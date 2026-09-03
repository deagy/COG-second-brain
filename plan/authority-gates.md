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
project and work that reaches it.

**The set below is not complete, and its coverage is inverted.** `create-user-story` opens
GitHub Issues, `generate-release-notes` publishes, and `.claude/agents/worker-executor.md`
is *defined* as "pre-approved mutations — Jira transitions, Linear updates, API calls" and
carries no gate at all. Meanwhile `00-inbox/MY-INTEGRATIONS.md` lists Slack, Linear,
Confluence and Notion as **Disabled** and only **GitHub** and **Discord** as Active — so
three of the five rows below gate services that do not run in this vault, and both surfaces
that do run are absent. `CLAUDE.md` § Integration Preferences says to check that file before
using any external integration; this registry was written across four review passes without
anyone doing so. Treat the table as a gate-id mapping, not as a coverage claim.

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

## Why there is no approval record

Two constraints killed every version of one, and they are worth stating because they are
properties of the setting rather than of any particular design.

**An approval is a moment-fact; a run-record is a document written at the end of a run.**
None of the gated skills is a harness entry point, so in an ordinary
`/publish-to-confluence` session no run-record exists at any path — and even inside
`/closed-loop` the mutation is Phase 6 while the run-record is written at Phase 7, so the
file does not exist at the moment the approval must precede the mutation. An append-only
ledger solves that shape problem, and one was built.

**But the ledger could not attest a human decision**, which was the point. See § Enforcement
below. A third constraint compounded it: the durable identity an approval should bind to
does not exist yet either. A new page's URL is assigned by the server on POST, so recording
an approval "before the page is created" against `<page-url>` is unsatisfiable; binding to a
hash of the content about to be posted would work, and `$defs/evidence` in the vendored
schema requires exactly that shape — `{evidence_id, uri, hash_algorithm, hash,
classification}`, a content hash rather than a URL — but a hash only helps if something
independent checks it, and in a solo vault the checker is the same agent.

## Enforcement — what actually stops an unapproved publish

Nothing in this document enforces anything, and an earlier draft of this section claimed
otherwise. The approval-ledger mechanism it described (`checkpoint.sh record_approval`,
a per-gate `human_approvals` fold, a ledger check in `worker-publisher`) was built, reviewed
four times, and withdrawn. The reason is worth keeping, because it is not a bug that could
have been patched:

**In a solo vault the agent supplies every field of its own approval.** `record_approval`
was a bash command the agent ran, with arguments the agent chose, in a vault where the
Publisher and the approver are the same person. The row recorded the agent's intent in the
grammar of the user's decision. No validation fixes that, because the agent fills the
validation's inputs too.

Worse, it was strictly weaker than what already existed. `publish-to-confluence` Phase 4
already says *wait for explicit "yes"*; `update-knowledge-base` Phase 6 already says *NEVER
auto-publish*. In those two the ledger row was written after a real human turn and added
nothing. In `team-brief` and `content-factory` — the latter explicitly "designed to run
unattended on a schedule (nightly)" — there was no prompt, so the row manufactured the
appearance of a control where none existed, and an unattended job signing its own approval
slip is the worst of the three outcomes: it publishes anyway *and* leaves an audit trail
asserting a human said yes.

What actually stops an unapproved publish today, in order of strength:

1. **A permission prompt the agent cannot issue to itself.** Deny-by-default `permissions`
   entries in `.claude/settings.json` covering the real mutation surface — the wiki host for
   `WebFetch`, `Bash(gh issue create:*)` and `Bash(gh api:*)` with a write method, the
   Discord webhook `curl`, and the Notion/Linear MCP write tools. This is the only control
   here that a human must clear, and it lands in the transcript. Not yet configured; the
   `update-config` skill exists for it.
2. **The per-skill explicit-approval step**, where the skill has one — a real turn where the
   user says yes. `publish-to-confluence` and `update-knowledge-base` have it; `team-brief`
   and `content-factory` do not.
3. **`CLAUDE.md` § Skill Post-Condition Rule** — observe the mutated artifact and confirm it
   matches intent before reporting success. This catches a wrong publish after the fact
   rather than preventing it, but it is mandatory and it is honest about what it does.

For an unattended pipeline the answer is not a per-run approval at all: it is a **standing
envelope the user wrote in advance** and the run may not exceed. `content-factory` already
has one — the volume budget ("Long video / deep essay — 0 — never autonomous"), the surfaces
in `MY-INTEGRATIONS.md`, the dedup ledger, the environment gate. Making that envelope
explicit and refusable, with anything outside it parked for morning review, is the real work
this change should have done.

## The gate-id mapping

The table above remains useful for one thing: if a COG run-record is ever compared against a
cadre one, these are the `gate_id` values COG's external mutations correspond to. That is a
mapping, not a control, and it is all this document now claims.
