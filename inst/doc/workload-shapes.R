## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(eval = FALSE)

## -----------------------------------------------------------------------------
# # Heavy tasks (minutes each) — the cloud wins
# results <- starburst_map(scenarios, run_expensive_model, workers = 30)
# 
# # Trivially cheap tasks — just do it locally
# results <- lapply(inputs, quick_function)

## -----------------------------------------------------------------------------
# # ❌ DON'T: 10,000 tasks — ~10,000 serial S3 submits from your laptop
# results <- starburst_map(1:10000, evaluate_point, workers = 50)
# 
# # ✅ DO: batch into ~100 chunks — 100 tasks, same 10,000 evaluations
# batches <- split(1:10000, ceiling(seq_along(1:10000) / 100))
# results <- starburst_map(batches, function(ids) lapply(ids, evaluate_point),
#                          workers = 50)
# results <- unlist(results, recursive = FALSE)  # flatten

## -----------------------------------------------------------------------------
# per_item_seconds <- 0.5              # measure this on a small local sample
# target_task_seconds <- 120           # aim for ~2 min per task
# batch_size <- ceiling(target_task_seconds / per_item_seconds)  # ~240 here

## -----------------------------------------------------------------------------
# # 200 tasks: ~50 workers is a reasonable ratio (each worker handles ~4 tasks)
# results <- starburst_map(param_sets, fit_model, workers = 50)
# 
# # 200 tasks on 500 workers: 300 workers idle, you pay for all 500 — don't

## -----------------------------------------------------------------------------
# # Cheapest for a one-off: enough workers to cover the tasks, spot on (default)
# starburst_map(tasks, fn, workers = length(tasks), use_spot = TRUE)
# 
# # Repeated runs: a warm pool pays startup once — see the detached-sessions guide

## -----------------------------------------------------------------------------
# # ❌ Hundreds of tasks writing under ONE prefix — throughput bottleneck
# key <- sprintf("s3://bucket/results/%d.parquet", i)
# 
# # ✅ Shard across prefixes so S3 parallelizes the writes
# shard <- i %% 100
# key <- sprintf("s3://bucket/results/shard=%02d/%d.parquet", shard, i)

