source("measures.R")

gold_task_a_mental_health <- task_a_mental_health_terms_test
gold_task_a_parkinson <- task_a_parkinson_terms_test

task_a_runs_mental_health <- task_a_runs %>% filter(str_detect(file_name, pattern = "mental"))
task_a_runs_parkinson <- task_a_runs %>% filter(str_detect(file_name, pattern = "parkinson"))


# # example with one run
# one_run <- task_a_runs |>
#   dplyr::filter(team == "GRIAL-ATE", file_name == "taskA_mental_health_predictions_detech.csv")
# 
# evaluate_task_a_run(one_run, gold_task_a_mental_health)

results_mental_health <- evaluate_all_task_a_runs(task_a_runs_mental_health, gold_task_a_mental_health)
results_parkinson <- evaluate_all_task_a_runs(task_a_runs_parkinson, gold_task_a_parkinson)
