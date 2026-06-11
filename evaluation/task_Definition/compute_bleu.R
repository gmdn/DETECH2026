library(dplyr)
library(purrr)
library(stringr)
#library(reticulate)

#reticulate::py_install("sacrebleu")
sacrebleu <- reticulate::import("sacrebleu")

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

compute_bleu_per_pair <- function(
    aligned_definitions,
    sacrebleu_module = sacrebleu
) {
  aligned_definitions |>
    dplyr::mutate(
      bleu_1 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) {
          metric <- sacrebleu_module$metrics$BLEU(
            max_ngram_order = 1L,
            effective_order = TRUE
          )
          metric$sentence_score(pred, list(gold))$score
        }
      ),
      bleu_2 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) {
          metric <- sacrebleu_module$metrics$BLEU(
            max_ngram_order = 2L,
            effective_order = TRUE
          )
          metric$sentence_score(pred, list(gold))$score
        }
      ),
      bleu_3 = purrr::map2_dbl(
        predicted_definition,
        gold_definition,
        \(pred, gold) {
          metric <- sacrebleu_module$metrics$BLEU(
            max_ngram_order = 3L,
            effective_order = TRUE
          )
          metric$sentence_score(pred, list(gold))$score
        }
      )
    )
}

compute_bleu_per_pair_all_runs <- function(task_b_runs, gold_task_b) {
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
      
      compute_bleu_per_pair(aligned) |>
        dplyr::mutate(
          team = team,
          subtask = subtask,
          run_id = run_id,
          .before = 1
        )
    }
  )
}

bleu_per_pair_all <- compute_bleu_per_pair_all_runs(
  task_b_runs = task_b_runs,
  gold_task_b = gold_task_b
)

print(bleu_per_pair_all)

bleu_summary_by_run <- bleu_per_pair_all |>
  dplyr::group_by(team, subtask, run_id) |>
  dplyr::summarise(
    n_pairs = dplyr::n(),
    mean_bleu_1 = mean(bleu_1, na.rm = TRUE),
    sd_bleu_1 = stats::sd(bleu_1, na.rm = TRUE),
    mean_bleu_2 = mean(bleu_2, na.rm = TRUE),
    sd_bleu_2 = stats::sd(bleu_2, na.rm = TRUE),
    mean_bleu_3 = mean(bleu_3, na.rm = TRUE),
    sd_bleu_3 = stats::sd(bleu_3, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    dplyr::across(
      starts_with("mean_") | starts_with("sd_"),
      ~ round(.x, 2)
    )
  )

print(bleu_summary_by_run)
