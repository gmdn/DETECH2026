library(tidyverse)

####### Helpers

detect_delimiter <- function(file_path) {
  first_lines <- readr::read_lines(file_path, n_max = 1)
  
  comma_count <- stringr::str_count(first_lines, ",") |> sum()
  semicolon_count <- stringr::str_count(first_lines, ";") |> sum()
  
  if (semicolon_count > comma_count) {
    return(";")
  }
  
  ","
}

read_delim_with_optional_header <- function(file_path, required_cols) {
  delim <- detect_delimiter(file_path)
  
  raw_data <- readr::read_delim(
    file = file_path,
    delim = delim,
    col_names = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    trim_ws = TRUE,
    show_col_types = FALSE,
    progress = FALSE
  )
  
  first_row <- raw_data[1, ] |> unlist(use.names = FALSE)
  first_row_clean <- first_row |>
    stringr::str_squish() |>
    stringr::str_to_lower()
  
  required_cols_clean <- required_cols |>
    stringr::str_squish() |>
    stringr::str_to_lower()
  
  has_header <- identical(first_row_clean, required_cols_clean)
  
  if (has_header) {
    data <- readr::read_delim(
      file = file_path,
      delim = delim,
      col_names = TRUE,
      col_types = readr::cols(.default = readr::col_character()),
      trim_ws = TRUE,
      show_col_types = FALSE,
      progress = FALSE
    )
  } else {
    data <- raw_data
    colnames(data) <- required_cols
  }
  
  data
}

read_task_b_mentions <- function(file_path) {
  required_cols <- c(
    "num_article",
    "doi",
    "mention",
    "concept",
    "composed concept",
    "individual concept"
  )
  
  read_delim_with_optional_header(file_path, required_cols) |>
    janitor::clean_names() |>
    dplyr::transmute(
      num_article = stringr::str_squish(as.character(num_article)),
      doi = stringr::str_squish(as.character(doi)),
      mention = stringr::str_squish(as.character(mention)),
      concept = stringr::str_squish(as.character(concept)),
      composed_concept = stringr::str_squish(as.character(composed_concept)),
      individual_concept = stringr::str_squish(as.character(individual_concept))
    )
}


read_task_b_definitions <- function(file_path) {
  required_cols <- c(
    "concept",
    "intensional_definition"
  )
  
  read_delim_with_optional_header(file_path, required_cols) |>
    janitor::clean_names() |>
    dplyr::transmute(
      concept = stringr::str_squish(as.character(concept)),
      gold_definition = stringr::str_squish(as.character(intensional_definition))
    )
}


load_task_b_gold <- function(mentions_file, definitions_file) {
  mentions_data <- read_task_b_mentions(mentions_file)
  definitions_data <- read_task_b_definitions(definitions_file)
  
  mentions_data |>
    dplyr::left_join(definitions_data, by = "concept")
}


####### Load Gold Standard

gold_task_b_mental_health <- load_task_b_gold(
  mentions_file = "../../task_Definition/test/taskB_Mentions_mental_health_test.csv",
  definitions_file = "../../task_Definition/test/taskB_Definitions_test.csv"
)

gold_task_b_parkinson <- load_task_b_gold(
  mentions_file = "../../task_Definition/test/taskB_Mentions_parkinson_test.csv",
  definitions_file = "../../task_Definition/test/taskB_Definitions_test.csv"
)


####### Check empty definitions

# validate_task_b_gold <- function(gold_data) {
#   gold_data |>
#     dplyr::mutate(
#       missing_definition = is.na(gold_definition) | gold_definition == ""
#     )
# }
# 
# 
# gold_task_b_mental_health_checked <- validate_task_b_gold(
#   gold_task_b_mental_health
# )
# 
# gold_task_b_mental_health_checked |>
#   dplyr::count(missing_definition)
# 
# 
# gold_task_b_mental_health_checked |>
#   dplyr::filter(missing_definition)
# 
# 
# gold_task_b_parkinson_checked <- validate_task_b_gold(
#   gold_task_b_parkinson
# )
# 
# gold_task_b_parkinson_checked |>
#   dplyr::count(missing_definition)
# 
# 
# gold_task_b_parkinson_checked |>
#   dplyr::filter(missing_definition) |>
#   select(concept)



read_task_b_run_mentions <- function(file_path) {
  required_cols <- c(
    "num_article",
    "doi",
    "mention",
    "concept"
  )
  
  read_delim_with_optional_header(file_path, required_cols) |>
    janitor::clean_names() |>
    dplyr::transmute(
      num_article = stringr::str_squish(as.character(num_article)),
      doi = stringr::str_squish(as.character(doi)),
      mention = stringr::str_squish(as.character(mention)),
      concept = stringr::str_squish(as.character(concept))
    )
}

read_task_b_run_definitions <- function(file_path) {
  required_cols <- c(
    "concept",
    "definition"
  )
  
  data <- read_delim_with_optional_header(file_path, required_cols) |>
    janitor::clean_names()
  
  if (!all(c("concept", "definition") %in% names(data))) {
    stop(
      paste0(
        "Definitions file '", file_path,
        "' must contain columns corresponding to 'concept' and ",
        "'(intensional) definition'."
      ),
      call. = FALSE
    )
  }
  
  data |>
    dplyr::transmute(
      concept = stringr::str_squish(as.character(concept)),
      predicted_definition = stringr::str_squish(
        as.character(definition)
      )
    )
}


find_task_b_run_files <- function(task_b_runs_dir, subtask_name) {
  all_files <- fs::dir_ls(task_b_runs_dir, type = "file", recurse = FALSE)
  
  subtask_files <- all_files[
    stringr::str_detect(
      stringr::str_to_lower(fs::path_file(all_files)),
      stringr::str_to_lower(subtask_name)
    )
  ]
  
  if (length(subtask_files) == 0) {
    return(
      tibble::tibble(
        run_id = character(),
        mentions_file = character(),
        definitions_file = character()
      )
    )
  }
  
  file_index <- tibble::tibble(
    file_path = subtask_files,
    file_name = fs::path_file(subtask_files)
  ) |>
    dplyr::mutate(
      file_name_lower = stringr::str_to_lower(file_name),
      file_type = dplyr::case_when(
        stringr::str_detect(file_name_lower, "concept") ~ "concepts",
        stringr::str_detect(file_name_lower, "definition") ~ "definitions",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(file_type)) |>
    dplyr::mutate(
      run_id = file_name_lower |>
        stringr::str_remove("\\.[^.]+$") |>
        stringr::str_replace_all("concepts?", "") |>
        stringr::str_replace_all("definitions?", "") |>
        stringr::str_replace_all("__+", "_") |>
        stringr::str_replace_all("--+", "-") |>
        stringr::str_replace_all("_[._-]+", "_") |>
        stringr::str_replace_all("-[._-]+", "-") |>
        stringr::str_replace_all("^[._-]+|[._-]+$", "") |>
        stringr::str_squish()
    )
  
  run_pairs <- file_index |>
    dplyr::select(run_id, file_type, file_path) |>
    tidyr::pivot_wider(
      names_from = file_type,
      values_from = file_path
    ) |>
    dplyr::rename(
      mentions_file = concepts,
      definitions_file = definitions
    )
  
  incomplete_runs <- run_pairs |>
    dplyr::filter(is.na(mentions_file) | is.na(definitions_file))
  
  if (nrow(incomplete_runs) > 0) {
    warning(
      paste0(
        "Some Task B runs for subtask '", subtask_name,
        "' in '", task_b_runs_dir,
        "' do not have both mentions and definitions files. ",
        "They will be skipped."
      ),
      call. = FALSE
    )
  }
  
  run_pairs |>
    dplyr::filter(!is.na(mentions_file), !is.na(definitions_file))
}


load_task_b_run <- function(team_name, subtask_name, run_id,
                            mentions_file, definitions_file) {
  mentions_data <- read_task_b_run_mentions(mentions_file)
  definitions_data <- read_task_b_run_definitions(definitions_file)
  
  mentions_data |>
    dplyr::left_join(definitions_data, by = "concept") |>
    dplyr::mutate(
      team = team_name,
      subtask = subtask_name,
      run_id = run_id,
      mentions_file = fs::path_file(mentions_file),
      definitions_file = fs::path_file(definitions_file),
      .before = 1
    )
}

load_all_task_b_runs <- function(runs_dir) {
  team_dirs <- fs::dir_ls(runs_dir, type = "directory")
  
  run_index <- tibble::tibble(team_dir = team_dirs) |>
    dplyr::mutate(
      team = fs::path_file(team_dir),
      task_b_runs_dir = fs::path(team_dir, "TaskB")
    ) |>
    dplyr::filter(fs::dir_exists(task_b_runs_dir))
  
  all_specs <- purrr::map2_dfr(
    run_index$team,
    run_index$task_b_runs_dir,
    function(team, task_b_runs_dir) {
      mental_health_pairs <- find_task_b_run_files(
        task_b_runs_dir = task_b_runs_dir,
        subtask_name = "mental_health"
      ) |>
        dplyr::mutate(
          team = team,
          subtask = "mental_health"
        )
      
      parkinson_pairs <- find_task_b_run_files(
        task_b_runs_dir = task_b_runs_dir,
        subtask_name = "parkinson"
      ) |>
        dplyr::mutate(
          team = team,
          subtask = "parkinson"
        )
      
      dplyr::bind_rows(mental_health_pairs, parkinson_pairs)
    }
  )
  
  purrr::pmap_dfr(
    all_specs,
    function(run_id, mentions_file, definitions_file, team, subtask) {
      load_task_b_run(
        team_name = team,
        subtask_name = subtask,
        run_id = run_id,
        mentions_file = mentions_file,
        definitions_file = definitions_file
      )
    }
  )
}

task_b_runs <- load_all_task_b_runs("../../runs")

#task_b_runs %>% group_by(team, subtask, run_id) %>% count()
