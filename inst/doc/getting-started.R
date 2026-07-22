## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# # Install from GitHub
# remotes::install_github("scttfrdmn/starburst")

## -----------------------------------------------------------------------------
# library(starburst)
# 
# # Interactive setup wizard
# starburst_setup()

## -----------------------------------------------------------------------------
# library(starburst)
# 
# # Define your work
# expensive_simulation <- function(i) {
#   # Some computation that takes a few minutes
#   results <- replicate(1000, {
#     x <- rnorm(10000)
#     mean(x^2)
#   })
#   mean(results)
# }
# 
# # Run across 50 cloud workers (EC2 by default)
# results <- starburst_map(1:100, expensive_simulation, workers = 50)
# #> [Starting] Starting starburst cluster with 50 workers
# #> [Status] Processing 100 items with 50 workers
# #> [Starting] Submitting 100 tasks...
# #> [Wait] Progress: 100/100 (128.0s)
# #> [OK] Completed in 128.0 seconds
# #> [Cost] Estimated cost: $0.85

## -----------------------------------------------------------------------------
# library(furrr)
# library(starburst)
# 
# # Local baseline
# plan(sequential)
# results_local <- future_map(1:100, expensive_simulation)
# 
# # Same code, now on 50 cloud workers — just change the plan
# plan(starburst, workers = 50)
# results_cloud <- future_map(1:100, expensive_simulation)
# 
# # Results are identical to the local run
# identical(results_local, results_cloud)
# #> [1] TRUE

## -----------------------------------------------------------------------------
# # Direct API
# results <- starburst_map(1:100, expensive_simulation, workers = 50)
# 
# # future / furrr
# plan(starburst, workers = 50)
# results <- future_map(1:100, expensive_simulation)

## -----------------------------------------------------------------------------
# # Download an s3://bucket/key object to a temp file and read it on the worker.
# read_s3 <- function(s3_uri, reader = readRDS) {
#   m <- regmatches(s3_uri, regexec("^s3://([^/]+)/(.+)$", s3_uri))[[1]]
#   bucket <- m[2]; key <- m[3]
#   tmp <- tempfile()
#   obj <- paws.storage::s3()$get_object(Bucket = bucket, Key = key)
#   writeBin(obj$Body, tmp)
#   reader(tmp)
# }

## -----------------------------------------------------------------------------
# plan(starburst, workers = 50)
# 
# results <- future_map(file_list, function(file) {
#   # Each worker pulls its file from S3 (read_s3 defined above)
#   data <- read_s3(sprintf("s3://my-bucket/%s", file), reader = read.csv)
#   process(data)
# })

## -----------------------------------------------------------------------------
# # Load data locally
# data <- read.csv("local_file.csv")
# 
# # staRburst automatically uploads to S3 and distributes
# plan(starburst, workers = 50)
# 
# # `replicates` is your vector of inputs (e.g. bootstrap replicate ids)
# results <- future_map(replicates, function(i) {
#   # Each worker gets a copy of 'data'
#   bootstrap_analysis(data, i)
# })

## -----------------------------------------------------------------------------
# # Upload once from your machine
# paws.storage::s3()$put_object(
#   Bucket = "my-bucket", Key = "large_data.rds",
#   Body = "huge_file.rds"
# )
# s3_path <- "s3://my-bucket/large_data.rds"
# 
# # Workers read from S3 inside the task (read_s3 helper defined above)
# plan(starburst, workers = 100)
# 
# # `tasks` is your vector of work items
# results <- future_map(tasks, function(i) {
#   data <- read_s3(s3_path)   # readRDS by default
#   process(data, i)
# })

## -----------------------------------------------------------------------------
# # Check cost before running
# plan(starburst, workers = 100, cpu = 4, memory = "8GB")
# #> Estimated cost: ~$3.50/hour

## -----------------------------------------------------------------------------
# # Set an hourly cost ceiling (USD/hour) — jobs above this rate won't start
# starburst_config(
#   max_hourly_cost = 10,       # Don't start jobs estimated over $10/hour
#   cost_alert_threshold = 5     # Warn at $5/hour
# )
# 
# # Now jobs exceeding limit will error before starting
# plan(starburst, workers = 1000)  # Would cost ~$35/hour
# #> Error: Estimated cost ($35/hr) exceeds limit ($10/hr)

## -----------------------------------------------------------------------------
# plan(starburst, workers = 50)
# 
# results <- future_map(data, process)
# 
# #> Cluster runtime: ~23 minutes
# #> Estimated cost: ~$1.34

## -----------------------------------------------------------------------------
# starburst_quota_status()
# #> Fargate vCPU Quota: 100 / 100 used
# #> Allows: ~25 workers with 4 vCPUs each
# #>
# #> Recommended: Request increase to 500 vCPUs

## -----------------------------------------------------------------------------
# starburst_request_quota_increase(vcpus = 500)
# #> Requesting Fargate vCPU quota increase:
# #>   Current: 100 vCPUs
# #>   Requested: 500 vCPUs
# #>
# #> [OK] Quota increase requested (Case ID: 12345678)
# #> [OK] AWS typically approves within 1-24 hours

## -----------------------------------------------------------------------------
# # Quota allows 25 workers, but you request 100
# plan(starburst, workers = 100, cpu = 4)
# 
# #> [!] Requested: 100 workers (400 vCPUs)
# #> [!] Current quota: 100 vCPUs (allows 25 workers max)
# #>
# #> [Plan] Execution plan:
# #>   - Running in 4 waves of 25 workers each
# #>
# #> [TIP] Request quota increase to 500 vCPUs? [y/n]: y
# #>
# #> [OK] Quota increase requested
# #> [Starting] Starting wave 1 (25 workers)...
# 
# results <- future_map(inputs, expensive_function)
# 
# #> [Wave] Wave 1: 100% complete (250 tasks)
# #> [Wave] Wave 2: 100% complete (500 tasks)
# #> [Wave] Wave 3: 100% complete (750 tasks)
# #> [Wave] Wave 4: 100% complete (1000 tasks)

## -----------------------------------------------------------------------------
# # View logs from most recent cluster
# starburst_logs()
# 
# # View logs from specific task
# starburst_logs(task_id = "abc-123")
# 
# # View last 100 log lines
# starburst_logs(last_n = 100)

## -----------------------------------------------------------------------------
# starburst_status()
# #> Active Clusters:
# #>   • starburst-xyz123: 50 workers running
# #>   • starburst-abc456: 25 workers running

## -----------------------------------------------------------------------------
# # Rebuild environment
# starburst_rebuild_environment()

## -----------------------------------------------------------------------------
# # Check logs
# starburst_logs(task_id = "failed-task-id")
# 
# # Often due to memory limits - increase worker memory
# plan(starburst, workers = 50, memory = "16GB")  # Default is 8GB

## -----------------------------------------------------------------------------
# # Use Arrow for data frames
# library(arrow)
# write_parquet(my_data, "s3://bucket/data.parquet")
# 
# # Workers read Arrow
# results <- future_map(1:100, function(i) {
#   data <- read_parquet("s3://bucket/data.parquet")
#   process(data, i)
# })

## -----------------------------------------------------------------------------
# # 100 tasks, each takes 10 minutes
# # Local: 1000 minutes, Cloud: ~10 minutes

## -----------------------------------------------------------------------------
# # 10000 tasks, each takes 30 seconds
# # Startup overhead (45s) dominates

## -----------------------------------------------------------------------------
# # 10,000 tiny tasks
# results <- future_map(1:10000, small_function)

## -----------------------------------------------------------------------------
# # 100 batches of 100 tasks each
# batches <- split(1:10000, ceiling(seq_along(1:10000) / 100))
# 
# results <- future_map(batches, function(batch) {
#   lapply(batch, small_function)
# })
# 
# # Flatten results
# results <- unlist(results, recursive = FALSE)

## -----------------------------------------------------------------------------
# big_data <- read.csv("10GB_file.csv")  # Upload for every task
# results <- future_map(1:1000, function(i) process(big_data, i))

## -----------------------------------------------------------------------------
# # Upload once to S3
# tmp <- tempfile(fileext = ".csv"); write.csv(big_data, tmp, row.names = FALSE)
# paws.storage::s3()$put_object(Bucket = "bucket", Key = "big_data.csv", Body = tmp)
# 
# # Workers read from S3 (read_s3 helper from "Working with Data" above)
# results <- future_map(tasks, function(i) {
#   data <- read_s3("s3://bucket/big_data.csv", reader = read.csv)
#   process(data, i)
# })

## -----------------------------------------------------------------------------
# starburst_config(
#   max_hourly_cost = 50,            # Cap the hourly rate (USD/hour)
#   cost_alert_threshold = 25        # Get warned early
# )

## -----------------------------------------------------------------------------
# # staRburst auto-cleans, but you can force it
# plan(sequential)  # Switch back to local
# # Old cluster resources are cleaned up automatically

## -----------------------------------------------------------------------------
# # High CPU, low memory (CPU-bound work)
# plan(starburst, workers = 50, cpu = 8, memory = "16GB")
# 
# # Low CPU, high memory (memory-bound work)
# plan(starburst, workers = 25, cpu = 4, memory = "32GB")

## -----------------------------------------------------------------------------
# # Increase timeout for long-running tasks (default 1 hour)
# plan(starburst, workers = 10, timeout = 7200)  # 2 hours

## -----------------------------------------------------------------------------
# # Use specific region (default from config)
# plan(starburst, workers = 50, region = "us-west-2")

