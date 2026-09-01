# P5 / AC-10 — what "execution orchestration" turned out to be

The ownership table gives execution orchestration to gloop, and cadre has 73 files under `internal/orchestration`. Read at the seams rather than judged from doc comments, the overlap is **one runner out of three**, not a duplicated subsystem.

## cadre spawns agent CLIs; gloop drives LLM endpoints

**cadre's dispatch** resolves a role, computes an effective sandbox, gates write-capable operations behind a confirmation token with a 300-second TTL, writes an audit row, and then spawns a child:

- `SpawnClaudeCodeChild` — runs the Claude Code CLI with the prompt on stdin, mapping cadre's sandbox vocabulary onto `--permission-mode` (`read-only → plan`, `workspace-write → acceptEdits`, `danger-full-access → bypassPermissions`). Its own comment records that this flag was once absent entirely, so "every sandbox decision this package makes was computed, logged, and then discarded at the exec".
- `SpawnCodexChild` — the same for the Codex CLI.
- `SpawnAPIChild` — no child process at all: it drives a chat endpoint and executes the tool calls itself.

It is exposed as an **MCP server** (`dispatch_core_phase4_mcp_server.go`), so the client is an agent runtime that already exists.

**gloop's dispatch** takes a `DispatchPlan` and executes roles through a `SessionManager` over LLM provider APIs — `pkg/runtime/{anthropic,openai,google,cohere,mistral}` — with tool execution, token tracking, retries, rate limiting and circuit breakers.

`grep -rn "claude\|codex" pkg/dispatch/ pkg/runtime/` returns nothing outside the Anthropic provider. **gloop spawns no agent CLIs and has no claim on that.**

## The genuine overlap is `runner="api"`

Two implementations of one thing: ask an endpoint, execute the tool calls it asks for, ask again.

| | cadre | gloop |
|---|---|---|
| Where | `internal/orchestration/api_runner_{loop,endpoint,sandbox}.go` — **2,199 lines** | `pkg/runtime` + `pkg/dispatch` |
| Loop | `RunAPIDispatch`: "ask, execute what comes back, ask again" | `SessionManager` + `ToolExecutor` |
| Tools | a `Toolbox` with `listFiles`, `search`, `runCommand` against an allowlist | pluggable `ToolExecutor` |
| Extras | sandbox enforcement, an untrusted-brief fence | retries, timeouts, rate limits, circuit breakers, token accounting |

cadre's own comment states why `runner="api"` exists: *"it serves deployments where there is no coding CLI to spawn."* That is gloop's job description.

## What cadre's API runner has that gloop's runtime does not

Not a reason to keep two, but the list a replacement has to satisfy:

- **The sandbox is enforced, not advisory.** `api_runner_sandbox.go` bounds `runCommand` to an allowlist and file access to the project root.
- **The untrusted brief is fenced.** `FenceUntrustedBrief(ctx.Brief)` puts the caller-supplied brief in the user message and the role's instructions in the system message. The comment records the bug this fixed: the role's trusted instructions were previously *also* inside the untrusted slot, "which is the boundary the fence exists to draw".
- **Advertised tools and enforced tools come from one list**, so the two cannot drift.

## The table's row is too coarse to be true or false

"Execution orchestration → gloop" cannot describe this. Spawning a sandboxed Claude Code child under a confirmation gate and driving a chat endpoint's tool loop are different concerns that happen to share the word dispatch — the same mistake the table already corrected once for selection, where cadre's governed selection and gloop's execution planning were read as one concern until someone read both.

**Proposed rows:**

| Concern | Owner | Losing claimant |
|---|---|---|
| Sandboxed dispatch to agent CLIs, confirmation-gated and audited | `cadre` | none — gloop has no equivalent |
| Driving an LLM endpoint's tool-call loop | `gloop` | `cadre/internal/orchestration/api_runner_*.go`, 2,199 lines |

Closing AC-10 as written then means retiring cadre's `runner="api"` — with the sandbox, the fence and the single-source tool list carried into gloop, or the runner kept and the criterion amended to say why.
