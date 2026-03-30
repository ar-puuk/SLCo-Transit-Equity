# R/utils.R
# Shared utility functions for the SLCo Transit Equity analysis.
# Sourced at the top of index.qmd via source("R/utils.R").

# ── Correlation scatter plot ─────────────────────────────────────────────────

#' Build a ggplot2 bivariate scatter for one equity indicator vs. accessibility
#'
#' @param data   An sf or data frame containing the variables.
#' @param x_var  Character name of the independent (equity) variable column.
#' @param x_label Axis label string for the x-axis.
#' @param y_var  Character name of the dependent (accessibility) variable (default "access1").
#' @param y_label Axis label string for the y-axis.
#' @return A ggplot object.
corr_plot <- function(data,
                      x_var,
                      x_label,
                      y_var   = "access1",
                      y_label = "Transit Accessibility (2SFCA)") {
  data |>
    ggplot(aes(x = .data[[x_var]], y = .data[[y_var]])) +
    geom_point(alpha = 0.40, size = 1.1, color = "#3c6194") +
    geom_smooth(method = "lm", se = TRUE,
                color = "#c0392b", linewidth = 0.8, fill = "#c0392b", alpha = 0.12) +
    ggpubr::stat_cor(
      aes(label = paste(after_stat(r.label), after_stat(p.label), sep = "~`,`~")),
      p.accuracy = 0.001,
      size       = 3.2
    ) +
    labs(x = x_label, y = y_label) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor = element_blank(),
      axis.title       = element_text(size = 9)
    )
}

# ── Tidy gt table for spatial model coefficients ─────────────────────────────

#' Format a tidy data frame of spatial model coefficients as a gt table
#'
#' @param tidy_df  A tidy data frame from broom::tidy() with columns:
#'                 term, estimate, std.error, statistic, p.value, model (optional).
#' @return A gt table object.
fmt_coef_table <- function(tidy_df) {
  tidy_df |>
    mutate(
      sig = dplyr::case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01  ~ "**",
        p.value < 0.05  ~ "*",
        p.value < 0.10  ~ ".",
        TRUE            ~ ""
      )
    ) |>
    gt::gt() |>
    gt::fmt_number(columns = c(estimate, std.error, statistic), decimals = 4) |>
    gt::fmt_number(columns = p.value, decimals = 4) |>
    gt::cols_label(
      term      = "Variable",
      estimate  = "Estimate",
      std.error = "Std. Error",
      statistic = "z / t",
      p.value   = "p-value",
      sig       = ""
    ) |>
    gt::tab_style(
      style     = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(
        rows    = p.value < 0.05,
        columns = c(term, estimate, sig)
      )
    ) |>
    gt::tab_footnote(
      footnote  = "Significance codes: *** p<0.001, ** p<0.01, * p<0.05, . p<0.10",
      locations = gt::cells_column_labels(columns = sig)
    ) |>
    gt::opt_stylize(style = 6, color = "blue")
}

# ── Recode equity variable names for display ─────────────────────────────────

#' Replace internal variable names with human-readable labels
#'
#' @param x A character vector of variable names from the regression models.
#' @return A character vector of display labels.
recode_equity_vars <- function(x) {
  dplyr::recode(x,
    `(Intercept)`  = "Intercept",
    p_Race         = "Race: % Non-White",
    p_Ethnicity    = "Ethnicity: % Hispanic/Latino",
    p_Employment   = "Employment: % Unemployed",
    p_Age          = "Age: % Dependent (<18 or >65)",
    p_Education    = "Education: % Without HS Diploma",
    p_HMOwnership  = "Housing: % Renter-Occupied",
    p_Income       = "Income: % HH <80% AMI",
    p_VOwnership   = "Vehicle: % Car-Free HH"
  )
}
