# Normalize concept -------------------------------------------------------

normalize_concept <- function(x) {
  x |>
    stringr::str_remove_all("[<>]") |>
    stringr::str_squish() |>
    stringr::str_to_lower()
}

prepare_task_b_concepts <- function(data) {
  data |>
    dplyr::transmute(
      num_article = as.character(num_article),
      concept = as.character(concept),
      concept_norm = normalize_concept(concept)
    ) |>
    dplyr::filter(
      !is.na(num_article),
      num_article != "",
      !is.na(concept_norm),
      concept_norm != ""
    )
}

evaluate_concept_recall <- function(run_data, gold_data) {
  run_prepared <- prepare_task_b_concepts(run_data)
  gold_prepared <- prepare_task_b_concepts(gold_data)
  
  run_concepts <- run_prepared |>
    dplyr::distinct(num_article, concept_norm)
  
  gold_concepts <- gold_prepared |>
    dplyr::distinct(num_article, concept_norm)
  
  # True positives: concepts found in both
  tp <- dplyr::inner_join(
    run_concepts,
    gold_concepts,
    by = c("num_article", "concept_norm")
  ) |>
    nrow()
  
  # False negatives: gold concepts not found
  fn <- dplyr::anti_join(
    gold_concepts,
    run_concepts,
    by = c("num_article", "concept_norm")
  ) |>
    nrow()
  
  recall <- if ((tp + fn) > 0) tp / (tp + fn) else 0
  
  tibble::tibble(
    concept_tp = tp,
    concept_fn = fn,
    concept_recall = recall
  )
}

evaluate_all_concept_recall <- function(task_b_runs, gold_data) {
  run_keys <- task_b_runs |>
    dplyr::distinct(team, subtask, run_id)
  
  purrr::pmap_dfr(
    run_keys,
    function(team, subtask, run_id) {
      run_data <- task_b_runs |>
        dplyr::filter(
          team == !!team,
          subtask == !!subtask,
          run_id == !!run_id
        )
      
      # Match correct gold
      gold_subset <- gold_data |>
        dplyr::filter(subtask == !!subtask)
      
      metrics <- evaluate_concept_recall(
        run_data = run_data,
        gold_data = gold_subset
      )
      
      tibble::tibble(
        team = team,
        subtask = subtask,
        run_id = run_id
      ) |>
        dplyr::bind_cols(metrics)
    }
  )
}

# build gold with subtasks
gold_task_b <- dplyr::bind_rows(
  gold_task_b_mental_health |>
    dplyr::mutate(subtask = "mental_health"),
  gold_task_b_parkinson |>
    dplyr::mutate(subtask = "parkinson")
)


concept_recall_summary_by_run <- evaluate_all_concept_recall(task_b_runs, gold_task_b)

