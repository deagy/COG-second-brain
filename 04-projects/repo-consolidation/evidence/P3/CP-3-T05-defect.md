# P3 / T-05 — the deprecation as shipped is incoherent and incomplete

Found during T-06, after `9ce408b` was committed and pushed.

## What happened

T-05's inventory was run as `grep ... | head -10`. Eleven hits existed. The truncated output was treated as complete, and the deprecation was designed against it.

The complete inventory is 31 hits, of which three are production callers outside the deprecated functions themselves:

| Caller | Calls | Deprecated? |
|---|---|---|
| `cmd/gloop/cmd/select.go:91` | `selector.Select` | yes — intended |
| `pkg/roster/select.go:70` | `catalog.MatchRoutes` | **no** |
| `pkg/tenant/catalog.go:97` | `catalog.MatchRoutes` | **no** |

## Two separate defects

**1. `catalog.MatchRoutes` should not have been deprecated.** It is the shared low-level matching engine, and `pkg/roster` and `pkg/tenant` both call it for their own purposes. Marking it deprecated while two undeprecated packages depend on it tells every reader of those packages that they are built on something scheduled for removal, which is not the intent and not true.

What is superseded is `selector.Select` — the thing that turns a matched route into a dispatch plan, which `pkg/govplan` now does from cadre's governed plan instead. `MatchRoutes` is a level below that and has legitimate other consumers.

**2. `pkg/roster.Select` is a third plan-producing path, and it is the one that actually duplicates cadre.** Its own doc comment:

> Select matches the request against the roster's routes and builds a multi-role `types.DispatchPlan` for the best match. Matching reuses the catalog engine and then applies the roster-specific post-filters that the native catalog cannot express: **`keyword_groups` AND-of-OR** … **`exclude_paths`** …

Those are cadre's routing concepts by name. `keyword_groups` and `exclude_paths` are fields in cadre's `routing.json`, and `exclude_paths`' inverted-polarity rule is **correction #2 in AC-07's own list**. So gloop already re-implements part of cadre's routing semantics, against cadre-format rosters, in a package nobody looked at.

That is a far closer duplicate of cadre's selection than `pkg/selector` ever was — and AC-07's claim that only one implementation is reachable by new code is false as shipped.

## Root cause

AI-1 required a four-axis inventory and one was run. Axis 1's output was then truncated to ten lines by the command that produced it, and the truncation was invisible in the result.

**A new practice item: an inventory whose output is piped through `head` is not an inventory.** Count first, then read all of it.

## What this does not undo

`pkg/govplan` and everything in T-01 through T-04 stand. Reading cadre's governed plan, refusing past a human gate, and the corpus equivalence across 25 cases are unaffected — none of them depended on this.

## Decisions needed

1. **Un-deprecate `catalog.MatchRoutes`?** Recommended yes: it is a shared engine, not a superseded interface, and only `selector.Select` was meant to be marked.
2. **What happens to `pkg/roster.Select`?** It re-implements cadre routing semantics against cadre-format rosters. Options: deprecate it too and route roster-backed planning through cadre; keep it as gloop's own external-roster feature and narrow AC-07 to say so explicitly; or treat it as its own phase, since it is a larger question than T-05 was scoped for.
