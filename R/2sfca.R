# R/2sfca.R
# Two-Step Floating Catchment Area (2SFCA) computation functions.
# Sourced by index.qmd via source("R/2sfca.R").
#
# The 2SFCA method (Luo & Wang, 2003) quantifies spatial accessibility
# by combining supply capacity and population demand within shared
# pedestrian isochrone catchment zones.

# ── Step 1: Supply ratio per TRAX station ───────────────────────────────────

#' Compute supply-to-population ratios for each TRAX station
#'
#' Spatially joins a station catchment polygon layer to block group centroids,
#' then calculates two supply ratios:
#'   supply_ratio1 = ServiceCapacity / sum(population in catchment)
#'   supply_ratio2 = AvgRidership   / sum(population in catchment)
#'
#' @param trax_catchment  sf polygon layer of TRAX station isochrones with
#'                        OBJECTID, ServCapaCT, and AvgRider columns.
#' @param blockgrp_centroids sf point layer of block group centroids with
#'                           total_popE column.
#' @return A data frame (geometry dropped) with columns:
#'         OBJECTID, sum_pop, supply_ratio1, supply_ratio2.
compute_supply_ratio <- function(trax_catchment, blockgrp_centroids) {
  sf::st_join(trax_catchment, blockgrp_centroids, left = FALSE) |>
    sf::st_drop_geometry() |>
    dplyr::group_by(OBJECTID) |>
    dplyr::summarise(
      sum_pop       = sum(total_popE, na.rm = TRUE),
      supply_ratio1 = dplyr::first(ServCapaCT) / sum_pop,
      supply_ratio2 = dplyr::first(AvgRider)   / sum_pop,
      .groups       = "drop"
    )
}

# ── Step 2: Demand (accessibility) score per block group ────────────────────

#' Compute 2SFCA accessibility scores for each block group
#'
#' Spatially joins population catchment isochrones to TRAX station supply
#' ratio points, then sums the supply ratios of all stations within each
#' block group's catchment.
#'
#' @param pop_catchment   sf polygon layer of block group isochrones with
#'                        GEOID and total_pop columns.
#' @param trax_to_pop     sf point layer of TRAX stations with
#'                        supply_ratio1 and supply_ratio2 columns.
#' @return A data frame (geometry dropped) with columns:
#'         GEOID, access1 (capacity-based), access2 (ridership-based).
compute_accessibility <- function(pop_catchment, trax_to_pop) {
  sf::st_join(pop_catchment, trax_to_pop) |>
    sf::st_drop_geometry() |>
    dplyr::group_by(GEOID) |>
    dplyr::summarise(
      access1 = sum(supply_ratio1, na.rm = TRUE),
      access2 = sum(supply_ratio2, na.rm = TRUE),
      .groups = "drop"
    )
}

# ── Wrapper: run both steps and return joined block group layer ─────────────

#' Run the full 2SFCA pipeline and merge results into block group polygons
#'
#' Calls compute_supply_ratio() and compute_accessibility() in sequence,
#' then left-joins the accessibility scores back into the block group polygon
#' layer.
#'
#' @param trax_catchment    See compute_supply_ratio().
#' @param blockgrp_centroids See compute_supply_ratio().
#' @param pop_catchment     See compute_accessibility().
#' @param trax_stn          sf point layer of raw TRAX stations (for join key).
#' @param slco_blockgrp     sf polygon layer of block groups (equity indicators
#'                          already computed) to receive the accessibility scores.
#' @return An sf polygon layer identical to slco_blockgrp with access1 and
#'         access2 columns appended.
run_2sfca <- function(trax_catchment,
                      blockgrp_centroids,
                      pop_catchment,
                      trax_stn,
                      slco_blockgrp) {
  supply  <- compute_supply_ratio(trax_catchment, blockgrp_centroids)
  trax_to_pop <- dplyr::left_join(trax_stn, supply, by = "OBJECTID") |>
    dplyr::select(OBJECTID, STATIONNAM, supply_ratio1, supply_ratio2)

  demand  <- compute_accessibility(pop_catchment, trax_to_pop)

  dplyr::left_join(slco_blockgrp, demand, by = "GEOID")
}
