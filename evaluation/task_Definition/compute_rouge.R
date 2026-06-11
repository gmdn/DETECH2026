library(dplyr)
library(purrr)
library(stringr)
#library(reticulate)

#reticulate::py_install("rouge-score")
rouge_score <- reticulate::import("rouge_score")

# Assumes normalize_concept() already exists from evaluate_concept_recall.R

prepare_run_definitions <- function(run_data) {
  run_data |>
    dplyr::transmute(
      num_article = as.character(num_article),
      concept = as.character(concept),
      concept_norm = normalize_concept(concept),
      predicted_definition = stringr::str_squish(
        as.character(predicted_definition)
      )
    ) |>
    dplyr::filter(
      !is.na(num_article),
      num_article != "",
      !is.na(concept_norm),
      concept_norm != "",
      !is.na(predicted_definition),
      predicted_definition != ""
    ) |>
    dplyr::distinct(num_article, concept_norm, .keep_all = TRUE)
}

prepare_gold_definitions <- function(gold_data) {
  gold_data |>
    dplyr::transmute(
      num_article = as.character(num_article),
      concept = as.character(concept),
      concept_norm = normalize_concept(concept),
      gold_definition = stringr::str_squish(
        as.character(gold_definition)
      )
    ) |>
    dplyr::filter(
      !is.na(num_article),
      num_article != "",
      !is.na(concept_norm),
      concept_norm != "",
      !is.na(gold_definition),
      gold_definition != ""
    ) |>
    dplyr::distinct(num_article, concept_norm, .keep_all = TRUE)
}

align_definitions_true_positives <- function(run_data, gold_data) {
  run_definitions <- prepare_run_definitions(run_data)
  gold_definitions <- prepare_gold_definitions(gold_data)
  
  dplyr::inner_join(
    run_definitions,
    gold_definitions,
    by = c("num_article", "concept_norm"),
    suffix = c("_run", "_gold")
  ) |>
    dplyr::transmute(
      num_article,
      concept_norm,
      concept_run = concept_run,
      concept_gold = concept_gold,
      predicted_definition,
      gold_definition,
      status = "matched"
    )
}

compute_rouge_per_pair <- function(
    aligned_definitions,
    rouge_score_module = rouge_score
) {
  scorer <- rouge_score_module$rouge_scorer$RougeScorer(
    rouge_types = list("rouge1", "rouge2", "rougeL"),
    use_stemmer = FALSE
  )
  
  aligned_definitions |>
    dplyr::mutate(
      rouge1_precision = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge1"]]$precision
      ),
      rouge1_recall = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge1"]]$recall
      ),
      rouge1_f1 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge1"]]$fmeasure
      ),
      rouge2_precision = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge2"]]$precision
      ),
      rouge2_recall = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge2"]]$recall
      ),
      rouge2_f1 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rouge2"]]$fmeasure
      ),
      rougeL_precision = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rougeL"]]$precision
      ),
      rougeL_recall = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rougeL"]]$recall
      ),
      rougeL_f1 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) scorer$score(gold, pred)[["rougeL"]]$fmeasure
      )
    )
}

compute_rouge_per_pair_all_runs <- function(
    task_b_runs,
    gold_task_b,
    rouge_score_module = rouge_score
) {
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
      
      gold_data <- gold_task_b |>
        dplyr::filter(subtask == !!subtask)
      
      aligned <- align_definitions_true_positives(run_data, gold_data)
      
      compute_rouge_per_pair(
        aligned_definitions = aligned,
        rouge_score_module = rouge_score_module
      ) |>
        dplyr::mutate(
          team = team,
          subtask = subtask,
          run_id = run_id,
          .before = 1
        )
    }
  )
}

rouge_per_pair_all <- compute_rouge_per_pair_all_runs(
  task_b_runs = task_b_runs,
  gold_task_b = gold_task_b
)

rouge_summary_by_run <- rouge_per_pair_all |>
  dplyr::group_by(team, subtask, run_id) |>
  dplyr::summarise(
    n_pairs = dplyr::n(),
    
    mean_rouge1_precision = mean(rouge1_precision, na.rm = TRUE),
    sd_rouge1_precision = stats::sd(rouge1_precision, na.rm = TRUE),
    mean_rouge1_recall = mean(rouge1_recall, na.rm = TRUE),
    sd_rouge1_recall = stats::sd(rouge1_recall, na.rm = TRUE),
    mean_rouge1_f1 = mean(rouge1_f1, na.rm = TRUE),
    sd_rouge1_f1 = stats::sd(rouge1_f1, na.rm = TRUE),
    
    mean_rouge2_precision = mean(rouge2_precision, na.rm = TRUE),
    sd_rouge2_precision = stats::sd(rouge2_precision, na.rm = TRUE),
    mean_rouge2_recall = mean(rouge2_recall, na.rm = TRUE),
    sd_rouge2_recall = stats::sd(rouge2_recall, na.rm = TRUE),
    mean_rouge2_f1 = mean(rouge2_f1, na.rm = TRUE),
    sd_rouge2_f1 = stats::sd(rouge2_f1, na.rm = TRUE),
    
    mean_rougeL_precision = mean(rougeL_precision, na.rm = TRUE),
    sd_rougeL_precision = stats::sd(rougeL_precision, na.rm = TRUE),
    mean_rougeL_recall = mean(rougeL_recall, na.rm = TRUE),
    sd_rougeL_recall = stats::sd(rougeL_recall, na.rm = TRUE),
    mean_rougeL_f1 = mean(rougeL_f1, na.rm = TRUE),
    sd_rougeL_f1 = stats::sd(rougeL_f1, na.rm = TRUE),
    
    .groups = "drop"
  )

print(rouge_summary_by_run)
