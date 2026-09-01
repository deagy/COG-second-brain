# Near-duplicate paragraph detector for the knowledge-store governance docs.
# Rounds 2 and 3 both failed on a stale paragraph left standing beside its
# corrected rewrite. Similarity of opening words is the signature.
import io, sys, glob, difflib
FILES = (glob.glob('roster/knowledge-store/*.md') + glob.glob('roster/workflows/*.md')
         + ['roster/shared/knowledge-use-policy.md', 'roster/context-store/README.md',
            'roster/operations/retention-and-deletion-executor/AGENT.md', 'roster/RUNBOOK.md',
            '.agents/skills/run-agent-orchestration/references/dispatch-contract.md'])
hits = 0
for path in sorted(set(FILES)):
    try:
        raw = io.open(path, encoding='utf-8').read()
    except OSError:
        continue
    paras = [(i, p.strip()) for i, p in enumerate(raw.split('\n\n')) if len(p.strip()) > 120]
    for a in range(len(paras)):
        for b in range(a + 1, len(paras)):
            ta, tb = paras[a][1], paras[b][1]
            if difflib.SequenceMatcher(None, ta[:400], tb[:400]).ratio() > 0.75:
                hits += 1
                print(f"{path}: paragraphs {paras[a][0]} and {paras[b][0]} are "
                      f"{difflib.SequenceMatcher(None, ta[:400], tb[:400]).ratio():.0%} similar")
                print(f"    A: {ta[:110]}...")
                print(f"    B: {tb[:110]}...")
print(f"\n{hits} near-duplicate pair(s)")
sys.exit(1 if hits else 0)
