# AC-10b — port the containment, then retire the runner

> gloop gains filesystem and command containment for its tool executor — path confinement, a command allowlist, and the untrusted-brief fence — and cadre's `internal/orchestration/api_runner_*.go` is absent from its tree, with `runner="api"` either routed through gloop or retired by name.

Scoped before building, per the pattern that has caught something in every phase. It caught something here too: **half of this criterion cannot be satisfied as written.**

## The blocker

`cadre` is **public**. `gloop` is **private**. A public Go module cannot depend on a private one — `go get github.com/deagy/cadre/cli` would fail for every consumer outside this account the moment cadre imported gloop.

So "routed through gloop" is not a code decision. It requires either gloop becoming public, or cadre becoming private, and neither is mine to make. cadre does not currently depend on gloop at all; the dependency would be new and in the opposite direction to everything else in this consolidation, where gloop reads cadre's *output* rather than importing it.

Same shape as T-04's blocker one phase ago: the work was fine and the destination was not reachable. That one was `recall/govern` being unpushed, and the answer was to publish before cutting over.

## What is actually being ported

Read rather than assumed. `api_runner_sandbox.go` is 290 lines and contains **no cadre policy at all** — every value it enforces comes from its caller:

| Mechanism | What it does |
|---|---|
| `ResolveWithinProject` | Resolves a model-supplied path **then** proves containment, so a symlink pointing out of the tree is caught by the check rather than by trusting the literal path. Refuses `.git` at any depth — "a hook is code that runs later, outside this loop and outside every limit it applies" |
| `ReadFileCapped` / `WriteFileCapped` | 2 MB read, 1 MB write |
| `CheckCommandAllowed` | Caller's allowlist, plus `refusedCommands` — `cadre`, `codex`, `claude`, `cline`, `agentic-sdlc`, case-folded. Each "starts another agent, and a role that can start agents can escape every limit placed on it by starting something without them" |
| `AvailableToolNames` | The advertised tool set is computed from the same inputs that enforce it, so offering a tool the toolbox would refuse is impossible |
| Eight caps | iterations 24, tool result 64 KB, write 1 MB, read 2 MB, files scanned 20 000, matches 200, response 4 MB |
| `ToolDenied` | A refusal is returned to the model **as a tool result**, not as an error — "a refusal the model cannot see is a refusal it will repeat" |

Plus, from the loop: `FenceUntrustedBrief`, which puts the caller-supplied brief in the user message and the role's instructions in the system message. Added to fix a real bug where the trusted instructions were *also* inside the untrusted slot.

**None of this decides policy.** Which paths, which commands, whether writes are allowed — all supplied by the embedding system. That is precisely the property that let cadre's six retrieval refusals move into recall as `govern`, and it is why this belongs in gloop.

## What gloop has today

`types.ToolExecutor` is `map[string]ToolHandler`, where `ToolHandler = func(ctx, args string) (string, error)`. Whoever registers a handler owns the safety entirely. No path confinement, no allowlist, no caps. Its only mention of a sandbox is a comment that read-only means offering no tools at all — containment by omission.

## The split

**AC-10b-i — gloop gains the containment layer. Unblocked, and valuable whatever is decided about visibility.** A `sandbox` package plus a `Toolbox` implementing `types.ToolExecutor`, carrying every mechanism above with the reasoning attached. This is the `govern` half: port the requirement first, prove it refuses, *then* retire the implementation. Doing it in the other order is how a capability gets lost in a migration.

**AC-10b-ii — cadre's runner retires.** Blocked on the visibility decision. Two shapes:

1. **gloop goes public**, cadre imports `gloop/sandbox` and `runner="api"` routes through it. Preserves the capability where operators meet it. Costs: a public API surface for gloop, and a new cadre→gloop dependency.
2. **`runner="api"` retires by name**, as `ingest`, `delete` and 22 other verbs did in P4. Operators who need endpoint dispatch use gloop directly. Smallest, consistent with how this consolidation has handled every other losing claimant — and it removes a working capability from cadre rather than moving it.

## Recommendation

Start **10b-i** now; it is unblocked and it is the half that must come first regardless. Put the visibility question up before 10b-ii, because the answer changes what "retire" means: with a public gloop it is a redirect, and with a private one it is a deletion.
