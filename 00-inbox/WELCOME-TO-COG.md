---
type: guide
created: 2026-08-28
tags: ["#welcome", "#getting-started", "#cog"]
---

# Welcome to Your COG Second Brain, Daniel!

Your COG is personalized and ready. Here's how to get started.

## Your Profile Documents

- **[[MY-PROFILE]]** — Basic info, role pack, agent mode
- **[[MY-INTERESTS]]** — Topics driving your daily briefs
- **[[MY-INTEGRATIONS]]** — Active and disabled integrations
- **[[03-professional/COMPETITIVE-WATCHLIST]]** — Who you're tracking

**Edit these anytime.** COG reads them when you use skills, so changes take effect immediately.

## Skills for Your Role

Ordered by what will pay off first given how you work:

1. **braindump** — Say it however it comes out; COG classifies it by domain and files it against the right project. This is the one that handles scattered thinking, so reach for it before you've organized anything.
2. **daily-journal** — Ambient. COG appends entries after meaningful work on its own, so you get a log of what you did without having to remember at the end of the day. `/daily-journal reflect` walks a guided review when you want one.
3. **url-dump** — Drop a link, get the key takeaways extracted and filed into a knowledge booklet. Good for PQC papers, standards drafts, and agent-framework writeups.
4. **knowledge-consolidation** — Turns scattered braindumps into one reference doc. Run it when you notice you've said the same thing three times in different notes.
5. **daily-brief** — Curated news across your interest areas, with sources verified and a 7-day freshness requirement.
6. **weekly-checkin** — Cross-domain pattern analysis. Surfaces the recurring blocker you didn't notice was recurring.
7. **update-cog** — Pull framework updates without touching your content.

Also worth knowing, given your projects: **generate-release-notes** and **create-user-story** work against GitHub, and **auto-research** runs a deep multi-thread research pass when a question deserves more than a brief.

## Your Integrations

**Active**: GitHub, Discord
**Disabled**: Slack, Linear, Jira, Confluence, Notion, PostHog, ElevenLabs

Change these anytime in [[MY-INTEGRATIONS]]. COG silently skips anything in the disabled list — it won't nag you to set them up.

## Your Active Projects

- [[04-projects/secure-quantum-environment/PROJECT-OVERVIEW|Secure Quantum Environment]] — PQC + QKD across a varied network stack (work)
- [[04-projects/agentic-sdlc/PROJECT-OVERVIEW|Agentic SDLC]] — specialist-agent task dispatch (personal)

When you braindump, pick the project and your thoughts file themselves in the right place.

## Agent Team Mode

You're set to `team`, so COG delegates to specialist sub-agents — Sonnet workers for data collection, research, file operations, and publishing; the lead session handles reasoning, synthesis, and writing. You'll see this most in `auto-research`, `comprehensive-analysis`, and `daily-brief`, where parallel workers make a real difference. Switch to `solo` in [[MY-PROFILE]] if the delegation ever feels like overhead.

## The Verification Harness (off by default)

COG ships a V-model verification harness: spec and plan on the way down, build at the apex, verification with evidence traced to criterion IDs on the way up. It's **off** — ordinary notes, briefs, and drafts take no checkpoints.

Turn it on per-task with `/closed-loop`, or for a long multi-session goal with `/ultragoal`. Given the agentic-sdlc project, it's worth reading `WORKFLOW.md` as prior art even if you never switch it on: it's a worked example of the verify-before-land problem you're solving.

## Quick Start

Try a braindump right now — say what's on your mind about either project and watch where it lands. Or ask for your daily brief to see what's moving in PQC, QKD, and agent tooling today.

## Keeping COG Updated

Your content and framework files are separate. Run `/update-cog` to pull new skills and improvements; your braindumps, profiles, and notes are never touched. Current version: `cat COG-VERSION`.

## Tips

- **Don't pre-organize.** Dump it, let COG file it. The friction of deciding where something goes is what kills capture.
- **Let the journal accumulate.** You'll want it at review time, and you won't have had to write it.
- **Prune the watchlist.** It started as recommendations — delete what you don't actually care about so the briefs stay sharp.
- **Correct COG when it's wrong.** Factual corrections get written straight into the relevant knowledge note.

---

*Archive or delete this guide once you're comfortable.*
