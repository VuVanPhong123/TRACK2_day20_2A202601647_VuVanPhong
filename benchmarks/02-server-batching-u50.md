# 02 - Continuous batching under load (u50)

Host `Linux-x86_64` · `--parallel 4` · 28 samples over
60s at 2.0s intervals · raw CSV: `02-server-metrics-u50.csv`

| Gauge | Peak observed |
|:--|--:|
| `n_busy_slots_per_decode` (avg/decode) | 3.94 of 4 slots (99%) |
| `requests_processing` | 4 |
| `requests_deferred` | 46 |
| `kv_cache_usage_ratio` | n/a — not exported by llama.cpp `b10488` |
| `tokens_predicted_total` (final) | 6832 |

Highest sampled value was **3.94 of 4** slots. Note this gauge is llama.cpp's *average* busy slots per decode step, so the number below is the highest average we sampled, not an instantaneous maximum batch width. A peak near 1 means
requests were served one at a time -- either the load was too light to overlap, or
they arrived too far apart. A peak approaching `--parallel` means the scheduler was
genuinely packing concurrent requests into shared decode steps.
`requests_deferred` went above zero: more requests arrived than there were slots, so some waited. That waiting contributes to P95, although this CSV does not isolate queue time from compute time.

## Observation from this run

The peak sampled `n_busy_slots_per_decode` was **3.94356 of 4 slots (99%)**;
`requests_processing` reached 4, `requests_deferred` reached 46, and
`tokens_predicted_total` finished at 6,832. This supports continuous batching and
queueing during the load-50 run. It does not equal the **22.8** effective
concurrency in `02-server-results.md` because Little's Law includes queued
requests, while the server gauge measures average decode-slot occupancy. I use
3.94356/4 to describe batch width and 22.8 to describe total in-flight-plus-queued
pressure.
