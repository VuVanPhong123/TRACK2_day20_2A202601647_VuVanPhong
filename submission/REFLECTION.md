# Reflection — Day 20 Lab (Personal Report)

> **Đây là báo cáo cá nhân.** Số liệu của bạn **không** so sánh được với bạn cùng lớp
> — chỉ so **before vs after trên chính máy bạn**. Rubric chấm độ rõ ràng của setup,
> đo lường và **lập luận**, không chấm tốc độ tuyệt đối.
>
> `make verify` sẽ fail nếu còn placeholder chưa điền. Đó là cố ý.

**Họ Tên:** Vũ Văn Phong
**Student ID / MSSV:** 2A202601647
**Cohort:** 3
**Ngày submit:** 2026-08-20

---

## 1. Hardware & runtime  *(rubric 1, 2 — 10 điểm)*

> Từ `make probe`. Paste output hoặc điền tay.

- **OS:** Linux 6.6.87.2-microsoft-standard-WSL2 (Windows 11 host)
- **CPU:** 13th Gen Intel(R) Core(TM) i5-13420H
- **Cores:** 6 physical / 12 logical
- **CPU extensions:** AVX2
- **RAM:** 7.6 GB
- **Accelerator:** CPU only; no CUDA, ROCm, Metal, or Vulkan device detected
- **llama.cpp asset đã tải:** `llama-b10488-bin-ubuntu-x64.tar.gz` (build b10488)
- **Model đã dùng:** Qwen3.5 0.8B (`LAB_MODEL=qwen35-0.8b`)
- **Quantization:** Q4_K_M + UD-Q2_K_XL (từ `models/active.json`)

**Chạy ở đâu:** local WSL2 trên laptop này
_(Nếu dùng cloud fallback: nói rõ vì sao — RAM < 8 GB, setup fail, v.v. Không mất điểm.)_

**Setup story** (≤ 80 chữ): điều gì cần thay đổi để lab chạy trên máy bạn? Có bước
nào fail rồi phải workaround không?

Probe tự chọn Qwen3.5 0.8B vì 7.6 GB RAM thấp hơn ngưỡng 8 GB của Gemma 4 E2B. Setup cài venv,
runtime llama.cpp prebuilt và tải đủ hai GGUF; không cần workaround hay GPU.

---

## 2. Đo lường  *(rubric 3, 4, 5 — 20 điểm)*

> Paste bảng từ `benchmarks/01-quickstart-results.md` (`make bench` tự sinh).

| Quantization | Size (GB) | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode (tok/s) |
|---|--:|--:|--:|--:|--:|--:|
| Q4_K_M | 0.50 | 2110 | 165 / 202 | 18.2 / 20.0 | 1290 / 1418 / 1418 | 54.9 |
| UD-Q2_K_XL | 0.39 | 2051 | 376 / 403 | 28.5 / 31.1 | 2158 / 2330 / 2330 | 35.1 |

**Quan sát** (≤ 60 chữ): 2-bit nhanh hơn bao nhiêu, và **có đáng không**? Bạn đã thử
hỏi cùng một câu trên cả hai (`make serve` vs `.venv/bin/python labs/02-serve/serve.py --compare`)
chưa? Chất lượng khác nhau thế nào?

Q4 nhanh hơn trên run này: 54.9 so với 35.1 tok/s, tức 1.56x (56.4%) cao hơn ở decode. Q2 nhỏ hơn 0.11 GB, tương đương 22% kích thước Q4, nhưng TTFT P50 cao hơn 2.28x và E2E P50 cao hơn 1.67x. Repository hiện không có bằng chứng chất lượng trả lời theo cặp, nên tôi không khẳng định khác biệt chất lượng. Với ưu tiên latency, tôi chọn Q4; Q2 chỉ đáng chọn nếu tiết kiệm dung lượng quan trọng hơn.

---

## 3. Serving under load  *(rubric 8, 9, 10 — 20 điểm)*

> Từ `benchmarks/02-server-results.md` (`make load-report`).

| Users | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|--:|--:|--:|--:|--:|--:|--:|
| 10 | 0.92 | 8000 | 14000 | 15000 | 7.6 | 0.0% |
| 50 | 0.85 | 23000 | 55000 | 55000 | 22.8 | 0.0% |

- **Offered load tăng 5×, throughput thực:** 0.93× (0.92 → 0.85 RPS)
- **P95 tăng:** 3.93× (14,000 → 55,000 ms)
- **Effective concurrency ở 50 users:** 22.8 so với `--parallel` = 4 slots (5.69× slot count)

**Peak `llamacpp:n_busy_slots_per_decode`** (từ `make metrics` khi `make load-50` đang
chạy): 3.94356 / 4 slots (99%); `requests_processing` đạt 4, `requests_deferred`
đạt 46, và `tokens_predicted_total` kết thúc ở 6,832.

**Saturation reading** (≤ 80 chữ): server của bạn bão hoà ở đâu, và **bằng chứng nào**
thuyết phục bạn? Nếu P95 tăng nhanh hơn RPS thì phần latency thêm đó là queue time hay
compute time — bạn biết bằng cách nào? Nếu bạn phải nâng goodput@SLO, bạn sẽ đổi knob
nào **trước**, và vì sao knob đó?

Trong range đã đo, saturation nằm ở hoặc dưới 50 users, chưa thể chỉ ra một knee chính xác: offered load tăng 5x nhưng RPS giảm từ 0.92 xuống 0.85 (0.93x), còn P95 tăng 3.93x từ 14,000 lên 55,000 ms. Effective concurrency 50 users là 22.8 so với 4 slots; metrics chồng thời gian ghi 3.94356/4 busy slots và 46 request deferred. Điều này cho thấy queueing góp phần lớn vào latency thêm, nhưng dữ liệu không tách chính xác queue time khỏi compute time. Tôi sẽ retest `-t 3` trước: tuning hiện tại đo 33.74 so với 32.17 tok/s ở `-t 6` (1.0488x), còn tăng `--parallel` có thể chỉ nhận thêm queue trên CPU này.

---

## 4. Integration  *(rubric 12, 13 — 15 điểm)*

> Từ `make pipeline`. Nói thật cái nào real, cái nào stub — stub **không** mất điểm.

| Day | Piece | Real hay stub? |
|---|---|---|
| N16 Cloud/IaC | stubbed/local |
| N17 Data pipeline | stubbed/local |
| N18 Lakehouse | stubbed/local |
| N19 Vector + features | stubbed/local: `TOY_DOCS` + keyword overlap |
| N20 Serving | `llama-server` | real |

**Latency split** (mean của 3 query, từ output của `pipeline.py`):

- embed: 0.0 ms
- retrieve: 0.0 ms
- llm: 2814.3 ms
- **stage chiếm nhiều nhất:** llm (100% của total khi làm tròn)

**Reflection** (≤ 60 chữ): bottleneck ở đâu? Có khớp với kỳ vọng của bạn không? Nếu
phải giảm latency của pipeline này 2×, bạn sẽ tấn công vào đâu?

N16 Cloud/IaC, N17 data pipeline, N18 lakehouse, và N19 vector/features đều là local stubs: pipeline dùng `TOY_DOCS` trong memory và keyword overlap, không có cloud, batch orchestrator, lakehouse hay vector index thật. N20 serving là **real** qua local `llama-server`. Ba query đều chạy và lấy được contexts. Mean hiện tại là embed 0.0 ms, retrieve 0.0 ms, llm 2814.3 ms, total 2814.4 ms; LLM là bottleneck (99.996%, làm tròn 100%). Muốn giảm 2x, tôi sẽ tấn công LLM decode hoặc giảm prompt/output work trước vì retrieval gần như không đáng kể.

---

## 5. The single change that mattered most  *(rubric 11 — 10 điểm)*

> **Phần quan trọng nhất của report.** Không cần bonus track: `make tune` đã cho bạn
> một before/after thật (`benchmarks/01-tuning-tg128.md`). Đổi quantization,
> `LAB_N_CTX`, hay `--parallel` rồi đo lại cũng được.

**Change:** hạ số thread decode từ `-t 6` xuống `-t 3`

```
before:  32.17 tok/s (`-t 6`)
after:   33.74 tok/s (`-t 3`)
speedup: 1.0488× (+4.88%)
```

**Tại sao nó work** (1–2 đoạn — đây là phần grader đọc kỹ nhất):

_Giải thích như đang nói với bạn ngồi cạnh. Bám vào **cơ chế**, không phải "vibes":
memory bandwidth? vector width? cache residency? scheduling? queueing? Nếu kết quả
**khác** với kỳ vọng từ deck — nói rõ, và giải thích vì sao. Grader thưởng điểm cho
lập luận đúng về một kết quả bất ngờ, hơn là một con số đẹp không được giải thích._

Sweep thật trên CPU này cho thấy knee ở 3 thread, thấp hơn 6 physical cores: thêm thread không còn tạo thêm decode work mà làm các worker tranh chấp CPU time, cache và memory bandwidth. `-t 12` giảm còn 21.33 tok/s và oversubscription `-t 24` giảm mạnh còn 2.41 tok/s, nên kết quả không phải một speedup được chọn vì số đẹp.

Vì vậy thay đổi nhỏ 6 → 3 cho 1.0488x (xấp xỉ 1.05x), nhưng nó là knob có bằng chứng trực tiếp và không làm tăng KV/slot memory. Đây là lý do tôi ưu tiên retest thread count trước khi tăng `--parallel`, vốn có thể chỉ biến thêm tải thành queue trên máy CPU này.

---

## 6. Bonus  *(optional — tối đa 20 điểm)*

> Bỏ trống nếu không làm. Xem `bonus/README.md`. Đừng làm hết — **một** finding sâu
> ăn điểm hơn năm bảng nông.

**Đã làm:** _<B1 build-compare / B2 sweep nào / B4 challenge nào / B5 lựa chọn nào>_

**Numbers:**

```
before:  <số>
after:   <số>
speedup: <X.Y>×
```

**Điều này nói lên gì mà deck chưa nói:**

_(để trống nếu bạn không làm phần này)_

---

## 7. Điều làm bạn ngạc nhiên nhất  *(optional)*

_(1–2 câu. Không bắt buộc, nhưng grader đọc hết.)_

_(để trống nếu bạn không làm phần này)_

---

## 8. Self-check trước khi push

- [x] `hardware.json` committed
- [x] `models/active.json` committed
- [x] `benchmarks/01-quickstart-results.md` committed (`make bench`)
- [x] `benchmarks/01-tuning-tg128.md` committed (`make tune`)
- [x] `benchmarks/02-server-results.md` committed (`make load-report`)
- [x] `benchmarks/02-server-batching-u50.md` hoặc `-metrics-u50.csv` committed (`make metrics`)
- [x] `benchmarks/locust-10_stats.csv` + `locust-50_stats.csv` committed (`make load-10` / `load-50`)
- [x] `benchmarks/03-integration-results.md` committed (`make pipeline`)
- [x] Mọi section **"required — replace this line"** trong các file `benchmarks/*.md`
      đã được thay bằng nhận xét của bạn
- [x] 5 screenshots trong `submission/screenshots/`
- [x] `make verify` → **exit 0**
- [x] Repo GitHub ở chế độ **public**
- [ ] Đã paste public URL vào VinUni LMS
- [x] **Không** commit `models/*.gguf` hay `runtime/` (đã có trong `.gitignore`)

**Quan trọng:** repo phải **public** đến khi điểm được công bố. Private → grader không
xem được → 0 điểm.
