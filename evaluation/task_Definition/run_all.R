source("load_data.R")

source("evaluate_concept_recall.R")

#source("prepare_evaluation_definition.R")

source("create_virtualenv.R")

library(reticulate)
reticulate::use_virtualenv("detech", required = TRUE)

#reticulate::py_install("sacrebleu")
source("compute_bleu.R")

#reticulate::py_install("rouge-score")
source("compute_rouge.R")

#reticulate::py_install(c("bert-score", "torch", "transformers"))
#reticulate::py_install(packages = c("sentencepiece", "tiktoken"))
source("compute_bertscore.R")

taskB_final_results <- concept_recall_summary_by_run |>
  dplyr::left_join(bleu_summary_by_run,
                   by = c("team", "subtask", "run_id")) |>
  dplyr::left_join(rouge_summary_by_run,
                   by = c("team", "subtask", "run_id", "n_pairs")) |>
  dplyr::left_join(bertscore_summary_by_run,
                   by = c("team", "subtask", "run_id", "n_pairs"))


taskB_final_results <- taskB_final_results |>
  dplyr::select(
    team,
    subtask,
    run_id,
    n_pairs,
    
    # RECALL
    concept_recall,
    
    # BLEU
    mean_bleu_1,
    mean_bleu_2,
    mean_bleu_3,
    
    # ROUGE (focus on F1)
    mean_rouge1_f1,
    mean_rouge2_f1,
    mean_rougeL_f1,
    
    # BERTScore
    bert_f1
  )

taskB_final_results <- taskB_final_results |>
  dplyr::mutate(
    dplyr::across(
      where(is.numeric),
      ~ round(.x, 3)
    )
  )

print(taskB_final_results)

# create_median_row_task_b <- function(results_table) {
#   median_row <- results_table[1, ] |>
#     dplyr::slice(1) |>
#     dplyr::mutate(dplyr::across(dplyr::everything(), ~ NA))
#   
#   numeric_cols <- results_table |>
#     dplyr::select(where(is.numeric)) |>
#     names()
#   
#   median_values <- results_table |>
#     dplyr::summarise(
#       dplyr::across(
#         dplyr::all_of(numeric_cols),
#         ~ stats::median(.x, na.rm = TRUE)
#       )
#     )
#   
#   for (col_name in numeric_cols) {
#     median_row[[col_name]] <- median_values[[col_name]]
#   }
#   
#   median_row$team <- "median"
#   
#   median_row
# }

create_summary_row_task_b <- function(results_table, label, summary_fun) {
  summary_row <- results_table[1, ] |>
    dplyr::slice(1) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), ~ NA))
  
  numeric_cols <- results_table |>
    dplyr::select(where(is.numeric)) |>
    names()
  
  summary_values <- results_table |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(numeric_cols),
        ~ summary_fun(.x)
      )
    )
  
  for (col_name in numeric_cols) {
    summary_row[[col_name]] <- summary_values[[col_name]]
  }
  
  summary_row$team <- label
  
  summary_row
}

create_benchmark_rows_task_b <- function(results_table) {
  dplyr::bind_rows(
    create_summary_row_task_b(
      results_table,
      label = "q1",
      summary_fun = \(x) stats::quantile(x, probs = 0.25, na.rm = TRUE)
    ),
    create_summary_row_task_b(
      results_table,
      label = "median",
      summary_fun = \(x) stats::median(x, na.rm = TRUE)
    ),
    create_summary_row_task_b(
      results_table,
      label = "q3",
      summary_fun = \(x) stats::quantile(x, probs = 0.75, na.rm = TRUE)
    )
  )
}


export_team_results_task_b <- function(results_table, output_dir, subtask_name) {
  fs::dir_create(output_dir)
  
  #median_row <- create_median_row_task_b(results_table)
  benchmark_rows <- create_benchmark_rows_task_b(results_table)
  
  team_results <- results_table |>
    dplyr::group_by(team) |>
    dplyr::group_split()
  
  purrr::walk(
    team_results,
    function(team_data) {
      team_name <- unique(team_data$team)
      
      #output_data <- dplyr::bind_rows(team_data, median_row)
      output_data <- dplyr::bind_rows(team_data, benchmark_rows)
      
      output_file <- fs::path(
        output_dir,
        paste0("TaskB-", subtask_name, "-taskB-results-", team_name, ".csv")
      )
      
      readr::write_csv(output_data, output_file)
    }
  )
  
  invisible(NULL)
}

taskB_results_mental_health <- taskB_final_results |>
  dplyr::filter(subtask == "mental_health")

taskB_results_parkinson <- taskB_final_results |>
  dplyr::filter(subtask == "parkinson")


export_team_results_task_b(
  results_table = taskB_results_mental_health,
  output_dir = "team-feedback/mental_health",
  subtask_name = "mental_health"
)

export_team_results_task_b(
  results_table = taskB_results_parkinson,
  output_dir = "team-feedback/parkinson",
  subtask_name = "parkinson"
)
