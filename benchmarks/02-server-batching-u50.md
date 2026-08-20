# 02 - Continuous batching under load (u50)

Host `Linux-x86_64` · `--parallel 4` · 27 samples over
60s at 2.0s intervals · raw CSV: `02-server-metrics-u50.csv`

| Gauge | Peak observed |
|:--|--:|
| `n_busy_slots_per_decode` (avg/decode) | 3.91 of 4 slots (98%) |
| `requests_processing` | 4 |
| `requests_deferred` | 46 |
| `kv_cache_usage_ratio` | n/a — not exported by llama.cpp `b10488` |
| `tokens_predicted_total` (final) | 4190 |

Highest sampled value was **3.91 of 4** slots. Note this gauge is llama.cpp's *average* busy slots per decode step, so the number below is the highest average we sampled, not an instantaneous maximum batch width. A peak near 1 means
requests were served one at a time -- either the load was too light to overlap, or
they arrived too far apart. A peak approaching `--parallel` means the scheduler was
genuinely packing concurrent requests into shared decode steps.
`requests_deferred` went above zero: more requests arrived than there were slots, so some waited. That wait is the queue time in your P95.

## Your observation

The peak `n_busy_slots_per_decode` was **3.91/4 (98%)**, with four requests processing
and up to 46 deferred during the overlapping run. This is consistent with the server
running all four decode slots, but it is lower than the **17.2** effective concurrency
from Little's Law in `02-server-results.md`. The difference is expected: the metric is
the average number of slots doing decode work, while effective concurrency also counts
the queued requests. I trust the server gauge for continuous-batching width and Little's
Law for total in-flight-plus-queued pressure.
