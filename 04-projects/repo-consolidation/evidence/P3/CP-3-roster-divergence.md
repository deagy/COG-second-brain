# `pkg/roster.Select` already diverges from the semantics it claims

Gathered before recommending its fate, because reasoning about it was what produced the wrong answer twice.

## The claim

`pkg/roster.Select` matches an external, cadre-format roster (`roster.json` + `catalog.yaml` + `routing.json` + `AGENT.md` roles) and states that it applies "the roster-specific post-filters that the native catalog cannot express":

> `exclude_paths`: if any request file matches an exclude pattern, **the route is dropped**

## Cadre's actual rule

`internal/selector/match.go:182`, in cadre's own words:

> `exclude_paths` subtracts at the ***file*** level, not the rule level: a route whose include glob is deliberately broad can carve out the paths that glob was never meant to reach **while still matching on any other changed file**.

Confirmed in the implementation: the excluder is applied per file inside the `paths` loop, removing that file from the match. The route survives on any other file.

## They disagree, materially

Take files `[internal/api/handler.go, vendor/lib.go]` and a route with `paths: ["**/*.go"]`, `exclude_paths: ["vendor/**"]`.

- **cadre**: the route matches, on `handler.go`. `vendor/lib.go` is subtracted.
- **gloop roster** (`postFilter` → `excludedBy(ex.ExcludePaths, req.Files)`): the route is dropped entirely.

The same roster produces different plans depending on which engine reads it. And `exclude_paths`' polarity is **correction #2 in AC-07's own list** — the rule the ultragoal already identified as one that must not be lost.

## Why this settles the question

The three options for `pkg/roster.Select` were: deprecate it, keep it as gloop's own feature, or defer it to its own phase. The evidence removes the middle one as currently written.

gloop does not merely have a similar feature — it **claims cadre's semantics** and implements one of them backwards. Claiming compatibility while diverging is worse than either honest alternative: a user reading a cadre roster through gloop gets a plan they have every reason to believe cadre would have produced, and it is not.

So either gloop stops claiming compatibility and documents its own semantics loudly, or it stops implementing them and reads cadre's plan. The north-star chooses the second.

## Recommendation

1. **Report the divergence as a defect now**, independent of any consolidation decision. A shipped function that claims cadre-compatible filtering and inverts one of the rules is wrong today, for anyone using it today.
2. **Deprecate `pkg/roster.Select`'s planning on `selector.Select`'s timeline**, pointing at `pkg/govplan`.
3. **Do not fix the divergence first.** Correcting it would mean maintaining a faithful second implementation of cadre's routing indefinitely, which is the thing this ultragoal exists to stop. Fixing a duplicate you intend to retire buys nothing but the appearance of diligence.

Point 3 is the one worth arguing about. The case against it: users of `roster plan` today get wrong results until the deprecation lands. The case for it: the deprecation can land immediately, and a documented "this diverges, use cadre" is more honest than a silent fix that entrenches the duplicate for another release cycle.

## Scope note

This is larger than T-05 was written for. `pkg/roster` is a documented gloop feature with its own guide (`docs/ROSTER.md`), team recipes, capability classes and parallel-wave execution. Deprecating its planning path is a product decision, not a cleanup.
