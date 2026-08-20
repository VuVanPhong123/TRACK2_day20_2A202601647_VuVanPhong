# 03 - Integrate: RAG pipeline run

Host `Linux-x86_64` · llama.cpp `b10488` ·
retrieval backend: **keyword overlap** · 3 queries

| Query | Contexts retrieved | embed (ms) | retrieve (ms) | llm (ms) | total (ms) |
|:--|--:|--:|--:|--:|--:|
| Why is goodput more useful than raw throughp... | goodput, paged, radix | 0.0 | 0.0 | 3090.4 | 3090.4 |
| What problem does PagedAttention actually so... | paged, radix, disagg | 0.0 | 0.0 | 2160.7 | 2160.8 |
| When does splitting prefill and decode help?... | disagg, radix, batching | 0.0 | 0.0 | 3191.9 | 3192.0 |

Mean per stage (ms): embed **0.0** · retrieve **0.0** ·
llm **2814.3** · total **2814.4**
Dominant stage: **llm** (100% of total)

## Answers returned

**Why is goodput more useful than raw throughput?**

> Based on the provided context, **Goodput** is more useful than raw throughput because it explicitly accounts for the **SLOs (Service Level Objectives)**, while raw throughput ignores them.

The text explains this by stating:
> "Goodput@SLO counts only the requests per second that met the TTFT and TPOT targets. Throughput at saturation ignores SLOs."

Since Goodput filters for requests that meet sp

**What problem does PagedAttention actually solve?**

> PagedAttention solves the problem of **internal fragmentation** in GPU memory.

By storing the Key-Value (KV) cache in non-contiguous pages, the model avoids the wasted space that would exist if all KV data were packed tightly into a single contiguous block. This allows the engine to utilize more of the available GPU memory for computation and data transfer, which is particularly beneficial for la

**When does splitting prefill and decode help?**

> Based on the provided context, splitting prefill and decode helps during the **prefill** phase.

The reasoning is as follows:
1.  **Prefill is compute-bound**: It requires significant processing power.
2.  **Splitting allows parallelization**: By splitting the prefill and decoding tasks, the system can process compute-bound tasks in parallel rather than sequentially.
3.  **Result**: This reduces t


## N16-N19 reality check

N16 Cloud/IaC: **stubbed/local**; N17 data pipelines: **stubbed/local**; N18
Lakehouse: **stubbed/local**; N19 vector + features: **stubbed/local** using the
in-memory `TOY_DOCS` list and keyword-overlap retrieval. N20 serving is **real**:
all three queries used the local `llama-server` HTTP endpoint and returned
retrieved contexts. The current mean timings are embed 0.0 ms, retrieve 0.0 ms,
LLM 2,814.3 ms, and total 2,814.4 ms; LLM is 100% when rounded and is the
expected bottleneck. To halve latency I would attack LLM generation/decode or
reduce prompt/output work, because retrieval is negligible in this run.
