# First-hour teammate experience — deagy/cadre, cadre-kernel, recall, gloop

Environment: `docker run --platform linux/arm64 node:22-bookworm-slim` on an aarch64 host, container named `cadre-test`, no local `~/sdk` checkouts mounted or referenced. `claude` CLI installed via `npm install -g @anthropic-ai/claude-code`. All commands run 2026-09-02.

## What worked

- **cadre — Claude Code plugin path, once prerequisites are present.** `docs/INSTALL.md`'s "any runner" row (`curl -fsSL https://raw.githubusercontent.com/deagy/cadre/main/install.sh | sh`) succeeded, exit 0, after `git`, `python3`, `curl`, `ca-certificates` were apt-installed (none present in the base image — see Undocumented prerequisites). It auto-detected no SSH key and fell back to HTTPS cloning on its own ("SSH not configured, cloning via HTTPS"), added the `cadre-team` marketplace, and installed `cadre@cadre-team` at user scope.
- **cadre — the doc's own "first task."** The install script's closing output literally suggests `cadre select --task "..." --files a.go --task-id T-1`. Ran the docs' "Verifying" command instead (`cadre select --task "smoke test" --files README.md --task-id SMOKE-1`) after adding `/root/.local/bin` to `PATH` (not done automatically — see below): exit 0, returned a full JSON routing plan (`agent-suite-governance` + `documentation` routes, `application-engineer`/`debugging-engineer`/`technical-writer` primary agents, `dispatch_disposition.status: "staffed"`). This is genuinely useful output with zero authentication.
- **cadre — plugin introspection without login.** `claude plugin details cadre@cadre-team` worked with no `/login`: full inventory (9 skills, 159 agents, 1 hook, projected token cost ~4,843 always-on tokens).
- **recall — prebuilt binary.** Downloaded `recall-0.3.3-linux-arm64` directly from the GitHub Releases page (`gh release view v0.3.3 -R deagy/recall` lists linux-arm64/amd64, darwin, windows assets) — not mentioned anywhere in the README. `chmod +x`, ran immediately: `recall version` → `recall version v0.3.3`; `recall store info` → `mode: local / backend: memory / status: healthy`. Fully usable with no build step.
- **recall — documented `go build` path, once Go is installed.** `git clone --depth 1 https://github.com/deagy/recall.git` succeeded (public repo, no auth). After installing Go 1.23.4, `go build -o recall ./cmd/recall` inside the checkout auto-downloaded a newer required toolchain (`go: downloading go1.26.5`, per `go.mod`'s toolchain directive) over the network and completed, exit 0, producing a working 17MB binary. So the documented command is correct — it just omits the toolchain-version and network-access prerequisites.
- **cadre-kernel — release + checksum path.** Downloaded `agentic-sdlc-v0.14.4-linux-arm64.tar.gz` and `SHA256SUMS` from `github.com/deagy/cadre-kernel/releases`, per `docs/INSTALL.md`'s "A warning about PyPI" section ("a release archive from deagy/cadre-kernel/releases for the kernel, verified against that release's SHA256SUMS"). `sha256sum` matched the published sum exactly (`db6f0b76898a385b2c7a8ce380bea2c75c00e6449be34803bbe28f58a8d9c794`). Extracted, `./agentic-sdlc --version` → `0.14.4`, exit 0.
- **gloop README is accurate about its own inaccessibility.** It states plainly: private repo, no releases, `go get`/`go install` won't work because `proxy.golang.org`/`pkg.go.dev` 404 on a private module, and the fallback "asks for a GitHub username and gives up when there is no terminal to ask." Our clone attempt reproduced exactly that predicted failure (see below).

## Where a newcomer stops

- **Base image has no `git`, `python3`, or `curl`.** The very first documented "any runner" command (`curl -fsSL ... | sh`) cannot even be typed on a stock `node:22-bookworm-slim` container:
  ```
  $ docker exec cadre-test which git python3 curl
  OCI runtime exec failed: exec failed: unable to start container process: exec: "git": executable file not found in $PATH
  OCI runtime exec failed: exec failed: unable to start container process: exec: "python3": executable file not found in $PATH
  ```
  `curl` itself was also absent, so the newcomer cannot even fetch `install.sh` without first knowing to `apt-get install curl` — a chicken-and-egg gap the docs don't flag. INSTALL.md says the script "needs `git` and Python 3.10+, checked up front rather than halfway through" but never says these aren't present on a bare image, nor that `curl` is needed to run the installer at all.
- **`cadre` is not on `PATH` after install, silently.** The install script prints the note itself:
  ```
  Note: /root/.local/bin is not on your PATH. Add it:
    bash/zsh   echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.profile
  ```
  A newcomer who doesn't read this line and just tries `cadre select ...` next gets `command not found` — the very first "verifying" step in the docs fails until this is done manually.
- **Actually dispatching an agent role needs `claude` login, and there is no headless path.** `claude plugin install`/`details` work with no auth, but running the suite for real — the entire point of "159 specialist roles" — requires an authenticated `claude` session. `echo "" | claude -p "say hi"` (no key) returned instantly:
  ```
  Not logged in · Please run /login
  ```
  `/login` is an interactive OAuth device-code flow; nothing in `docs/INSTALL.md` mentions it or how to authenticate a headless/CI/container teammate. This is the first-hour stop for anyone without a Claude account already logged in on that machine.
- **A bad/placeholder API key hangs instead of failing.** `ANTHROPIC_API_KEY=sk-test-fake claude -p "say hi"` did not error — it hung with zero stdout/stderr for well over 90 seconds (`docker top` showed the `claude -p say hi` process still accumulating CPU time at 00:00:03 after ~90s), then eventually exited 0 with no output at all. A newcomer who exports a typo'd or expired key gets silence, not a diagnosable error.
- **recall has no `## Installation` section at all.** Headings present: Features, Quick Start, Command-Line Interface (CLI), Semantic Chunking, Distributed Storage, Graph Embeddings, Intelligent Caching, Architecture, Design Decisions, Security Guidance, Current Status, Roadmap, Testing, License (appears twice), Advanced Usage, Running Benchmarks (appears twice), Multi-hop Reasoning. The only build instruction is buried in the CLI section: `go build -o recall ./cmd/recall`, which presupposes a local clone (never stated) and a Go toolchain (never stated, and no version given). The README never mentions the GitHub Releases page or the prebuilt binaries that exist there.
- **cadre-kernel's repo front page is blank.** `gh repo view deagy/cadre-kernel` returns only the one-line description; the repository has no `README.md` at all (`gh api repos/deagy/cadre-kernel/contents` lists `.github, .gitignore, LICENSE, Makefile, SECURITY.md, bin, cmd, go.mod, go.sum, internal, kernel` — no README). A newcomer arriving at this repo directly (rather than being routed here from cadre's INSTALL.md) has nothing to read.
- **cadre's own front-page README doesn't point a newcomer at INSTALL.md as an installation step.** The "Choose your path" table (the first thing on the README) routes to `IDENTITY.md`, `docs/adopt-cadre-quickstart.md`, `docs/getting-started.md`, `docs/orchestration.md`, `docs/lifecycle-and-plugin-operations.md`, `docs/role-index.md` — none of them `docs/INSTALL.md`. The only two links to INSTALL.md are buried in the "Supported runners" table further down, scoped to "Codex CLI" and "Claude Code" rows, not labeled as "how do I install this."
- **gloop cannot be cloned at all without credentials — exactly as its own README predicts.**
  ```
  $ git clone https://github.com/deagy/gloop.git
  Cloning into 'gloop'...
  fatal: could not read Username for 'https://github.com': No such device or address

  $ GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no" git clone git@github.com:deagy/gloop.git
  Cloning into 'gloop'...
  Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
  git@github.com: Permission denied (publickey).
  fatal: Could not read from remote repository.
  ```
  `which gh` in the container returned nothing (exit 1) — no GitHub CLI available either as an alternate auth path. Checked collaborator access from the host session (authenticated as the owner): `gh api repos/deagy/gloop/collaborators -q '.[].login'` returns only `deagy`; `gh api repos/deagy/gloop/teams` returns an empty list. No teammate currently has any grant on this repository — the access gap isn't just undemonstrated in the clean container, it doesn't exist yet at the repo-settings level either.

## Undocumented prerequisites

| Prerequisite | Repo | Stated in docs? | Evidence |
|---|---|---|---|
| `git` | cadre (install.sh), recall, gloop | Partially — cadre's INSTALL.md says the script "needs git and Python 3.10+" but doesn't say a bare image lacks it | `exec: "git": executable file not found in $PATH` before `apt-get install` |
| `python3` (3.10+) | cadre | Same as above | `exec: "python3": executable file not found in $PATH` |
| `curl` | cadre (to fetch install.sh in the first place) | Not stated | `exec: "curl": ...` — needed before the documented command can even run |
| Adding `~/.local/bin` to `PATH` | cadre | Stated only as a printed note *after* install completes, not as a pre-read prerequisite | install.sh's own "Note: ... is not on your PATH" output |
| An authenticated `claude` account (`/login`, OAuth device flow) | cadre | Not stated anywhere in `docs/INSTALL.md` | `claude -p "say hi"` → `Not logged in · Please run /login` |
| Go toolchain, and specifically a version new enough to satisfy `go.mod`'s toolchain directive (auto-fetches 1.26.5 even when 1.23.4 is installed) | recall, cadre-kernel would-be-source-build, gloop | recall: not stated at all (no version, no mention Go is required); gloop: stated explicitly ("Go 1.26.5 or higher") | `go: command not found` pre-install; `go: downloading go1.26.5` during build |
| Network egress to `proxy.golang.org` / `go.dev` / module sources | recall | Not stated | required for `go build`'s toolchain and dependency downloads (all succeeded in this container, which had outbound internet) |
| Network egress to `github.com` (raw content, releases, marketplace clone) | cadre, recall, cadre-kernel | Implicit, not called out as a requirement | all install/download steps depend on it |
| GitHub read access / credentials (SSH key or HTTPS PAT) to `deagy/gloop` specifically | gloop | Stated explicitly under "Requirements" ("Read access to this repository") | but no teammate currently holds this grant — confirmed via `collaborators`/`teams` API above |
| `make` | gloop (`make install` / `make build`) | Implicit in the one documented command, not listed under "Requirements" (which lists only Go, Git, repo access) | not tested (blocked earlier by clone failure) |
| A GitHub account with any relationship to the `deagy` account at all, for gloop | gloop | Not stated as a step ("ask deagy to add you as a collaborator") — the README explains *why* public install paths don't work but not *how* to get private access | inferred from empty collaborators/teams list |

## Raw transcripts

### Container setup
```
$ uname -m
aarch64
$ docker run -d --name cadre-test --platform linux/arm64 node:22-bookworm-slim sleep infinity
09c414c578e1cc5a3e1452afde6c72ea6bbb2e7d508602ef1ad5cefdbafa5c6d
$ docker exec cadre-test cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
$ docker exec cadre-test node --version
v22.23.2
$ docker exec cadre-test npm --version
10.9.8
$ docker exec cadre-test npm install -g @anthropic-ai/claude-code
added 2 packages in 6s
EXIT:0
```

### Missing base-image tools
```
$ docker exec cadre-test which git python3 curl
OCI runtime exec failed: exec failed: unable to start container process: exec: "git": executable file not found in $PATH
EXIT:127
$ docker exec cadre-test python3 --version
OCI runtime exec failed: exec failed: unable to start container process: exec: "python3": executable file not found in $PATH
EXIT:127
$ docker exec cadre-test curl --version
OCI runtime exec failed: exec failed: unable to start container process: exec: "curl": executable file not found in $PATH
EXIT:0
```
(installed via `apt-get update -qq && apt-get install -y -qq git python3 curl ca-certificates`, exit 0)

### cadre install.sh
```
$ curl -fsSL https://raw.githubusercontent.com/deagy/cadre/main/install.sh | sh
Runners: claude

checkout:
  cloning into /root/.cadre/dist
  linked /root/.local/bin/cadre

  Note: /root/.local/bin is not on your PATH. Add it:
    bash/zsh   echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.profile
    fish       fish_add_path /root/.local/bin

claude:
Adding marketplace…SSH not configured, cloning via HTTPS: https://github.com/deagy/cadre.git
Refreshing marketplace cache (timeout: 120s)…
Cloning repository (timeout: 120s): https://github.com/deagy/cadre.git
Clone complete, validating marketplace…
Cleaning up old marketplace cache…
✔ Successfully added marketplace: cadre-team (declared in user settings)
Installing plugin "cadre@cadre-team"...✔ Successfully installed plugin: cadre@cadre-team (scope: user)

Done.

  cadre select --task "..." --files a.go --task-id T-1

Lifecycle governance (G1-G10 gates) is optional and not installed.
Re-run with --with-lifecycle if you want it.
EXIT:0
```

### cadre select (docs' "Verifying" command)
```
$ export PATH="/root/.local/bin:$PATH"; cadre select --task "smoke test" --files README.md --task-id SMOKE-1
{
  "schema_version": 8,
  "task_id": "SMOKE-1",
  ...
  "dispatch_disposition": { "reason": "A primary and/or reviewer role was selected and can be dispatched as an accountable executor or independent reviewer.", "status": "staffed" },
  "lifecycle_tracking": { "reason": "Agentic SDLC executable not found; team dispatch is unaffected.", "status": "standalone" },
  ...
}
EXIT:0
```

### claude auth state
```
$ claude --version
2.1.259 (Claude Code)
EXIT:0
$ echo "" | claude -p "say hi"
Not logged in · Please run /login
EXIT:0
$ ANTHROPIC_API_KEY=sk-test-fake claude -p "say hi"
[no output for >90s; docker top showed the process still running with accumulating CPU time; eventually exited 0 with empty output]
```

### recall
```
$ gh release list -R deagy/recall
v0.3.3  Latest  v0.3.3  2026-09-02T15:58:28Z
v0.2.0          v0.2.0  2026-08-21T22:13:32Z
v0.1.0          v0.1.0  2026-08-19T23:10:55Z
$ gh release view v0.3.3 -R deagy/recall
asset:  recall-0.3.3-linux-arm64
...
$ curl -fsSL -o recall-bin https://github.com/deagy/recall/releases/download/v0.3.3/recall-0.3.3-linux-arm64
EXIT:0
$ chmod +x recall-bin && ./recall-bin --version || true
$ ./recall-bin store info
mode:        local
backend:     memory
status:      healthy (ok=true, connected=true)
chunks:      0
EXIT:0

$ which go
bash: line 1: go: command not found
EXIT:127
$ git clone --depth 1 https://github.com/deagy/recall.git
Cloning into 'recall'...
EXIT:0
$ cd recall && go build -o recall ./cmd/recall
bash: line 1: go: command not found
EXIT:127
# after installing go1.23.4:
$ go build -o recall ./cmd/recall
go: downloading go1.26.5 (linux/arm64)
go: downloading gopkg.in/yaml.v3 v3.0.1
... (dependency downloads) ...
EXIT:0
$ ls -la recall
-rwxr-xr-x 1 root root 17320324 ... recall
```

### cadre-kernel
```
$ gh repo view deagy/cadre-kernel
name: deagy/cadre-kernel
description: Portable Agentic SDLC lifecycle kernel: ...
(no README rendered — repo has none)
$ gh api repos/deagy/cadre-kernel/contents -q '.[].name'
.github .gitignore LICENSE Makefile SECURITY.md bin cmd go.mod go.sum internal kernel
$ curl -fsSL -o agentic-sdlc.tgz https://github.com/deagy/cadre-kernel/releases/download/v0.14.4/agentic-sdlc-v0.14.4-linux-arm64.tar.gz
EXIT:0
$ curl -fsSL -o SHA256SUMS https://github.com/deagy/cadre-kernel/releases/download/v0.14.4/SHA256SUMS
EXIT:0
$ sha256sum agentic-sdlc.tgz; grep linux-arm64 SHA256SUMS
db6f0b76898a385b2c7a8ce380bea2c75c00e6449be34803bbe28f58a8d9c794  agentic-sdlc.tgz
db6f0b76898a385b2c7a8ce380bea2c75c00e6449be34803bbe28f58a8d9c794  agentic-sdlc-v0.14.4-linux-arm64.tar.gz
$ tar xzf agentic-sdlc.tgz && ./agentic-sdlc --version
0.14.4
EXIT:0
```

### gloop
```
$ gh repo view deagy/gloop --json visibility,description,url
{"description":"","url":"https://github.com/deagy/gloop","visibility":"PRIVATE"}
$ git clone https://github.com/deagy/gloop.git
Cloning into 'gloop'...
fatal: could not read Username for 'https://github.com': No such device or address
EXIT:128
$ GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no" git clone git@github.com:deagy/gloop.git
Cloning into 'gloop'...
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
EXIT:128
$ which gh
EXIT:1
```
Host-side access check (run with the owner's authenticated `gh`, not from inside the clean container):
```
$ gh api repos/deagy/gloop/collaborators -q '.[].login'
deagy
$ gh api repos/deagy/gloop/teams -q '.[].slug'
(empty)
```
gloop's own README, "Installation" section (quoted verbatim, fetched via `gh api repos/deagy/gloop/contents/README.md`):
> Clone and build. There is no `go get github.com/deagy/gloop` and no `go install github.com/deagy/gloop/cmd/gloop@latest`, because both resolve through the public module proxy and this repository is private: `proxy.golang.org` and `pkg.go.dev` both answer 404 for it, and the direct fallback asks for a GitHub username and gives up when there is no terminal to ask.
>
> ### Requirements
> - Go 1.26.5 or higher
> - Git
> - Read access to this repository
