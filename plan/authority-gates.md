---
type: plan
project: cog-cadre-integration
change: 03-gate-mutations
created: 2026-09-02
depends_on: ["01-run-record", "02-per-task-amend"]
status: draft
tags: ["#plan", "#gates", "#authority", "#publishing"]
---

# Change 3 — Gate the high-consequence mutations

## The boundary

The gate applies only where the mutation leaves COG and touches an external system that
other people see or rely on. Everything that stays inside COG — writing to `05-knowledge/`,
a local braindump, a draft PRD, a consolidated framework that is not synced — takes no
gate. This is the same split the phase-level loop draws between work that stays inside the
project and work that reaches it. The whole external set, today, is five mutations.

## The registry

This document is the one claim on the authority mapping; it is owned here and referenced,
never re-declared in a skill (AC-5). Gate numbers are cadre's, so a COG run-record and a
cadre one join on the same `gate_id`; the authority is renamed from cadre's software-release
role to the COG role that actually decides — the **Publisher**, the human who owns the brain
and approves the external write. Each mutation names exactly one authority (AC-1).

The numbers come from `cadre-kernel/kernel/contracts/lifecycle-gates.json` at the vendored
revision, which is also the ladder `05-knowledge/product/agentic-sdlc.md` already records:
G7 Evidence, G8 Release Readiness, G9 Deployment Authorization, G10 Runtime Conformance.
Do not renumber them here — a gate id that disagrees with the kernel makes the run-record
uncomparable, which is the whole reason the schema was vendored.

| COG mutation | External system | Gate | Deciding authority |
|---|---|---|---|
| Publish a page to Confluence / Notion | Shared wiki | G8 release-readiness | Publisher |
| Post to Slack / socials / webhook | Public channel | G9 deployment-authorization | Publisher |
| Sync a team brief back to Linear | Issue tracker | G7 evidence | Publisher |
| content-factory publish | Public post | G8 + G9 | Publisher |
| update-knowledge-base sync to external wiki | Shared KB | G8 release-readiness | Publisher |

content-factory spans G8 and G9 but has one approval — one authority signs off the whole
publish, not one per gate. That is the one-shape rule (AC-1): the approval record carries a
single authority even when two gates apply.

## Where the approval is recorded

An approval is a moment-fact; a run-record is a document written at the end of a harness
run. The first cannot be written into the second, and the earlier draft of this section
asked for exactly that. Two things made it unsatisfiable: none of the gated skills is a
harness entry point, so in an ordinary `/publish-to-confluence` session no run-record
exists at any path; and even inside `/closed-loop` the mutation is Phase 6 while the
run-record is written at Phase 7, so the file does not exist at the moment the approval
must precede the mutation.

So the approval goes where COG already puts moment-facts — an append-only ledger, the same
mechanism `checkpoint.sh record` uses for checkpoints:

```bash
bash .claude/lib/checkpoint.sh record_approval <gate> Publisher <approver> "<artifact>" [run-dir]
```

This appends to `.claude/logs/approval-ledger.tsv`, which exists in every session, so
"recorded before the mutation" (AC-3) is satisfiable everywhere. Inside a harness run, pass
the run directory as well and the row is also written to `<run-dir>/evidence/approvals.tsv`,
where `checkpoint.sh status` surfaces it.

When a run-record *is* being written, Phase 7 of `closed-loop` folds the run's approval rows
into the matching gate's `human_approvals` array — a property of the gate object, never of
the run-record root, which is `additionalProperties: false` and rejects a top-level
`human_approvals` outright. That fold is the only place the run-record and the approval meet,
and it happens after the fact, which is the correct direction: the ledger is the record, the
run-record is a report assembled from it.

A mutation spanning two gates (content-factory, G8 + G9) still has one approval — record it
against the gate the table names first and note the span, per the one-shape rule above.

A mutation without a recorded approval is not executed: the skill stops at the gate and
asks (AC-2). After the mutation, the external artifact is re-fetched or re-read and
confirmed to match intent, not just the tool return (AC-4) — this is the same post-condition
each skill already runs; the gate makes the approval a first-class, durable record rather
than a fact that lives only in the conversation.

## Enforcement

Each of the four skills records the approval in the run-record before the mutation and
references this registry:

- `.claude/skills/publish-to-confluence/SKILL.md` — G8, Publisher; the run-record approval is
  written before the page is created; the post-condition re-fetches the page.
- `.claude/agents/worker-publisher.md` — G9 for Slack / socials / webhooks and G8 for
  Confluence / Notion pages, Publisher; the agent that actually posts confirms the
  recorded approval before publishing and observes the artifact afterwards.
- `.claude/skills/team-brief/SKILL.md` — G7, Publisher; the Linear sync-back is gated with explicit
  approval recorded; the sync is the post-condition.
- `.claude/skills/content-factory/SKILL.md` — G8 + G9, Publisher; the publish is gated with the
  approval recorded; the screenshot/curl is the post-condition.
- `.claude/skills/update-knowledge-base/SKILL.md` — G8, Publisher; the sync to an external wiki is
  gated with the approval recorded; the post-condition re-fetches the wiki.
