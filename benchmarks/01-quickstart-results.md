# 01 - Measure: latency baseline

Model `Qwen3.5 0.8B` · host `Linux-x86_64` · llama.cpp `b10488`
Settings: `threads=6` `ngl=0` `ctx=2048`
`max_tokens=64` · warm-up discarded
Completed requests: `Q4_K_M` 10/10 · `UD-Q2_K_XL` 10/10

| Quantization | Size (GB) | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode (tok/s) |
|:--|--:|--:|--:|--:|--:|--:|
| Q4_K_M | 0.50 | 2083 | 304 / 355 | 31.4 / 32.7 | 2247 / 2414 / 2414 | 31.8 |
| UD-Q2_K_XL | 0.39 | 2067 | 428 / 471 | 33.1 / 40.4 | 2513 / 2993 / 2993 | 30.2 |

- **TTFT** = prefill. Short prompts keep it small; long-context RAG is where it explodes.
- **TPOT** = per-output-token decode cost, bounded by memory bandwidth. `decode tok/s = 1000 / TPOT_p50`.
- `UD-Q2_K_XL` decodes **1.05x SLOWER** than `Q4_K_M` here, despite being 0.11 GB smaller. That is a real result, not a mistake: fewer bits only buys speed when decode is limited by memory bandwidth. On a machine that is compute-limited instead — few cores, no GPU offload — the extra dequantization work of a heavily-quantized format can cost more than the bytes it saves. Say which case yours is.

## Your observation

On this CPU, `Q4_K_M` is the faster option: its 31.8 tok/s decode rate is 5.0% higher
than `UD-Q2_K_XL` (30.2 tok/s), while Q2 is 0.11 GB, or 22%, smaller. Q2 also had 1.41x
the TTFT P50 and 1.12x the E2E P50. On the same deterministic question, Q4 produced a
more structured answer; both had factual weaknesses, but Q2 was more diffuse. I would
keep Q4 for latency/quality on this machine and choose Q2 only when the disk saving is
more important than the small measured slowdown.
