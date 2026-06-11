normalize_term <- function(x) {
  x |>
    stringr::str_squish() |>
    stringr::str_to_lower()
}

prepare_task_a_data <- function(data) {
  data |>
    dplyr::transmute(
      num_article = as.character(num_article),
      term = stringr::str_squish(as.character(term)),
      term_norm = normalize_term(term)
    )
  # |>
  #   dplyr::filter(
  #     !is.na(num_article),
  #     num_article != "",
  #     !is.na(term),
  #     term != ""
  #   )
}

# compute_precision_recall <- function(tp, fp, fn) {
#   
#   precision <- if ((tp + fp) > 0) tp / (tp + fp) else 0
#   recall <- if ((tp + fn) > 0) tp / (tp + fn) else 0
#   
#   tibble::tibble(
#     tp = tp,
#     fp = fp,
#     fn = fn,
#     precision = precision,
#     recall = recall
#   )
# }

compute_precision_recall <- function(tp, fp, fn) {
  
  precision <- ifelse(tp + fp > 0, tp / (tp + fp), 0)
  recall <- ifelse(tp + fn > 0, tp / (tp + fn), 0)
  
  f1 <- ifelse(
    precision + recall > 0,
    2 * precision * recall / (precision + recall),
    0
  )
  
  tibble::tibble(
    tp = tp,
    fp = fp,
    fn = fn,
    precision = precision,
    recall = recall,
    f1 = f1
  )
}

evaluate_task_a_micro <- function(run_data, gold_data) {
  run_counts <- run_data |>
    dplyr::count(num_article, term_norm, name = "run_n")
  
  gold_counts <- gold_data |>
    dplyr::count(num_article, term_norm, name = "gold_n")
  
  comparison <- dplyr::full_join(
    run_counts,
    gold_counts,
    by = c("num_article", "term_norm")
  ) |>
    dplyr::mutate(
      run_n = dplyr::coalesce(run_n, 0L),
      gold_n = dplyr::coalesce(gold_n, 0L),
      tp = pmin(run_n, gold_n),
      fp = pmax(run_n - gold_n, 0L),
      fn = pmax(gold_n - run_n, 0L)
    )
  
  tp <- sum(comparison$tp)
  fp <- sum(comparison$fp)
  fn <- sum(comparison$fn)
  
  compute_precision_recall(tp, fp, fn) |>
    dplyr::rename(
      micro_tp = tp,
      micro_fp = fp,
      micro_fn = fn,
      micro_precision = precision,
      micro_recall = recall,
      micro_f1 = f1
    )
}

evaluate_task_a_type <- function(run_data, gold_data) {
  run_types <- run_data |>
    dplyr::distinct(num_article, term_norm)
  
  gold_types <- gold_data |>
    dplyr::distinct(num_article, term_norm)
  
  tp <- dplyr::inner_join(
    run_types,
    gold_types,
    by = c("num_article", "term_norm")
  ) |>
    nrow()
  
  fp <- dplyr::anti_join(
    run_types,
    gold_types,
    by = c("num_article", "term_norm")
  ) |>
    nrow()
  
  fn <- dplyr::anti_join(
    gold_types,
    run_types,
    by = c("num_article", "term_norm")
  ) |>
    nrow()
  
  compute_precision_recall(tp, fp, fn) |>
    dplyr::rename(
      type_tp = tp,
      type_fp = fp,
      type_fn = fn,
      type_precision = precision,
      type_recall = recall,
      type_f1 = f1
    )
}

evaluate_task_a_run <- function(run_data, gold_data) {
  run_prepared <- prepare_task_a_data(run_data)
  gold_prepared <- prepare_task_a_data(gold_data)
  
  micro_results <- evaluate_task_a_micro(run_prepared, gold_prepared)
  type_results <- evaluate_task_a_type(run_prepared, gold_prepared)
  
  dplyr::bind_cols(micro_results, type_results)
}

evaluate_all_task_a_runs <- function(task_a_runs, gold_data) {
  run_keys <- task_a_runs |>
    dplyr::distinct(team, file_name)
  
  purrr::pmap_dfr(
    run_keys,
    function(team, file_name) {
      run_data <- task_a_runs |>
        dplyr::filter(team == !!team, file_name == !!file_name)
      
      metrics <- evaluate_task_a_run(
        run_data = run_data,
        gold_data = gold_data
      )
      
      tibble::tibble(
        team = team,
        file_name = file_name
      ) |>
        dplyr::bind_cols(metrics)
    }
  )
}
