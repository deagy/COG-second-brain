# P2 — CP-5 acceptance · AC-8

**EVIDENCE AC-8 | CP-5 | PASS** — both known defects closed.

`#249` fixed at cadre `998ad425`: the project walk now stops below `$HOME`. Reproduced against the fixed binary — tier `global-fallback`, store resolved from `KNOWLEDGE_STORE_HOME`, where before it reported `project-local` and silently ignored the variable. A genuine project-local config below home still resolves, which is the case the bound could have broken. Two tests pin it, both falsified against the unfixed walk before counting.

The issue's record corrected and closed. Its core defect survived the Python-to-Go rewrite; its stated consequence did not, and the comment says which is which.

The kernel's second release home retired at cadre `0f4bd58c` — a husk rather than a competing publisher: the job had left with the kernel, and a trigger on a moved file, an unread output, an orphaned comment block and a stale test citation stayed.

**EVIDENCE — | CP-4 | PASS** — 6 claims. The check that mattered was the one AC-8 does not cover: `FindFileAtProjectRoot` has five callers and CP-3v examined two. The other three — `.agents/cadre.yaml` discovery, the orchestration routing overlay, roster-root resolution — are unaffected, confirmed against the full suite under `CGO_ENABLED=1`. The `release.yml` job graph is intact with no job depending on the removed `kernel` output, which a YAML parse alone would not have shown.

**EVIDENCE — | CP-6 | PASS** — cadre `0f4bd58c`, CI run 33635041600, green on the runner.

## What the gates caught

| Gate | Verdict | Found |
|---|---|---|
| CP-3v | PASS | Nothing. Six checks reproduced independently, first round |
| CP-4 | FAIL | **CP-3v had never been recorded.** It ran and passed; no row, no filed report |

That failure is worth keeping. `phase-gates.sh` separates "never asked" from "ran unrecorded" precisely because they need different fixes, and this is the second kind: the verification happened, the verdict was acted on, and the trail could not be queried for it. Had the phase closed there, a later reader would have found a criterion marked verified with no verifier's report behind it — which is the shape of defect the previous ultragoal spent four rounds on.

## The claim now living in a public issue

P2's closing comment on `#249` asserts the Go source-scope gate is unconditional rather than tier-dependent. CP-4 verified it by building the binary and running an unscoped search at both tiers, not by re-reading the comment it cites. That matters because the claim is no longer internal: it is the correction of record on a closed issue, and if it were wrong the next reader would inherit the error.
