## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE  # Don't run in build
)

## -----------------------------------------------------------------------------
# library(starburst)
# 
# # Create a detached session (EC2 workers with Spot by default)
# session <- starburst_session(
#   workers = 10,
#   cpu = 4,
#   memory = "8GB"
# )
# 
# # Submit tasks
# task_ids <- lapply(1:100, function(i) {
#   session$submit(quote({
#     # Your long-running computation
#     result <- expensive_analysis(i)
#     result
#   }))
# })
# 
# # Save session ID for later
# session_id <- session$session_id
# print(session_id)  # "session-abc123..."

## -----------------------------------------------------------------------------
# # Check progress anytime
# status <- session$status()
# print(status)
# # Session Status:
# #   Total tasks:     100
# #   Pending:         25
# #   Running:         10
# #   Completed:       60
# #   Failed:          5
# #   Progress:        60.0%

## -----------------------------------------------------------------------------
# # Collect completed results (non-blocking)
# results <- session$collect(wait = FALSE)
# length(results)  # 60 (only completed so far)
# 
# # Or wait for all to complete
# results <- session$collect(wait = TRUE, timeout = 3600)
# length(results)  # 100 (all tasks)

## -----------------------------------------------------------------------------
# # Session 1: Start work
# session <- starburst_session(workers = 20)
# lapply(1:1000, function(i) session$submit(quote(slow_computation(i))))
# session_id <- session$session_id
# 
# # Close R, go home, come back tomorrow...
# 
# # Session 2: Reattach
# session <- starburst_session_attach(session_id)
# status <- session$status()
# results <- session$collect()

## -----------------------------------------------------------------------------
# sessions <- starburst_list_sessions()
# print(sessions)
# #   session_id         created_at           last_activity        total_tasks pending running completed failed
# #   session-abc123     2026-02-06 10:00:00  2026-02-06 10:15:00  100         0       5       90        5
# #   session-def456     2026-02-05 14:30:00  2026-02-05 18:45:00  500         0       0       500       0

## -----------------------------------------------------------------------------
# # Extend session timeout by 1 hour
# session$extend(seconds = 3600)

## -----------------------------------------------------------------------------
# # Stop workers and mark the session terminated. S3 objects are PRESERVED by
# # default, so you can still reattach and collect afterwards.
# session$cleanup()
# 
# # To also delete the session's S3 task/result objects, pass force = TRUE:
# session$cleanup(force = TRUE)

## -----------------------------------------------------------------------------
# # Default is already EC2 + Spot (c7g.xlarge); override the instance type if you like
# session <- starburst_session(
#   workers = 50,
#   instance_type = "c8a.xlarge",  # AMD 8th gen; auto-provisioned on first use
#   use_spot = TRUE                 # default TRUE — ~70% cheaper
# )
# 
# # Opt into the Fargate backend (serverless, task-based) instead
# session <- starburst_session(
#   workers = 50,
#   launch_type = "FARGATE"
# )

## -----------------------------------------------------------------------------
# # Tasks that fail are tracked, not silently dropped
# session <- starburst_session(workers = 5)
# 
# task_ids <- lapply(1:10, function(i) {
#   session$submit(quote({
#     if (i == 5) stop("Intentional error")
#     i * 2
#   }), globals = list(i = i))
# })
# 
# # Check status
# status <- session$status()
# print(status)   # Failed: 1
# 
# # collect() returns an entry for EVERY task, keyed by task id. A failed task
# # comes back as a structured failure (error = TRUE) alongside the successes.
# results <- session$collect(wait = TRUE)
# 
# # Separate successes from failures
# failures <- Filter(function(r) isTRUE(r$error), results)
# length(failures)                 # 1
# print(failures[[1]]$message)     # "Intentional error"
# 
# # Successful values are the non-error entries
# successes <- Filter(function(r) !isTRUE(r$error), results)

## -----------------------------------------------------------------------------
# session <- starburst_session(workers = 10)
# 
# # Submit mix of fast and slow tasks
# lapply(1:5, function(i) session$submit(quote(i * 2)))        # Fast
# lapply(1:5, function(i) session$submit(quote({ Sys.sleep(60); i })))  # Slow
# 
# Sys.sleep(10)
# 
# # Get fast results immediately
# results <- session$collect(wait = FALSE)
# length(results)  # 5 (fast tasks done)
# 
# # Later, get remaining results
# Sys.sleep(60)
# results <- session$collect(wait = FALSE)
# length(results)  # 10 (all done)

## -----------------------------------------------------------------------------
# # Start with fewer workers, let them process queue
# session <- starburst_session(workers = 5)
# 
# # Submit large batch
# lapply(1:1000, function(i) session$submit(quote(work(i))))
# 
# # Workers process tasks continuously until queue empty
# # Then auto-terminate after 5 min idle

## -----------------------------------------------------------------------------
# # Cost-effective setup
# session <- starburst_session(
#   workers = 20,
#   launch_type = "EC2",
#   instance_type = "c8a.xlarge",
#   use_spot = TRUE,
#   session_timeout = 3600,
#   absolute_timeout = 86400
# )

## -----------------------------------------------------------------------------
# # Error: Session not found: session-xyz
# # - Check session ID is correct
# # - Verify region matches (use region parameter)
# # - Session may have expired (check absolute_timeout)

## -----------------------------------------------------------------------------
# # Check session status
# status <- session$status()
# 
# # If pending tasks stuck:
# # - Workers may have terminated (check idle timeout)
# # - Launch more workers: (not yet implemented)
# # - Check CloudWatch logs: starburst_logs(session_id)

## -----------------------------------------------------------------------------
# # Workers exit after 5 min idle by default
# # For sporadic task submission, relaunch workers periodically
# # (Auto-scaling based on pending tasks coming in future release)

## -----------------------------------------------------------------------------
# library(starburst)
# 
# # Process 1000 samples overnight
# session <- starburst_session(
#   workers = 100,
#   cpu = 8,
#   memory = "32GB",
#   launch_type = "EC2",
#   use_spot = TRUE
# )
# 
# # Submit all samples
# sample_files <- list.files("samples/", pattern = "*.fastq")
# task_ids <- lapply(sample_files, function(file) {
#   session$submit(quote({
#     library(Rsubread)
#     results <- align_and_quantify(file)
#     save_results(results, file)
#     results
#   }))
# })
# 
# # Check progress next morning
# session <- starburst_session_attach(session$session_id)
# status <- session$status()
# # Completed: 950, Running: 45, Failed: 5
# 
# results <- session$collect(wait = TRUE)

## -----------------------------------------------------------------------------
# # Run 10,000 simulations
# session <- starburst_session(workers = 50)
# 
# n_sims <- 10000
# lapply(1:n_sims, function(i) {
#   session$submit(quote({
#     set.seed(i)
#     run_simulation()
#   }))
# })
# 
# # Check progress periodically
# repeat {
#   status <- session$status()
#   print(sprintf("Progress: %.1f%%", 100 * status$completed / status$total))
# 
#   if (status$completed == n_sims) break
#   Sys.sleep(60)
# }
# 
# results <- session$collect()

