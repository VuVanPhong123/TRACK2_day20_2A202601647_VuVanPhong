# 02 - Serve: load test + saturation reading

Host `Linux-x86_64` · llama.cpp `b10488` ·
`--parallel 4` · `ctx=2048` · `threads=6` ·
`ngl=0`

| Users | Reqs | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|:--|--:|--:|--:|--:|--:|--:|--:|
| 10 | 59 | 0.92 | 8000 | 14000 | 15000 | 7.6 | 0.0% |
| 50 | 55 | 0.85 | 23000 | 55000 | 55000 | 22.8 | 0.0% |

*Effective concurrency = RPS x average latency (Little's Law) -- how many requests were
really in flight, regardless of how many users locust simulated. It counts queued requests
too, so the occupancy/slot ratio can legitimately exceed 1.0; it is occupancy, not
utilisation. For true slot utilisation use the server's own gauges (`make metrics`).*

## What these two runs say

| Going from 10 to 50 users | |
|:--|--:|
| Offered load | 5x |
| Throughput actually delivered | **0.93x** (19% of linear) |
| P95 latency | **3.93x** |
| Effective concurrency at 50 users | 22.8 vs `--parallel 4` slots (occupancy/slot ratio 5.69) |

**Saturated.** Throughput delivered only 0.93x for 5x the offered load, and effective concurrency (22.8) is at or above all 4 decode slots. Saturation sets in somewhere at or below 50 users; the added load mostly increased queueing rather than producing linear throughput.

Throughput moved 0.93x while P95 moved 3.93x. That gap shows the added load was paid for mainly in latency; a chosen P95 SLO would be needed to calculate goodput, and these aggregate CSVs do not provide that percentage directly.

## Saturation reading

The tested range places saturation at or below 50 users, not at one exact point:
offered load rose 5x, but RPS fell from 0.92 to 0.85 (0.93x), while P95 rose
from 14,000 ms to 55,000 ms (3.93x). At 50 users, effective concurrency was
22.8 against 4 `--parallel` slots (5.69x the slot count), and the overlapping
metrics run measured 3.94356 busy slots plus 46 deferred requests. These are
strong queueing and slot-pressure signals; they show that the added load mostly
increased waiting, but do not identify an exact knee or split queue time from
compute time. I would retest with `-t 3` first: the current tuning evidence is
33.74 versus 32.17 tok/s at `-t 6` (1.0488x), while increasing `--parallel` could
admit more queued work without increasing CPU decode capacity.
