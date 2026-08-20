# Reflection — Day 20 Lab (Personal Report)

> **Đây là báo cáo cá nhân.** Số liệu của bạn **không** so sánh được với bạn cùng lớp
> — chỉ so **before vs after trên chính máy bạn**. Rubric chấm độ rõ ràng của setup,
> đo lường và **lập luận**, không chấm tốc độ tuyệt đối.
>
> `make verify` sẽ fail nếu còn placeholder chưa điền. Đó là cố ý.

**Họ Tên:** Vũ Văn Phong (inferred from the repository identity)
**Cohort:** Không xác định được từ repository hoặc user input; cần xác nhận trước khi submit.
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
| Q4_K_M | 0.50 | 2083 | 304 / 355 | 31.4 / 32.7 | 2247 / 2414 / 2414 | 31.8 |
| UD-Q2_K_XL | 0.39 | 2067 | 428 / 471 | 33.1 / 40.4 | 2513 / 2993 / 2993 | 30.2 |

**Quan sát** (≤ 60 chữ): 2-bit nhanh hơn bao nhiêu, và **có đáng không**? Bạn đã thử
hỏi cùng một câu trên cả hai (`make serve` vs `.venv/bin/python labs/02-serve/serve.py --compare`)
chưa? Chất lượng khác nhau thế nào?

Q4 nhanh hơn 5.0% ở decode (31.8 so với 30.2 tok/s); Q2 nhỏ hơn 0.11 GB/22% nhưng TTFT P50 cao hơn 1.41x và E2E P50 cao hơn 1.12x. Trên cùng một prompt, Q4 có cấu trúc tốt hơn còn Q2 lan man hơn; tôi chọn Q4 trên máy này.

---

## 3. Serving under load  *(rubric 8, 9, 10 — 20 điểm)*

> Từ `benchmarks/02-server-results.md` (`make load-report`).

| Users | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|--:|--:|--:|--:|--:|--:|--:|
| 10 | 0.63 | 12000 | 24000 | 28000 | 8.1 | 0.0% |
| 50 | 0.61 | 29000 | 54000 | 57000 | 17.2 | 0.0% |

- **Offered load tăng 5×, throughput thực tăng:** 0.98×
- **P95 tăng:** 2.25×
- **Effective concurrency ở 50 users:** 17.2 so với `--parallel` = 4 slots

**Peak `llamacpp:n_busy_slots_per_decode`** (từ `make metrics` khi `make load-50` đang
chạy): 3.91 / 4 slots

**Saturation reading** (≤ 80 chữ): server của bạn bão hoà ở đâu, và **bằng chứng nào**
thuyết phục bạn? Nếu P95 tăng nhanh hơn RPS thì phần latency thêm đó là queue time hay
compute time — bạn biết bằng cách nào? Nếu bạn phải nâng goodput@SLO, bạn sẽ đổi knob
nào **trước**, và vì sao knob đó?

Trong range đã đo, saturation nằm ở hoặc dưới 50 users: RPS gần như phẳng (0.63 → 0.61) nhưng P95 tăng 2.25x. Metrics đồng thời ghi 3.91/4 busy slots và 46 request deferred. Với SLO P95 30 s, 10 users nằm dưới ngưỡng còn 50 users vượt ngưỡng; CSV aggregate không đủ để tính goodput chính xác. Tôi sẽ retest `-t 3` trước vì sweep đo được 33.7 thay 32.2 tok/s, không tăng áp lực KV như tăng `--parallel`.

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
- retrieve: 0.1 ms
- llm: 5224.4 ms
- **stage chiếm nhiều nhất:** llm (100% của total khi làm tròn)

**Reflection** (≤ 60 chữ): bottleneck ở đâu? Có khớp với kỳ vọng của bạn không? Nếu
phải giảm latency của pipeline này 2×, bạn sẽ tấn công vào đâu?

N16–N19 là local stubs; N20 llama-server là real. LLM đúng như dự đoán là bottleneck (5224.4/5224.5 ms), còn retrieval chỉ 0.1 ms. Muốn giảm 2x, tôi sẽ giảm output/prompt cost hoặc tối ưu decode trước.

---

## 5. The single change that mattered most  *(rubric 11 — 10 điểm)*

> **Phần quan trọng nhất của report.** Không cần bonus track: `make tune` đã cho bạn
> một before/after thật (`benchmarks/01-tuning-tg128.md`). Đổi quantization,
> `LAB_N_CTX`, hay `--parallel` rồi đo lại cũng được.

**Change:** hạ số thread decode từ `-t 6` xuống `-t 3`

```
before:  32.2 tok/s (`-t 6`)
after:   33.7 tok/s (`-t 3`)
speedup: 1.05×
```

**Tại sao nó work** (1–2 đoạn — đây là phần grader đọc kỹ nhất):

_Giải thích như đang nói với bạn ngồi cạnh. Bám vào **cơ chế**, không phải "vibes":
memory bandwidth? vector width? cache residency? scheduling? queueing? Nếu kết quả
**khác** với kỳ vọng từ deck — nói rõ, và giải thích vì sao. Grader thưởng điểm cho
lập luận đúng về một kết quả bất ngờ, hơn là một con số đẹp không được giải thích._

Sweep thật trên CPU này cho thấy knee ở 3 thread, thấp hơn 6 physical cores: thêm thread không còn tạo thêm decode work mà làm các worker tranh chấp CPU time, cache và memory bandwidth. `-t 12` giảm còn 21.3 tok/s và oversubscription `-t 24` giảm mạnh còn 2.4 tok/s, nên kết quả không phải một speedup được chọn vì số đẹp.

Vì vậy thay đổi nhỏ 6 → 3 chỉ cho 1.05×, nhưng nó là knob có bằng chứng trực tiếp và không làm tăng KV/slot memory. Đây là lý do tôi ưu tiên retest thread count trước khi tăng `--parallel`, vốn có thể chỉ biến thêm tải thành queue trên máy CPU này.

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

- [ ] `hardware.json` committed
- [ ] `models/active.json` committed
- [ ] `benchmarks/01-quickstart-results.md` committed (`make bench`)
- [ ] `benchmarks/01-tuning-tg128.md` committed (`make tune`)
- [ ] `benchmarks/02-server-results.md` committed (`make load-report`)
- [ ] `benchmarks/02-server-batching-u50.md` hoặc `-metrics-u50.csv` committed (`make metrics`)
- [ ] `benchmarks/locust-10_stats.csv` + `locust-50_stats.csv` committed (`make load-10` / `load-50`)
- [ ] `benchmarks/03-integration-results.md` committed (`make pipeline`)
- [ ] Mọi section **"required — replace this line"** trong các file `benchmarks/*.md`
      đã được thay bằng nhận xét của bạn
- [ ] 5 screenshots trong `submission/screenshots/`
- [ ] `make verify` → **exit 0**
- [ ] Repo GitHub ở chế độ **public**
- [ ] Đã paste public URL vào VinUni LMS
- [ ] **Không** commit `models/*.gguf` hay `runtime/` (đã có trong `.gitignore`)

**Quan trọng:** repo phải **public** đến khi điểm được công bố. Private → grader không
xem được → 0 điểm.
