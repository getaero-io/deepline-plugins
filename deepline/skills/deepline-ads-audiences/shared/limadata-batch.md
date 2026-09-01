# LimaData batch ad audiences

`limadata_batch_ad_audiences` (BETA) resolves up to 100,000 LinkedIn URLs or
work emails to SHA-256 hashed ad-audience rows in one async job. On a
10,000-row list it replaces 10,000 sequential `limadata_find_audience_identifiers`
calls, so prefer it for any list of a few thousand rows or more.

## It is billed, despite what the catalog says

The tool's `bestFor` ends with "Not currently billed." **That line is wrong.**
Ledger rows for `limadata_batch_ad_audiences` show real charges — seven jobs
totalling 1,212.12 credits on one workspace in Aug 2026, `billing_stage:
posted`, `charge_state` settled.

Never present this endpoint to a user as free. Quote it from the ledger like any
other provider (→ `shared/pricing-lookup.md`) and treat the catalog line as a
known metadata bug.

## Billing shape

`pricing_model: per_result`, `pricing_basis: result` — you are billed for rows
the job **resolves**, not rows you submit. Unmatched rows in the batch are free,
which is the opposite of the sync per-row tool, where every attempt bills.

That difference decides where each belongs in the ladder:

| Tool | Model | Bills on |
| --- | --- | --- |
| `limadata_find_audience_identifiers` | `fixed` / `attempt` | Every row sent |
| `limadata_batch_ad_audiences` | `per_result` | Only resolved rows |

Because misses are free, the batch endpoint is safe to run across a whole list
without pre-filtering to likely hits. Do not spend a paid LinkedIn-repair or
verification pass just to trim its send set — that optimises a cost you do not
pay.

Observed charges were all exact multiples of 0.84 credits. Whether the unit is
0.84 per resolved person or 0.28 (the sync per-row rate) per returned hash with
three hashes per person cannot be settled from charge amounts alone, since both
divide every observed total. Confirm against `processed_entity_count` from
`limadata_batch_results` on a job you have run before quoting a firm per-row
number, and quote a range until then.

## Flow

```bash
deepline tools execute limadata_batch_ad_audiences --json --input '{
  "name": "abm-q3-meta",
  "urls": ["https://linkedin.com/in/example", "..."],
  "target_network": "meta"
}'
```

Returns a `batch_id` only. Poll for rows:

```bash
deepline tools execute limadata_batch_results --json --input '{"batch_id": 12345, "page": 1}'
```

Notes:

- `target_network` accepts `meta`, `google`, `tiktok`, `x`, `reddit`,
  `snapchat`, `pinterest`, `amazon`. Hash normalization differs per network, so
  set it to the platform you will upload to rather than taking the default.
- `limadata_batch_results` is free, so poll without worrying about cost.
- Results expire after **30 days**. Export them to CSV on completion.
- Page size is 100. Follow `pagination` to the end; a partial read silently
  produces a short audience.
- Compare `processed_entity_count` against `requested_entity_count` to get the
  real hit rate, and report that rather than assuming every submitted row
  resolved.
- `notification_url` takes a webhook, which beats polling a long job.

## When to use which

| Situation | Use |
| --- | --- |
| A few thousand rows or more | `limadata_batch_ad_audiences` |
| A handful of rows, or a live per-row waterfall where later layers must skip earlier hits | `limadata_find_audience_identifiers` |
| Rows already covered by another provider | Neither — skip them, unless running `max_coverage`, where extra addresses per person are the point |

The batch job returns rows keyed to the identifiers you submitted, so unlike the
ContactOut pool (→ `shared/contactout-hash-pool.md`) its output **is**
attributable per row and can waterfall normally.
