# Add quartiles to one result table ----------------------------------------

create_summary_row_task_a <- function(results_table, label, summary_fun) {
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
  summary_row$file_name <- paste0(label, " values of all runs")
  
  summary_row
}

create_benchmark_rows_task_a <- function(results_table) {
  dplyr::bind_rows(
    create_summary_row_task_a(
      results_table,
      label = "q1",
      summary_fun = \(x) stats::quantile(x, probs = 0.25, na.rm = TRUE)
    ),
    create_summary_row_task_a(
      results_table,
      label = "median",
      summary_fun = \(x) stats::median(x, na.rm = TRUE)
    ),
    create_summary_row_task_a(
      results_table,
      label = "q3",
      summary_fun = \(x) stats::quantile(x, probs = 0.75, na.rm = TRUE)
    )
  ) |>
    dplyr::mutate(
      dplyr::across(where(is.numeric), ~ round(.x, 3))
    )
}


# Export one CSV per team for one track ----------------------------------

export_team_results <- function(results_table, output_dir, track_name) {
  fs::dir_create(output_dir)
  
  benchmark_rows <- create_benchmark_rows_task_a(results_table)
  
  team_results <- results_table |>
    dplyr::group_by(team) |>
    dplyr::group_split()
  
  purrr::walk(
    team_results,
    function(team_data) {
      team_name <- unique(team_data$team)
      
      output_data <- dplyr::bind_rows(
        team_data,
        benchmark_rows
      )
      
      output_file <- fs::path(
        output_dir,
        paste0("TaskA-", track_name, "-results-", team_name, ".csv")
      )
      
      readr::write_csv(output_data, output_file)
    }
  )
  
  invisible(NULL)
}

export_team_results(
  results_table = results_parkinson,
  output_dir = "team-feedback/parkinson",
  track_name = "parkinson"
)

export_team_results(
  results_table = results_mental_health,
  output_dir = "team-feedback/mental-health",
  track_name = "mental-health"
)
