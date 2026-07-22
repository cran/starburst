## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(eval = FALSE)

## ----batching-bad-------------------------------------------------------------
# # Bad: 10,000 tasks of 0.1s each — overhead dominates
# starburst_map(1:10000, quick_fn, workers = 100)

## ----batching-good------------------------------------------------------------
# # Good: 100 tasks of 100s each — overhead is negligible
# batches <- split(1:10000, ceiling(seq_along(1:10000) / 100))
# starburst_map(batches, function(batch) lapply(batch, quick_fn), workers = 100)

## ----batch-size---------------------------------------------------------------
# # Profile your function first
# per_item_time <- 0.5   # seconds, from local profiling
# target_task_duration <- 60  # aim for 60s minimum per task
# 
# batch_size <- ceiling(target_task_duration / per_item_time)
# # Result: 120 items per batch

## ----instance-choice----------------------------------------------------------
# # Recommended alternative: c8a with spot instances (auto-provisioned on first use)
# plan(starburst,
#   workers     = 50,
#   instance_type = "c8a.xlarge",  # AMD 8th gen — best price/performance
#   use_spot    = TRUE             # 70% cheaper than on-demand
# )

## ----one-shot-local-----------------------------------------------------------
# library(parallel)
# cl <- makeCluster(detectCores() - 1)
# results <- parLapply(cl, data, your_function)
# stopCluster(cl)

## ----param-sweep--------------------------------------------------------------
# # Pay startup cost once, run many combinations
# for (alpha in seq(0.1, 1.0, 0.1)) {
#   for (beta in seq(0.1, 1.0, 0.1)) {
#     results <- starburst_map(
#       data,
#       function(x) model(x, alpha = alpha, beta = beta),
#       workers = 50
#     )
#   }
# }

## ----warm-pool----------------------------------------------------------------
# # Start warm pool once in the morning
# plan(starburst, workers = 50, warm_pool_timeout = 28800)  # 8 hours
# 
# # All runs during the day start in < 30s
# results_am <- starburst_map(morning_data, process)
# results_pm <- starburst_map(afternoon_data, process)
# # Pool shuts down automatically after 8 hours of inactivity

## ----hybrid-------------------------------------------------------------------
# # Iterate quickly on a small sample locally
# results_test <- lapply(data[1:100], your_function)
# 
# # When logic is right, scale to full dataset on cloud
# results_full <- starburst_map(data, your_function, workers = 100)

## ----pitfall-small------------------------------------------------------------
# # Bad: each task is 0.1s — overhead is 20-30x the work
# starburst_map(1:10000, function(x) sqrt(x), workers = 100)
# 
# # Good: batch into groups of 100
# batches <- split(1:10000, ceiling(seq_along(1:10000) / 100))
# starburst_map(batches, function(b) sapply(b, sqrt), workers = 100)

## ----pitfall-workers----------------------------------------------------------
# # Bad: 40 workers sit idle
# starburst_map(1:10, fn, workers = 50)
# 
# # Good: match workers to workload
# starburst_map(1:100, fn, workers = 25)  # 4 tasks per worker

## ----pitfall-data-------------------------------------------------------------
# # Bad: huge_matrix serialized and sent to each of 50 workers
# huge_matrix <- matrix(rnorm(1e8), ncol = 1000)
# starburst_map(1:50, function(i) process(huge_matrix, i), workers = 50)
# 
# # Good: generate data inside the worker
# starburst_map(1:50, function(i) {
#   data <- generate_chunk(i)  # create data on the worker
#   process(data)
# }, workers = 50)

