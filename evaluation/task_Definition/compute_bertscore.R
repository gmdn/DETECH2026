library(dplyr)
library(purrr)
library(stringr)
#library(reticulate)

#reticulate::py_install(c("bert-score", "torch", "transformers"))
#reticulate::py_install(packages = c("sentencepiece", "tiktoken"))

bert_score <- reticulate::import("bert_score")

#biobert_model <- "dmis-lab/biobert-base-cased-v1.2"
#biobert_model <- "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext"
biobert_model <- "models/pubmedbert-fixed"

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

compute_bertscore_per_pair <- function(
    aligned_definitions,
    bert_score_module = bert_score,
    model_type = biobert_model,
    num_layers = 12L,
    device = "cpu"
) {
  if (nrow(aligned_definitions) == 0) {
    return(
      aligned_definitions |>
        dplyr::mutate(
          bert_precision = numeric(),
          bert_recall = numeric(),
          bert_f1 = numeric()
        )
    )
  }
  
  predictions <- as.list(aligned_definitions$predicted_definition)
  references <- as.list(aligned_definitions$gold_definition)
  
  scores <- bert_score_module$score(
    cands = predictions,
    refs = references,
    model_type = model_type,
    num_layers = as.integer(num_layers),
    verbose = FALSE,
    rescale_with_baseline = FALSE,
    device = device,
    use_fast_tokenizer = FALSE
  )
  
  aligned_definitions |>
    dplyr::mutate(
      bert_precision = as.numeric(scores[[1]]$cpu()$numpy()),
      bert_recall = as.numeric(scores[[2]]$cpu()$numpy()),
      bert_f1 = as.numeric(scores[[3]]$cpu()$numpy())
    )
}

compute_bertscore_per_pair_all_runs <- function(
    task_b_runs,
    gold_task_b,
    bert_score_module = bert_score,
    model_type = biobert_model,
    num_layers = 12L,
    device = "cpu"
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
      
      compute_bertscore_per_pair(
        aligned_definitions = aligned,
        bert_score_module = bert_score_module,
        model_type = model_type,
        num_layers = num_layers,
        device = device
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

bertscore_per_pair_all <- compute_bertscore_per_pair_all_runs(
  task_b_runs = task_b_runs,
  gold_task_b = gold_task_b,
  model_type = biobert_model,
  num_layers = 12L,
  device = "cpu"
)

bertscore_summary_by_run <- bertscore_per_pair_all |>
  dplyr::group_by(team, subtask, run_id) |>
  dplyr::summarise(
    n_pairs = dplyr::n(),
    mean_bert_precision = mean(bert_precision, na.rm = TRUE),
    sd_bert_precision = stats::sd(bert_precision, na.rm = TRUE),
    mean_bert_recall = mean(bert_recall, na.rm = TRUE),
    sd_bert_recall = stats::sd(bert_recall, na.rm = TRUE),
    mean_bert_f1 = mean(bert_f1, na.rm = TRUE),
    sd_bert_f1 = stats::sd(bert_f1, na.rm = TRUE),
    .groups = "drop"
  )

print(bertscore_summary_by_run)

compute_bertscore_all_runs <- function(
    task_b_runs,
    gold_task_b,
    bert_score_module = bert_score,
    model_type = biobert_model,
    num_layers = 12L,
    device = "cpu"
) {
  bertscore_per_pair_all <- compute_bertscore_per_pair_all_runs(
    task_b_runs = task_b_runs,
    gold_task_b = gold_task_b,
    bert_score_module = bert_score_module,
    model_type = model_type,
    num_layers = num_layers,
    device = device
  )
  
  bertscore_per_pair_all |>
    dplyr::group_by(team, subtask, run_id) |>
    dplyr::summarise(
      n_pairs = dplyr::n(),
      bert_precision = mean(bert_precision, na.rm = TRUE),
      bert_recall = mean(bert_recall, na.rm = TRUE),
      bert_f1 = mean(bert_f1, na.rm = TRUE),
      .groups = "drop"
    )
}

bertscore_summary_by_run <- compute_bertscore_all_runs(
  task_b_runs = task_b_runs,
  gold_task_b = gold_task_b,
  model_type = biobert_model,
  num_layers = 12L,
  device = "cpu"
)

print(bertscore_summary_by_run)
