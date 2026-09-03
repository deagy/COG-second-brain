---
type: plan
project: cog-cadre-integration
change: 03-gate-mutations
created: 2026-09-02
depends_on: ["01-run-record", "02-per-task-amend"]
status: withdrawn
tags: ["#plan", "#gates", "#authority", "#publishing"]
---

# Change 3 — Gate the high-consequence mutations

## The change

COG already requires explicit human approval before it publishes externally, but it
does so ad hoc: each skill says "ask the user first" in its own words with no shared
authority model and no audit trail. This change frames the external mutations as
release gates with a named authority and a single approval record that lands in the
run-record. It is deliberately narrow. COG's capture loop, braindumps, briefs, and
knowledge-base edits stay as they are — fast, no gate. The gate applies only where
the mutation leaves COG and touches an external system that other people see or
rely on. That is the whole set.

The authority model is cadre's G1-G10, read down to only the gates that match a
COG mutation's consequence. Not all ten apply; the mapping is the work of this
change, and it should keep the existing human names so the mapping is legible to
the person who approved the mutation.

## The mapping

| COG mutation | External system | Gate | Deciding authority |
|---|---|---|---|
| Publish a page to Confluence / Notion | Shared wiki | G8 release-readiness | Publisher |
| Post to Slack / socials / webhook | Public channel | G9 deployment-authorization | Publisher |
| Sync a team brief back to Linear | Issue tracker | G7 evidence | Publisher |
| content-factory publish | Public post | G8 + G9 | Publisher |
| update-knowledge-base sync to external wiki | Shared KB | G8 release-readiness | Publisher |

Everything that stays internal — writing to `05-knowledge/`, a local braindump, a
draft PRD, a consolidated framework that is not synced — takes no gate. The
distinction is the same one the phase-level loop already draws between work that
stays inside the project and work that reaches it.

## Where it lands

- A new `plan/authority-gates.md` registry (kept in the plan for now; the
  production form is a small schema in `05-knowledge/`) listing each mutation, its
  gate, its authority, and its approval-record shape. This is the one claim on the
  authority mapping, owned in one place.
- `.claude/skills/publish-to-confluence/SKILL.md` — the approval step records the authority
  and gate in the run-record before the page is created, and the post-condition
  re-fetches the page to confirm it matches.
- `.claude/skills/team-brief/SKILL.md` — the sync-back to Linear is gated as G7 with the
  Publisher's explicit approval recorded; the sync is the post-condition.
- `.claude/skills/content-factory/SKILL.md` — the publish step is gated G8+G9 with a
  screenshot as the post-condition, matching the existing voice-checklist.

## Acceptance criteria

- `AC-1` Each external mutation names exactly one gate and one authority; no
  mutation maps to two authorities for the same approval (the one-shape rule).
- `AC-2` A mutation without a recorded approval is not executed; the skill stops at
  the gate and asks.
- `AC-3` The approval — authority, gate, timestamp, who approved — is recorded before
  the mutation runs, via `checkpoint.sh record_approval` into
  `.claude/logs/approval-ledger.tsv`. A run-record cannot hold it: it is written at
  Phase 7, after the Phase 6 mutation, and the gated skills are not harness entry
  points, so in an ordinary session no run-record exists at all. Inside a harness run
  Phase 7 folds the ledger rows into the matching gate's `human_approvals`.
- `AC-4` After the mutation, the external artifact is re-fetched or re-read and
  confirmed to match intent (the post-condition), not just the tool return.
- `AC-5` Internal writes (knowledge-base edits, drafts, braindumps) take no gate;
  verified by running a knowledge-consolidation that never hits a gate.

## Files touched

New: `plan/authority-gates.md`. Edited (in the withdrawn implementation):
`.claude/skills/publish-to-confluence/SKILL.md`, `.claude/skills/team-brief/SKILL.md`,
`.claude/skills/content-factory/SKILL.md`, `.claude/skills/update-knowledge-base/SKILL.md`,
and `.claude/agents/worker-publisher.md` — the last of which is where the only actual
enforcement lived. None of those edits survives; all five files are at their `main` state.

## Risk

Medium. The blast radius is three skills, and the failure mode is over-gating: if
the boundary between "external, gated" and "internal, ungated" is drawn too wide,
COG's capture loop slows to a crawl and the feature stops being useful. The
boundary is the one judgment to get right, and it should be drawn from what each
skill actually writes and where it writes it, not from a general principle. The
second risk is that the authority names (Release Owner, Release Authority) come
from cadre's software-release context and feel wrong for a personal knowledge tool;
the mapping should keep the gate numbers for traceability but can rename the
authority to something a COG user recognizes if that reads better. That is a
cosmetic decision, not a structural one.

## Unblock

Decide the external/internal boundary by listing each skill's writes and tagging
them, and confirm the authority names. The run-record (change 1) must carry the
`approval` binding, and the amend semantics (change 2) must exist so a denied mutation has a defined re-entry rather than a dead end.

## Outcome — withdrawn

This change was built, reviewed four times, and withdrawn. No code from it is on `main`;
what survives is `plan/authority-gates.md` as a gate-id mapping document and the reasoning
in its § Enforcement.

The earlier version of this section claimed `implemented (committed: 883b7fd)` and marked
AC-1 through AC-5 met. That was wrong three ways, and the errors are instructive in a plan
repo whose product is provenance: `883b7fd` is an ancestor of `main` but its content is not
on `main` (it was reverted with the rest of the change); it touched three files under the
generated `skills/` mirror rather than the four `.claude/skills` files plus
`worker-publisher.md` the section described; and the acceptance criteria it declared met
included AC-3, the one the change could never satisfy.

**Why it was withdrawn.** The gate did not gate anything. `content-factory` is "designed to
run unattended on a schedule (nightly)" and the gate text instructed the agent to record its
own approval and then publish; the check meant to catch that matched on gate number alone,
so any prior approval row cleared an unrelated artifact; and the artifact identity it should
have matched on does not exist until after the mutation. Underneath all three: in a solo
vault the agent supplies every field of its own approval, so no ledger design attests a
human decision. See `plan/authority-gates.md` § Enforcement for what does.

**AC status.** AC-1 (one authority per mutation) and AC-5 (internal writes ungated) were
met and are recorded in the registry. AC-2 (an unapproved mutation does not run) and AC-3
(the approval recorded before the mutation) were not met and are not satisfiable by a
record the agent writes; they need a permission prompt, not a document. AC-4 (post-condition
observation) was already met before this change by `CLAUDE.md` § Skill Post-Condition Rule
and did not need it.
