# 03 - Integrate: RAG pipeline run

Host `Linux-x86_64` · llama.cpp `b10488` ·
retrieval backend: **keyword overlap** · 3 queries

| Query | Contexts retrieved | embed (ms) | retrieve (ms) | llm (ms) | total (ms) |
|:--|--:|--:|--:|--:|--:|
| Why is goodput more useful than raw throughp... | goodput, paged, radix | 0.0 | 0.0 | 5963.0 | 5963.1 |
| What problem does PagedAttention actually so... | paged, radix, disagg | 0.0 | 0.1 | 4134.4 | 4134.6 |
| When does splitting prefill and decode help?... | disagg, radix, batching | 0.0 | 0.1 | 5575.8 | 5575.9 |

Mean per stage (ms): embed **0.0** · retrieve **0.1** ·
llm **5224.4** · total **5224.5**
Dominant stage: **llm** (100% of total)

## Answers returned

**Why is goodput more useful than raw throughput?**

> Based on the context provided, **Goodput** is more useful than raw throughput because it filters out traffic that does not meet the specific performance targets (TTFT and TPOT).

While raw throughput counts all requests per second, Goodput specifically counts only the requests that successfully met these targets. This means Goodput provides a more accurate and targeted measure of actual system per

**What problem does PagedAttention actually solve?**

> PagedAttention solves the problem of **internal fragmentation in GPU memory** caused by storing the Key-Value (KV) cache in non-contiguous pages.

Specifically, it addresses the issue where most GPU memory is wasted due to this fragmentation. By storing the KV cache in non-contiguous pages, the model can remove this internal fragmentation, thereby optimizing the use of available GPU memory.

**When does splitting prefill and decode help?**

> Splitting prefill and decode helps when **prefill is compute-bound and decode is memory-bound**.

In this scenario, the system uses a strategy where prefill is executed on a compute-bound device (e.g., GPU), and the decoding happens on a memory-bound device (e.g., CPU). By separating these operations into distinct pools, the system can utilize the compute-bound device for the heavy lifting of the


## Which N16-N19 pieces are real

N16 Cloud/IaC, N17 data pipeline, N18 lakehouse, and N19 vector/features are all
**stubbed/local** in this run: the repository uses an in-memory `TOY_DOCS` list and
keyword-overlap retrieval, with no cloud, batch orchestrator, lakehouse, or vector
index. N20 is **real**: the three queries went through the local llama-server HTTP
endpoint. The mean LLM stage was 5,224.4 ms of 5,224.5 ms total (100% when rounded),
which matches the expectation that generation dominates; retrieval was only 0.1 ms.
To halve latency I would attack the LLM stage first, for example by reducing output
budget or improving decode/prompt efficiency, rather than optimizing the negligible
keyword lookup.
