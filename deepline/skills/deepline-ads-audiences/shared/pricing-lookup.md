# Pricing lookup

Read this before quoting any cost, estimating a run, or setting a budget cap.

`deepline tools describe <tool_id>` does **not** return a price. Most audience
providers return the literal string `Provider pricing details redacted.` in the
`description` field, and some return a `bestFor` line that contradicts the real
charge. So an agent asked "what will this cost?" has no price in the tool
contract, and the recurring failure is to fill the gap with a remembered or
invented number.

There is a real source: the workspace billing ledger. It records what every call
actually charged.

## Get real rates from the ledger

```bash
deepline billing ledger export all --output ./ledger.csv
```

The export can take a few minutes and reach tens of MB on an active workspace.
Run it in the background and keep working.

Relevant columns:

| Column | Meaning |
| --- | --- |
| `operation` | tool id, e.g. `limadata_find_audience_identifiers` |
| `charge_credits` | credits actually charged for that call |
| `pricing_model` | `fixed` (billed per call) or `per_result` (billed per result) |
| `pricing_basis` | `attempt` or `result` |
| `outcome` | `hit`, `unknown`, `no_result` |
| `created_at` | use this — rates change, see below |

Per-operation current rate:

```bash
python3 - <<'PY'
import csv, collections
rows = collections.defaultdict(list)
with open('ledger.csv') as f:
    for r in csv.DictReader(f):
        if r['operation']:
            rows[r['operation']].append(r)
for op in sorted(rows):
    recent = sorted(rows[op], key=lambda r: r['created_at'])[-200:]
    charges = collections.Counter(r['charge_credits'] for r in recent)
    model = recent[-1]['pricing_model'] or '?'
    basis = recent[-1]['pricing_basis'] or '?'
    print(f'{op:48s} {model:10s} {basis:8s} {charges.most_common(3)}')
PY
```

Convert with the workspace's own numbers rather than an assumed rate:

```bash
deepline billing usage --json   # balance vs rough_usd_balance gives credits->USD
```

## Use the most recent rate, not the average

Providers get repriced, and an all-time average silently blends old and new
rates into a number that was never charged. One measured example:

| Month | `limadata_find_audience_identifiers` |
| --- | --- |
| 2026-05 → 06 | 0.47 credits/call |
| 2026-07 | 0.29 credits/call |
| 2026-08 → 09 | 0.28 credits/call |

Averaging those gives ~0.44, which overstates a current 10k-row plan by about
57%. Always slice by `created_at` and quote the latest rate.

## Derive a per-result unit price

`per_result` operations do not record the result count in `result_count`, so
recover the unit price as the greatest common divisor of the observed charges:

```bash
python3 - <<'PY'
import csv
from math import gcd
op = 'contactout_get_hashed_email_identifiers'
ch = []
with open('ledger.csv') as f:
    for r in csv.DictReader(f):
        if r['operation'] == op and r['charge_credits']:
            ch.append(round(float(r['charge_credits']) * 100))
g = 0
for c in ch:
    g = gcd(g, c)
print(op, 'unit =', g / 100, 'credits per result')
PY
```

A GCD is an upper bound on the unit price: if every job in the sample happened
to return a multiple of N results, the true unit is the GCD divided by N. Say so
when the sample is small, and treat the figure as approximate rather than
quoting it as exact.

## Billing shape decides ladder order, not headline price

Two providers at the same headline rate cost very different amounts on the same
list, because a miss is free for one and billed for the other:

| `pricing_model` | Providers | Consequence |
| --- | --- | --- |
| `fixed` / `attempt` | LimaData, Aviato | Every row billed, hit or miss |
| `per_result` | ContactOut, LimaData batch | Misses free; suits a thin remainder |

To compare a `per_result` provider against a `fixed` one, multiply its unit
price by the match rate you actually observe. Comparing headline numbers
flatters the `per_result` provider on a low-match list and penalises it on a
high-match one.

## Quote the estimate honestly

When presenting a cost estimate, state:

- the per-unit rate **and** the date of the ledger rows it came from;
- whether each layer bills per attempt or per result;
- the hit-rate assumption, and that it is an assumption;
- a range, not a single number, when hit rates are unmeasured for this list.

A confident single figure built on a guessed hit rate is the thing this file
exists to prevent. If the ledger holds no rows for an operation, say the rate is
unknown and offer a priced test batch instead of estimating.
