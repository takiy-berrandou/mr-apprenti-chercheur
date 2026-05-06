suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(ggplot2)
  library(TwoSampleMR)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  files <- list.files(
    "data/harmonised",
    pattern = "_scad\\.tsv$",
    full.names = TRUE
  )
} else {
  files <- args
}

if (length(files) == 0) {
  stop("No harmonised files found.")
}

for (infile in files) {
  if (!file.exists(infile)) {
    warning("File does not exist: ", infile)
    next
  }

  exposure_id <- sub("_scad\\.tsv$", "", basename(infile))
  outdir <- file.path("results", exposure_id)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  cat("\n============================================\n")
  cat("Testing MR:", infile, "\n")
  cat("============================================\n")

  dat <- fread(infile)
  dat <- as.data.frame(dat)

  if ("mr_keep" %in% names(dat)) {
    dat <- dat[dat$mr_keep == TRUE, ]
  }

  cat("SNPs kept:", nrow(dat), "\n")

  if (nrow(dat) < 1) {
    warning("No SNPs kept for MR in ", infile)
    next
  }

  mr_results <- tryCatch(mr(dat), error = function(e) e)

  if (inherits(mr_results, "error")) {
    warning("MR failed for ", infile, ": ", mr_results$message)
    next
  }

  fwrite(as.data.table(mr_results), file.path(outdir, "mr_results.tsv"), sep = "\t")

  mr_or <- tryCatch(generate_odds_ratios(mr_results), error = function(e) NULL)

  if (!is.null(mr_or)) {
    fwrite(as.data.table(mr_or), file.path(outdir, "mr_results_or.tsv"), sep = "\t")
    print(mr_or)
  } else {
    print(mr_results)
  }

  # Scatter plot
  try({
    scatter <- mr_scatter_plot(mr_results, dat)
    ggsave(
      filename = file.path(outdir, "scatter_plot.png"),
      plot = scatter[[1]],
      width = 7,
      height = 5,
      dpi = 300
    )
  }, silent = TRUE)

  # Single SNP forest
  try({
    single_snp <- mr_singlesnp(dat)
    fwrite(as.data.table(single_snp), file.path(outdir, "single_snp_results.tsv"), sep = "\t")
    forest <- mr_forest_plot(single_snp)
    ggsave(
      filename = file.path(outdir, "forest_plot.png"),
      plot = forest[[1]],
      width = 7,
      height = 6,
      dpi = 300
    )
  }, silent = TRUE)

  # Leave-one-out
  try({
    loo <- mr_leaveoneout(dat)
    fwrite(as.data.table(loo), file.path(outdir, "leave_one_out.tsv"), sep = "\t")
    loo_plot <- mr_leaveoneout_plot(loo)
    ggsave(
      filename = file.path(outdir, "leave_one_out_plot.png"),
      plot = loo_plot[[1]],
      width = 7,
      height = 6,
      dpi = 300
    )
  }, silent = TRUE)

  # Heterogeneity
  try({
    het <- mr_heterogeneity(dat)
    fwrite(as.data.table(het), file.path(outdir, "heterogeneity.tsv"), sep = "\t")
  }, silent = TRUE)

  # Pleiotropy
  try({
    pleio <- mr_pleiotropy_test(dat)
    fwrite(as.data.table(pleio), file.path(outdir, "pleiotropy.tsv"), sep = "\t")
  }, silent = TRUE)

  cat("Saved results in:", outdir, "\n")
}
