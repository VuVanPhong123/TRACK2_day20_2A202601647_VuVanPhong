# 01 - Tune: thread-count sweep

Model `Qwen3.5-0.8B-Q4_K_M.gguf` · host `Linux-x86_64` · llama.cpp `b10488`
CPU: **6 physical · 12 logical** cores · `ngl=0` · metric `tg128`

| threads (-t) | tg128 (tok/s) | vs best |
|:--|--:|--:|
| 1 | 22.7 | 67% |
| 3 | 33.7 | 100% |
| 6 | 32.2 | 95% |
| 12 | 21.3 | 63% |
| 24 | 2.4 | 7% |

**Best**: `-t 3` at 33.7 tok/s
**Slowest tested**: `-t 24` at 2.4 tok/s (14.00x spread)
**Against the physical-core default** (`-t 6`, 32.2 tok/s): 1.05x

Use this in your run:

```bash
LAB_N_THREADS=3 make bench
```

## Your explanation

The knee is at `-t 3`, not at the reported six physical cores: 33.7 tok/s is 1.05x the
`-t 6` baseline (32.2 tok/s). Adding threads past three reduced throughput to 21.3 tok/s
at 12 threads and 2.4 tok/s at 24. On this WSL2 CPU run, three workers appear sufficient
to keep the small model's decode work busy; more workers compete for the same CPU time,
cache and memory bandwidth, while the 24-thread point adds severe scheduler
oversubscription. I therefore use three threads as the measured tuning change rather
than assuming physical-core count must win.
