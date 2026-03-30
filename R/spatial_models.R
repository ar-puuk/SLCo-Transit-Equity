# R/spatial_models.R
# Spatial weights construction and autoregressive model wrappers.
# Sourced by index.qmd via source("R/spatial_models.R").

# ── Spatial weights ──────────────────────────────────────────────────────────

#' Build a Queen's contiguity spatial weights object
#'
#' @param sf_layer  An sf polygon layer.
#' @param style     Weight style passed to spdep::nb2listw() (default "W" = row-standardized).
#' @return A listw object.
build_queen_weights <- function(sf_layer, style = "W") {
  nb <- spdep::poly2nb(sf_layer, queen = TRUE)
  spdep::nb2listw(neighbours = nb, style = style, zero.policy = TRUE)
}

# ── Model formula ────────────────────────────────────────────────────────────

#' Standard equity regression formula used across OLS, SLM, and SEM
equity_formula <- access1 ~ p_Race + p_Ethnicity + p_Employment + p_Age +
                             p_Education + p_HMOwnership + p_Income + p_VOwnership

# ── Model fitting wrappers ───────────────────────────────────────────────────

#' Fit OLS, Spatial Lag, and Spatial Error models and return as a named list
#'
#' @param data    sf or data frame with the response and predictor columns.
#' @param weights A listw weights object from build_queen_weights().
#' @return A named list with elements: ols, slm, sem.
fit_spatial_models <- function(data, weights) {
  list(
    ols = lm(
      formula = equity_formula,
      data    = data
    ),
    slm = spatialreg::lagsarlm(
      formula     = equity_formula,
      data        = data,
      listw       = weights,
      zero.policy = TRUE
    ),
    sem = spatialreg::errorsarlm(
      formula     = equity_formula,
      data        = data,
      listw       = weights,
      zero.policy = TRUE
    )
  )
}

# ── AIC comparison table ─────────────────────────────────────────────────────

#' Build a tidy AIC comparison data frame from the three model list
#'
#' @param models Named list from fit_spatial_models().
#' @return A tibble with columns: Model, Log_Likelihood, AIC.
aic_table <- function(models) {
  tibble::tibble(
    Model           = c("OLS", "Spatial Lag (SLM)", "Spatial Error (SEM)"),
    Log_Likelihood  = c(
      as.numeric(logLik(models$ols)),
      as.numeric(logLik(models$slm)),
      as.numeric(logLik(models$sem))
    ),
    AIC             = c(
      AIC(models$ols),
      AIC(models$slm),
      AIC(models$sem)
    )
  ) |>
    dplyr::mutate(dplyr::across(where(is.numeric), \(x) round(x, 2)))
}

# ── LISA computation ─────────────────────────────────────────────────────────

#' Compute Local Moran's I (LISA) and classify clusters
#'
#' Adds three columns to the input sf layer:
#'   moran_p — local Moran's I p-value
#'   zscore  — standardized accessibility score
#'   LISA    — "High-High Cluster" | "No Significant Cluster"
#'
#' @param sf_layer  sf polygon layer with an access1 column.
#' @param weights   A listw weights object.
#' @param alpha     Significance threshold (default 0.05).
#' @return The input sf layer with three new columns appended.
compute_lisa <- function(sf_layer, weights, alpha = 0.05) {
  sf_layer |>
    dplyr::mutate(
      moran_p = spdep::localmoran(access1, listw = weights,
                                  zero.policy = TRUE)[, 5],
      zscore  = as.numeric(scale(access1)),
      lagged  = spdep::lag.listw(zscore, x = weights),
      LISA    = dplyr::if_else(
        zscore >= 0 & lagged >= 0 & moran_p <= alpha,
        "High-High Cluster",
        "No Significant Cluster"
      )
    )
}
