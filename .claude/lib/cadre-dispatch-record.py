#!/usr/bin/env python3
"""cadre-dispatch-record.py — emit a schema-valid run-record for a roster dispatch.

Change 4 AC-3: a dispatched specialist's work is audited the same way COG's own
work is, via the run-record (Change 1). This generator fills the vendored
run-record.schema.json (v2) with the fields a specialist dispatch needs and writes
run-record.json, so `run-record-lint.sh <run-dir>` validates it.

Inputs (positional):
  role_id sandbox_mode model codex_model reasoning_effort phase task_id baseline

The dispatch binding (role + sandbox + model + effort) is hashed into
dispatch_fingerprint / dispatch_binding_digest. The record names the dispatched
role and its sandbox in execution_summary.dispatched_agents and in the build/verify
gates, which is what AC-3 requires.
"""
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

SCHEMA = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "05-knowledge", "run-record.schema.json",
)

# Catalog phase (roster catalog.yaml) -> run-record lifecycle phase (the schema
# enum is the agentic-sdlc lifecycle, not the catalog's phase vocabulary).
PHASE_MAP = {
    "planning": "intent",
    "design": "architecture",
    "document": "evidence",
    "governance-data": "governance-data",
    "security": "security-crypto",
    "build": "build",
    "verify": "verify",
    "review": "verify",
    "evidence": "evidence",
    "release": "release-readiness",
    "authority": "deployment-authorization",
    "operations": "runtime-conformance",
    "support": "runtime-conformance",
    "knowledge": "feedback",
}

# Lifecycle phase -> the G1-G10 gate that owns it (verify is always also owned).
PHASE_TO_GATE = {
    "intent": "G1", "requirements": "G2", "architecture": "G3",
    "governance-data": "G4", "security-crypto": "G5", "build": "G6",
    "verify": "G7", "evidence": "G8", "release-readiness": "G9",
    "deployment-authorization": "G10", "runtime-conformance": "G10",
    "feedback": "G8",
}


def sha256_hex(text: str) -> str:
    return "sha256:" + hashlib.sha256(text.encode()).hexdigest()


def identity(role_id: str, kind: str = "agent") -> dict:
    return {"id": role_id, "role": role_id, "kind": kind}


def gate(tier, gate_id, name, applicability, status, preparer, verifier,
         artifact_id, binding, reentry=None, artifact=None,
         artifact_revision="0.1.0"):
    # This record is written at dispatch time, before the specialist has produced
    # anything: every applicable gate is still "pending". A binding here could only
    # digest its own synthesized artifact_id, which would match by construction and
    # attest integrity over a file that does not exist. Bind only a real artifact.
    bindings = []
    if artifact is not None:
        with open(artifact, "rb") as fh:
            bindings = [{
                "artifact_id": artifact_id or os.path.basename(artifact),
                "revision": artifact_revision,
                "digest": hashlib.sha256(fh.read()).hexdigest(),
            }]
    return {
        "tier": tier,
        "gate_id": gate_id,
        "name": name,
        "applicability": applicability,
        "applicability_rationale": (
            None if applicability == "not-applicable"
            else f"{gate_id} gates the {name} step of this dispatch"
        ),
        "status": status,
        "artifact_bindings": bindings,
        "preparers": [identity(preparer)],
        "independent_verifier": identity(verifier) if verifier else None,
        "independence_declaration": {
            "verifier_confirmed_not_preparer": verifier is not None,
            "verifier_made_material_correction": False,
        },
        "authority_requirements": [],
        "human_approvals": [],
        "decided_at": None,
        "evidence_refs": [],
        "knowledge_status": "complete",
        "findings": [],
        "exceptions": [],
        "invalidation_history": [],
        "required_reentry_gate": reentry,
    }


def main():
    argv = sys.argv[1:]
    verifier_id = None
    artifact_path = None
    rest = []
    i = 0
    while i < len(argv):
        if argv[i] == "--verifier" and i + 1 < len(argv):
            verifier_id = argv[i + 1]
            i += 2
        elif argv[i] == "--artifact" and i + 1 < len(argv):
            artifact_path = argv[i + 1]
            i += 2
        else:
            rest.append(argv[i])
            i += 1
    sys.argv = [sys.argv[0]] + rest

    if artifact_path is not None and not os.path.isfile(artifact_path):
        sys.stderr.write(f"FAIL: --artifact {artifact_path} does not exist\n")
        return 2

    if len(sys.argv) < 9:
        sys.stderr.write(
            "usage: cadre-dispatch-record.py <role_id> <sandbox_mode> <model> "
            "<codex_model> <reasoning_effort> <phase> <task_id> <baseline> "
            "[output-path] [--verifier <role-id>] [--artifact <path>]\n"
            "  output-path defaults to ./run-record.json; pass "
            "<run-dir>/run-record.json so the record lands with the work.\n"
            "  --verifier  the role that peer-reviewed the output (AC-4). "
            "Omitted, the record states no independent verifier.\n"
            "  --artifact  a real file to bind and digest. Omitted, gates carry "
            "no artifact_bindings -- correct at dispatch time, when nothing "
            "has been produced yet.\n"
        )
        return 2

    role_id, sandbox, model, codex_model, effort, phase, task_id, baseline = sys.argv[1:9]
    if phase not in PHASE_MAP:
        sys.stderr.write(
            f"FAIL: unknown phase '{phase}' (valid: {', '.join(sorted(PHASE_MAP))})\n"
        )
        return 2
    lifecycle_phase = PHASE_MAP[phase]

    # AC-3: the record must not attest a role or sandbox the vendored roster does
    # not actually hold. Resolve the role and its sandbox from the roster; reject a
    # role that is not in the roster, or a sandbox that does not match its capability
    # tier, rather than recording an unverifiable claim.
    _resolve = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "cadre-roster-resolve.sh"
    )
    _role_check = subprocess.run(
        ["bash", _resolve, role_id], capture_output=True, text=True
    )
    if _role_check.returncode == 1:
        sys.stderr.write(f"FAIL: role '{role_id}' is not in the vendored roster\n")
        return 2
    if _role_check.returncode != 0:
        sys.stderr.write(
            "FAIL: could not resolve the roster "
            f"(cadre-roster-resolve.sh exited {_role_check.returncode}): "
            f"{_role_check.stderr.strip()}\n"
        )
        return 2
    _sandbox_run = subprocess.run(
        ["bash", _resolve, "--key", "sandbox_mode", role_id],
        capture_output=True,
        text=True,
    )
    if _sandbox_run.returncode != 0:
        sys.stderr.write(
            "FAIL: could not read sandbox_mode for "
            f"'{role_id}': {_sandbox_run.stderr.strip()}\n"
        )
        return 2
    _expected_sandbox = _sandbox_run.stdout.strip()
    if _expected_sandbox != sandbox:
        sys.stderr.write(
            f"FAIL: sandbox '{sandbox}' does not match roster role '{role_id}' "
            f"(expected '{_expected_sandbox}')\n"
        )
        return 2

    binding = json.dumps({
        "role_id": role_id,
        "sandbox_mode": sandbox,
        "model": model,
        "codex_model": codex_model,
        "reasoning_effort": effort,
    }, sort_keys=True)
    dispatch_binding_digest = sha256_hex(binding)
    contract_digest = sha256_hex(open(SCHEMA).read())
    dispatch_fingerprint = sha256_hex(binding + contract_digest)

    # G1-G10 lifecycle gates. A specialist dispatch reuses the lifecycle it was
    # spawned into: build/verify are applicable, the rest are not (the dispatch
    # does not re-run intent/requirements/architecture/etc.).
    # The dispatch's lifecycle phase owns its gate; verify (G7) always owns the
    # output regardless of phase.
    applicable_gates = {PHASE_TO_GATE[lifecycle_phase], "G7"}
    phase_names = {
        "G1": "intent", "G2": "requirements", "G3": "architecture",
        "G4": "governance-data", "G5": "security-crypto", "G6": "build",
        "G7": "verify", "G8": "evidence", "G9": "release-readiness",
        "G10": "deployment-authorization",
    }
    phases = {gid: (name, "applicable" if gid in applicable_gates else "not-applicable")
              for gid, name in phase_names.items()}
    lifecycle_gates = []
    exec_gates = {}
    for gid, (name, applicability) in phases.items():
        status = "approved" if applicability == "not-applicable" else "pending"
        art = f"{role_id}-{gid}-artifact"
        g = gate("lifecycle", gid, name, applicability, status,
                 preparer=role_id, verifier=verifier_id,
                 artifact_id=art if applicability == "applicable" else None,
                 binding=binding,
                 artifact=artifact_path if applicability == "applicable" else None)
        lifecycle_gates.append(g)
        exec_gates[gid] = {
            "configured": True,
            "ignored": applicability == "not-applicable",
            "ignore_reason": None if applicability == "applicable"
                             else f"{name} not part of this specialist dispatch",
            "required_agents": [role_id],
            "dispatched_agents": [role_id] if applicability == "applicable" else [],
            "required_tasks": [f"{name}-task"],
            "completed_tasks": [],
            "required_agent_artifacts": [],
            "produced_agent_artifacts": [],
        }

    # The dispatched specialist's own attestations (specialist tier), naming the
    # role and sandbox — the audit trail AC-3 requires.
    specialist = gate("specialist", "S1", "specialist attestation",
                      "applicable", "pending", preparer=role_id,
                      verifier=verifier_id,
                      artifact_id=f"{role_id}-artifact",
                      binding=binding,
                      artifact=artifact_path)
    specialist["name"] = f"{role_id} ({sandbox}) attestation"

    record = {
        "version": 2,
        "task_id": task_id,
        "dispatch_fingerprint": dispatch_fingerprint,
        "kernel_version": "cadre-1.0.0",
        "contract_digest": contract_digest,
        "provider_bindings": [],
        "profile": None,
        "profile_digest": None,
        "dispatch_binding_digest": dispatch_binding_digest,
        "recorded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "classification": f"cadre-dispatch:{role_id}",
        "mode": "specialist-dispatch",
        "baseline_revision": baseline,
        "scope": f"{role_id} work under {sandbox} sandbox",
        "disposition": "in-progress",
        "intent_record_id": None,
        "requirements_baseline_id": None,
        "current_lifecycle_phase": lifecycle_phase,
        "knowledge_retrieval": {
            "status": "complete",
            "reason": None,
            "query_ids": [],
            "evidence_refs": [],
            "influence": "The role's AGENT.md defines the specialist's scope.",
        },
        "impact_profile": {
            "profile_id": f"{role_id}-impact",
            "status": "draft",
            "impact_categories": [],
            "specialized_boms": [],
            "blocking_unknowns": [],
        },
        "lifecycle_gates": lifecycle_gates,
        "specialist_attestations": [specialist],
        "re_entry_history": [],
        "execution_summary": {"gates": exec_gates},
    }

    out = sys.argv[9] if len(sys.argv) > 9 else "run-record.json"
    with open(out, "w") as fh:
        json.dump(record, fh, indent=2)
        fh.write("\n")
    print(f"WROTE {out} (role={role_id}, sandbox={sandbox})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
