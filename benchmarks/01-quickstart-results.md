# 01 - Measure: latency baseline

Model `Qwen3.5 0.8B` · host `Linux-x86_64` · llama.cpp `b10488`
Settings: `threads=6` `ngl=0` `ctx=2048`
`max_tokens=64` · warm-up discarded
Completed requests: `Q4_K_M` 10/10 · `UD-Q2_K_XL` 10/10

| Quantization | Size (GB) | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode (tok/s) |
|:--|--:|--:|--:|--:|--:|--:|
| Q4_K_M | 0.50 | 2110 | 165 / 202 | 18.2 / 20.0 | 1290 / 1418 / 1418 | 54.9 |
| UD-Q2_K_XL | 0.39 | 2051 | 376 / 403 | 28.5 / 31.1 | 2158 / 2330 / 2330 | 35.1 |

- **TTFT** = prefill. Short prompts keep it small; long-context RAG is where it explodes.
- **TPOT** = per-output-token decode cost, bounded by memory bandwidth. `decode tok/s = 1000 / TPOT_p50`.
- `UD-Q2_K_XL` decodes **1.56x SLOWER** than `Q4_K_M` here, despite being 0.11 GB smaller. That is a real result, not a mistake: on this CPU-only run, the result is consistent with extra dequantization work outweighing the saved memory traffic.

## Observation from this run

`Q4_K_M` was faster on this CPU: 54.9 tok/s versus 35.1 tok/s, so it was 1.56x
faster (56.4% higher decode throughput). `UD-Q2_K_XL` saved 0.11 GB (22% of the
Q4 size), but its TTFT P50 was 2.28x higher and its E2E P50 was 1.67x higher.
The current repository has no paired quality-result evidence, so I make no quality
claim. For this run I would keep Q4; Q2 is worth considering only when disk size
matters more than the measured latency.
