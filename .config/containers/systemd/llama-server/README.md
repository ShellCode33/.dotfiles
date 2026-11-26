# Local LLM inference with llama.cpp and llama-swap

This configuration runs local coding assistants (primarily Codex CLI) through llama-swap and llama.cpp on an Arch Linux desktop. The goal is to use the largest practical models, retain their native context windows, and balance prompt-processing speed, generation speed, memory usage and desktop responsiveness.

The settings are the result of iterative testing on this particular machine, not universal recommendations. The accompanying configuration is the source of truth for the currently active flags.

> **Status (2026-11-26):** The 125B profile completed an extended coding session at approximately 67K occupied context. The 35B profile is substantially faster on short prompts, but an extended run crashed near 72K context. Long-context stability on the smaller model is still under investigation.

## Hardware and software

| Component | Configuration |
| --- | --- |
| CPU | AMD Ryzen 9 7900X, 12 cores / 24 threads |
| System memory | 64 GB DDR5-6000 |
| GPU | AMD Radeon RX 6600, 8 GB VRAM (Navi 23) |
| GPU backend | Vulkan, Mesa RADV |
| OS / runtime | Arch Linux, Podman, systemd user service |
| Inference | llama.cpp, managed by llama-swap |
| Client | Codex CLI via the OpenAI-compatible Responses API |

The main benchmark series used llama.cpp revision `ea72294`, compiled with GNU 16.2.1. Earlier comparisons used `b1b770d`. The CPU startup logs confirm AVX2, AVX-512, AVX-512 VNNI/BF16 and OpenMP support. The original crash investigation identified Mesa 26.3.1 in the container.

The RX 6600 cannot hold either model entirely in VRAM. Both are mixture-of-experts (MoE) models, so keeping most expert weights in system memory while accelerating dense layers and attention on the GPU is the central strategy.

## Model profiles

| | Smaller model | Larger model |
| --- | --- | --- |
| Model | Qwen3.6-35B-A3B | Qwen3.8-Flash-Next-125B-A6B |
| Main GGUF | UD-Q4_K_XL | GSQ-RCO-Q2_0 |
| Main GGUF size | 20.81 GiB | 61.85 GiB |
| MTP draft | Q4_0 | Q4_K_M |
| Native context | 262,144 tokens | 262,144 tokens |
| Attention | Hybrid recurrent / full attention | Hybrid recurrent / indexed sparse attention |
| Intended role | Fast interactive coding | More demanding or extended coding tasks |

The larger model's nominal size is taken from its filename/model label; the GGUF loader reports a different total parameter count. The profile selection is based on resource use and observed inference behavior, not a controlled coding-quality evaluation.

## Why llama-swap?

Only one model should occupy resources at a time. llama-swap provides a stable API endpoint, starts the requested model on demand, and unloads it when switching profiles or after an idle period.

The tested routing setup uses an exclusive swapping group, a 600-second startup health-check timeout and a global idle TTL of 1,800 seconds. A long startup allowance is useful when loading multi-gigabyte weights. The TTL limits idle resource use, but unloading a process also discards its live context and in-memory caches.

For local-only use, bind the exposed API to loopback (or restrict access with a firewall). The tested proxy listened on `0.0.0.0:9931` without API authentication; that should not be exposed to untrusted networks.

## Shared llama.cpp settings

| Setting | Rationale |
| --- | --- |
| `--device Vulkan0` | Use the RX 6600 through RADV. |
| `--parallel 1` | Optimize for a single coding session rather than concurrent users. |
| `--threads 12 --threads-batch 12` | Use the 12 physical cores as a starting point for memory-heavy MoE inference. |
| `--ctx-size 0` | Use the context length advertised by the model rather than hardcoding a shared limit. |
| `--batch-size 2048` | Allow larger logical prompt batches for efficient bulk prefill. |
| `--flash-attn auto` | Use supported Flash Attention kernels; quantized V cache requires it in the tested build. |
| `--cache-type-k q8_0 --cache-type-v q8_0` | Reduce KV memory while retaining relatively conservative cache precision. |
| `--gpu-layers auto --fit on` | Let the fitter choose GPU weight placement based on available memory. |
| `--fit-target 512` | Aim to leave 512 MiB of VRAM free. This is a fitting target, not a hard runtime reservation. |
| `--split-mode layer` | Use layer-based placement on the selected GPU. |
| `--no-op-offload` | Disable opportunistic operation offloading to improve CPU/GPU graph placement. |
| `--log-verbosity 4` | Retain timing, placement and cache diagnostics while tuning. |

### Native context and cache allocation

The intention is to preserve the model's native context. In the tested build, explicitly passing `--ctx-size 0` with automatic fitting retained the full 262,144 tokens. Omitting the option allowed the fitter to reduce context to 4,096 tokens, which was insufficient for even a basic Codex request containing system instructions and tools.

A native context limit is not a guarantee of acceptable performance or stability throughout that window. Allocating the full context consumes memory even when few tokens are occupied. The smaller model reserves 2,720 MiB of main Q8 KV cache and another 272 MiB for the draft. The larger model reserves 3,264 MiB of main KV plus 816 MiB of indexer cache, distributed between CPU and GPU, with another 340 MiB of draft KV/indexer cache.

Reducing context would free memory for weights and could improve throughput, but would sacrifice the native-context goal. It is deliberately not the first tuning lever.

### Why `--no-op-offload`?

GPU layer placement and operation offloading are different mechanisms. The flag disables the scheduler's opportunistic offloading of host-side operations; it does **not** disable GPU inference or force all weights onto the CPU.

On the larger model, after a llama.cpp update, the default scheduler placed some sparse-attention operations on a different backend from their corresponding layers, disabling fused top-k masking. With `--no-op-offload`, fused top-k masking was enabled for both main and draft contexts. Main graph splits dropped from 1,195 to 32 in that particular comparison, and the main GPU compute buffer fell from approximately 1,149 to 603 MiB. Short-request throughput improved as well.

The smaller model also benefited from the combination of the updated build and this flag: the first 4,528-token prefill improved from roughly 224 to 360 tokens/s. That comparison includes a revision change, so the entire gain cannot be attributed to this option alone.

### Why 12 CPU threads?

The larger model generated approximately 19.26 tokens/s across a short test using 12 threads, versus slower generation with six threads in an earlier run. More threads are not automatically better: expert inference is sensitive to memory bandwidth, synchronization and placement. SMT and CPU affinity have not been exhaustively benchmarked. Twelve threads is the measured starting point rather than an asserted global optimum.

## Speculative decoding (MTP)

Both profiles use the model-specific multi-token prediction (MTP) draft model:

```text
--spec-type draft-mtp
--spec-draft-n-max 2
--spec-draft-n-ubatch 128
--spec-draft-type-k q8_0
--spec-draft-type-v q8_0
--spec-draft-model <matching MTP GGUF>
```

MTP proposes tokens for verification by the main model, reducing the number of expensive main-model decoding iterations when proposals are accepted. The draft consumes its own weights, cache and compute buffers, so accelerating generation can reduce the GPU resources available for main-model prefill.

The larger-model tests below explain why the maximum draft length is two rather than one or three. These were real Codex requests, not fixed-output microbenchmarks.

| Draft length | First prefill (tok/s) | Aggregate generation (tok/s) | Draft acceptance |
| --- | ---: | ---: | ---: |
| Disabled | 109.49 | 13.40 | — |
| 1 | 79.90 | 16.68 | 89.23% |
| 2 | 79.10 | 19.26 | 81.64% |
| 3 | 79.04 | 17.71 | 61.64% |

Without MTP, more main-model tensors and caches fit in VRAM, making prefill faster but generation slower. Draft length three incurred extra speculative work that did not pay off in the measured session. Two provides a useful balance, particularly for longer generated responses. The best choice remains workload-dependent.

### Separate draft microbatch

`--spec-draft-n-ubatch 128` reduces the draft's physical microbatch independently of the main model. This saved substantial GPU compute memory without requiring a smaller logical batch or context window:

| Draft GPU compute buffer | ubatch 512 | ubatch 128 |
| --- | ---: | ---: |
| 35B profile | 298.02 MiB | 74.50 MiB |
| 125B profile | 649.72 MiB | 200.59 MiB |

A draft microbatch of 64 was also tested on the larger model. It saved only another 18.17 MiB and did not increase the fitted layer count, so 128 was retained.

### CPU-resident draft experts

`--spec-draft-cpu-moe` moves the draft's expert weights into system memory while leaving eligible dense operations on the GPU. It is particularly valuable for the larger draft model.

| Large-model MTP configuration | Main fitted layers* | Main GPU weights | First prefill (tok/s) |
| --- | ---: | ---: | ---: |
| Default draft placement, ubatch 512 | 17/49 | 2,060.68 MiB | 79.10 |
| CPU draft experts only | 29/49 | 2,751.00 MiB | 88.85 |
| Draft ubatch 128 only | 21/49 | 2,293.78 MiB | 82.88 |
| CPU draft experts + ubatch 128 | 33/49 | 2,971.83 MiB | 93.20 |

*Fitted layers include layers with some expert tensors still on the CPU; this is not the number of fully GPU-resident layers.*

Together these changes save approximately 2.15 GiB in major draft GPU allocations, allowing more main-model weights and attention caches onto the GPU. This is the preferred tested large-model profile.

On the smaller model, CPU draft experts save 432 MiB of draft weight VRAM, but short-run decoding did not clearly improve. The option was enabled in the long run that crashed. Removing it is a useful isolation experiment, not a proven fix.

## Model-specific settings

| Setting | 35B tested performance profile | 125B preferred tested profile |
| --- | --- | --- |
| Main microbatch | `--ubatch-size 512` | `--ubatch-size 512` |
| Draft CPU experts | Enabled in failed long run; experimental | Enabled |
| RAM prompt cache | `--cache-ram 8192` | `--cache-ram 0` |
| Weight loading | `--load-mode none` | `--load-mode mmap` |
| Lazy loading | `--lazy-mode off` | `--lazy-mode auto` |
| Reasoning | `--reasoning-budget 512` | `--reasoning-effort low` |

### Loading and RAM cache

The 35B model fits comfortably enough in system memory to use explicit backend allocations (`none`), avoiding reliance on demand paging of the model file. This was retained in the faster tested configurations. It is not independently proven to be faster than mmap under every workload.

The 125B GGUF alone is almost as large as the machine's physical RAM. Memory mapping and lazy loading therefore matter much more. Startup logs show approximately 27,466 MiB of per-layer embedding weights eligible for lazy loading/prefetch. Mapped size is not the same as resident RAM usage. Eagerly loading everything, or allocating a large additional prompt cache, risks unnecessary memory pressure.

The RAM prompt cache stores reusable prompt states beyond the active slot. Disabling it does **not** disable the live KV cache or context checkpoints. Repeated requests in the same Codex session still reuse their common prefix. Checkpoints help restore hybrid recurrent state when a prompt changes, but they consume memory separately and do not survive process termination. The tested build allowed up to 32 checkpoints, around 68 MiB each on the smaller model and 120 MiB each on the larger one.

The reasoning settings are intended to avoid excessive reasoning latency. The 35B budget is a token limit mechanism; the 125B's low reasoning effort is a model/template-dependent preference, not an equivalent hard cap.

## Benchmark results

Local Codex sessions on 25–26 November 2026 were used to test realistic prompt reuse, tool loops and long-context behavior. The numbers below exclude initial auxiliary requests, incomplete requests and retries after the crash. Throughput is weighted by evaluated/generated tokens and time, not an arithmetic mean of per-request speeds. Generation uses the timing convention in the logs (generated count minus one per completed request). These workloads differ in prompt length, outputs and MTP acceptance, so comparisons are indicative rather than controlled A/B results.

| Long-run metric | 35B | 125B |
| --- | ---: | ---: |
| Completed main requests | 51 | 98 |
| Newly evaluated prompt tokens | 51,117 | 47,082 |
| Reported generated tokens | 17,835 | 21,026 |
| Weighted prefill (tok/s) | 214.55 | 77.68 |
| Weighted generation (tok/s) | 26.76 | 20.25 |
| MTP acceptance | 85.07% | 88.37% |
| Last completed occupied context | 68,917 | 67,142 |
| Outcome | Next prefill crashed | Session completed |

The 35B is substantially faster on short prompts (around 360 tok/s prefill and 30–37 tok/s generation in short tests). However, full-attention prefill slows with occupied context, and the long run had an unusually severe slowdown before crashing. The larger model sustained around 20 tok/s decoding throughout its long run. Approximately 98.9% of submitted prompt tokens were reused in that session, avoiding repeated full-context evaluation.

The larger model was also tested with main microbatch 256 and tighter fitting targets. These reduced compute allocation and allowed more fitted layers, but did not demonstrate a sufficiently consistent speed advantage to displace the 512/512 profile used in the successful extended run.
