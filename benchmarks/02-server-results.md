# 02 - Serve: load test + saturation reading

Host `Linux-x86_64` · llama.cpp `b10488` ·
`--parallel 4` · `ctx=2048` · `threads=6` ·
`ngl=0`

| Users | Reqs | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|:--|--:|--:|--:|--:|--:|--:|--:|
| 10 | 38 | 0.63 | 12000 | 24000 | 28000 | 8.1 | 0.0% |
| 50 | 39 | 0.61 | 29000 | 54000 | 57000 | 17.2 | 0.0% |

*Effective concurrency = RPS x average latency (Little's Law) -- how many requests were
really in flight, regardless of how many users locust simulated. It counts queued requests
too, so the occupancy/slot ratio can legitimately exceed 1.0; it is occupancy, not
utilisation. For true slot utilisation use the server's own gauges (`make metrics`).*

## What these two runs say

| Going from 10 to 50 users | |
|:--|--:|
| Offered load | 5x |
| Throughput actually delivered | **0.98x** (20% of linear) |
| P95 latency | **2.25x** |
| Effective concurrency at 50 users | 17.2 vs `--parallel 4` slots (occupancy/slot ratio 4.30) |

**Saturated.** Throughput delivered only 0.98x for 5x the offered load, and effective concurrency (17.2) is at or above all 4 decode slots. Saturation sets in somewhere at or below 50 users; the load you added beyond that point became queue time rather than throughput.

Throughput moved 0.98x while P95 moved 2.25x. That gap is the goodput argument: past saturation you buy throughput by spending latency, and if your SLO is a P95 target then the requests you added are no longer being served within it. (This lab does not fix an SLO number for you -- pick one in your write-up and state how much goodput you keep at it.)

## Your reading

The tested range is already saturated at or below 50 users: offered load rose 5x, but
RPS moved from 0.63 to 0.61 (0.98x), while P95 inflated 2.25x from 24,000 to 54,000 ms.
At 50 users Little's-Law effective concurrency was 17.2 versus four slots, and the
overlapping metrics run measured 3.91/4 busy slots plus deferred requests. These are
queueing signals, not proof of an exact capacity point; with only 10- and 50-user
points, I can only place the knee at or below the tested 50-user regime. For a stated
P95 SLO of 30 s, the 10-user aggregate remains within the target but the 50-user run
does not; the CSV is too aggregate/thin to claim an exact goodput percentage. I would
first retest with the measured `-t 3` setting (33.7 vs 32.2 tok/s in the tune sweep),
because it improves decode without increasing KV/slot memory; raising `--parallel`
would likely admit more queueing on this CPU rather than improve SLO goodput.
