# Load packages -----------------------------------------------------------

library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tibble)
library(fs)
library(janitor)

# Helper: detect delimiter ------------------------------------------------

detect_delimiter <- function(file_path) {
  first_lines <- readr::read_lines(file_path, n_max = 1)
  
  comma_count <- stringr::str_count(first_lines, ",") |> sum()
  semicolon_count <- stringr::str_count(first_lines, ";") |> sum()
  
  if (semicolon_count > comma_count) {
    return(";")
  }
  
  ","
}

# Helper: read one TaskA run file ----------------------------------------

read_task_a_file <- function(file_path, team_name) {
  delim <- detect_delimiter(file_path)
  
  required_cols <- c("num_article", "doi", "term")
  
  # Read WITHOUT header first
  raw_data <- readr::read_delim(
    file = file_path,
    delim = delim,
    col_names = FALSE,
    col_types = cols(.default = col_character()),
    trim_ws = TRUE,
    show_col_types = FALSE,
    progress = FALSE
  )
  
  # Extract first row
  first_row <- raw_data[1, ] |> unlist(use.names = FALSE)
  
  # Normalize for comparison
  first_row_clean <- stringr::str_to_lower(stringr::str_squish(first_row))
  
  has_header <- identical(first_row_clean, required_cols)
  
  if (has_header) {
    # Re-read properly with header
    run_data <- readr::read_delim(
      file = file_path,
      delim = delim,
      col_names = TRUE,
      col_types = cols(.default = col_character()),
      trim_ws = TRUE,
      show_col_types = FALSE,
      progress = FALSE
    ) |>
      janitor::clean_names()
  } else {
    # Assign column names manually
    run_data <- raw_data
    colnames(run_data) <- required_cols
  }
  
  # Final checks ---------------------------------------------------------
  
  missing_cols <- setdiff(required_cols, names(run_data))
  
  if (length(missing_cols) > 0) {
    stop(
      paste0(
        "File '", file_path, "' is missing required columns: ",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  
  # Standardize output ---------------------------------------------------
  
  run_data |>
    transmute(
      team = team_name,
      file_name = fs::path_file(file_path),
      file_path = file_path,
      num_article = suppressWarnings(as.integer(num_article)),
      doi = stringr::str_squish(doi),
      term = stringr::str_squish(term)
    )
}


# Find TaskA run files ----------------------------------------------------

find_task_a_files <- function(runs_dir) {
  
  team_dirs <- fs::dir_ls(runs_dir, type = "directory")
  print(team_dirs)
  
  tibble(team_dir = team_dirs) |>
    mutate(
      team = fs::path_file(team_dir),
      #task_a_runs_dir = fs::path(team_dir, "taskA", "runs")
      task_a_runs_dir = fs::path(team_dir, "taskA")
    ) |>
    filter(fs::dir_exists(task_a_runs_dir)) |>
    mutate(
      run_files = map(
        task_a_runs_dir,
        ~ fs::dir_ls(
          .x,
          type = "file",
          recurse = FALSE,
          regexp = "\\.(csv|txt)$"
        )
      )
    ) |>
    select(team, run_files) |>
    tidyr::unnest(run_files, keep_empty = TRUE) |>
    rename(file_path = run_files) |>
    filter(!is.na(file_path))
}

# Load all TaskA runs -----------------------------------------------------

load_task_a_runs <- function(runs_dir) {
  task_a_files <- find_task_a_files(runs_dir)
  
  if (nrow(task_a_files) == 0) {
    stop(
      paste0("No TaskA run files found under: ", runs_dir),
      call. = FALSE
    )
  }
  
  purrr::map2_dfr(
    .x = task_a_files$file_path,
    .y = task_a_files$team,
    .f = read_task_a_file
  )
}

# Example ----------------------------------------------------------------

runs_dir <- "../../runs"
task_a_runs <- load_task_a_runs(runs_dir)
# print(task_a_runs)

task_a_runs %>% group_by(team, file_name) %>% count()

task_a_parkinson_test <- read_csv2("../../task_ATE/test/taskA_parkinson_test.csv", 
                                   col_types = c("c", "c"))

task_a_mental_health_test <- read_csv2("../../task_ATE/test/taskA_mental_health_test.csv", 
                                       col_types = c("c", "c"))

task_a_mental_health_terms <- read_csv("../../task_ATE/test/taskA_mental_health_terms_test.csv",
                                            col_types = c("c", "c", "c"))

task_a_parkinson_terms <- read_csv("../../task_ATE/test/taskA_parkinson_terms_test.csv",
                                            col_types = c("c", "c", "c"))


task_a_parkinson_terms_test <- inner_join(task_a_parkinson_terms,
                                          task_a_parkinson_test[, "num_article"], 
                                          by = "num_article")


task_a_mental_health_terms_test <- inner_join(task_a_mental_health_terms,
                                          task_a_mental_health_test[, "num_article"], 
                                          by = "num_article")
