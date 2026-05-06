suppressPackageStartupMessages({
  library(data.table)
  library(TwoSampleMR)
})

dir.create("data/harmonised", showWarnings = FALSE, recursive = TRUE)

outcome_cfg <- fread("config/outcome_scad.tsv")
exposure_cfg <- fread("config/gwas_catalog_exposures.tsv")

standardise_outcome <- function(dt, cfg) {
  required <- c(
    cfg$snp_col,
    cfg$effect_col,
    cfg$se_col,
    cfg$effect_allele_col,
    cfg$other_allele_col,
    cfg$eaf_col,
    cfg$pval_col
  )

  missing <- required[!required %in% names(dt)]

  if (length(missing) > 0) {
    cat("Available outcome columns:\n")
    print(names(dt))
    stop("Missing outcome columns: ", paste(missing, collapse = ", "))
  }

  beta <- as.numeric(dt[[cfg$effect_col]])

  if (cfg$effect_type == "or") {
    beta <- log(beta)
  }

  out <- data.table(
    SNP = as.character(dt[[cfg$snp_col]]),
    beta = beta,
    se = as.numeric(dt[[cfg$se_col]]),
    effect_allele = toupper(as.character(dt[[cfg$effect_allele_col]])),
    other_allele = toupper(as.character(dt[[cfg$other_allele_col]])),
    eaf = as.numeric(dt[[cfg$eaf_col]]),
    pval = as.numeric(dt[[cfg$pval_col]]),
    samplesize = as.numeric(cfg$samplesize)
  )

  out <- out[
    !is.na(SNP) & SNP != "" &
      !is.na(beta) &
      !is.na(se) &
      !is.na(pval) &
      effect_allele %in% c("A", "C", "G", "T") &
      other_allele %in% c("A", "C", "G", "T")
  ]

  unique(out, by = "SNP")
}

get_exposure_label <- function(exposure_id_value, exposure_cfg) {
  hit <- exposure_cfg[exposure_id == exposure_id_value]

  if (nrow(hit) == 0) {
    return(exposure_id_value)
  }

  hit$exposure_label[1]
}

scad_file <- outcome_cfg$outcome_file[1]

if (!file.exists(scad_file)) {
  stop("SCAD file not found: ", scad_file)
}

cat("Reading SCAD:", scad_file, "\n")
scad_raw <- fread(scad_file)

scad_std <- standardise_outcome(scad_raw, outcome_cfg[1])
cat("SCAD variants after QC:", nrow(scad_std), "\n")

instrument_files <- list.files(
  "data/instruments",
  pattern = "_instruments\\.tsv$",
  full.names = TRUE
)

if (length(instrument_files) == 0) {
  stop("No instrument files found in data/instruments/")
}

for (f in instrument_files) {
  exposure_id_value <- sub("_instruments\\.tsv$", "", basename(f))
  exposure_label_value <- get_exposure_label(exposure_id_value, exposure_cfg)

  cat("\n============================================\n")
  cat("Harmonising:", exposure_label_value, "-> SCAD\n")
  cat("Instrument file:", f, "\n")
  cat("============================================\n")

  exposure_std <- fread(f)

  required_exp_cols <- c(
    "SNP",
    "beta",
    "se",
    "effect_allele",
    "other_allele",
    "eaf",
    "pval",
    "samplesize"
  )

  missing_exp <- required_exp_cols[!required_exp_cols %in% names(exposure_std)]

  if (length(missing_exp) > 0) {
    cat("Available exposure columns:\n")
    print(names(exposure_std))
    stop("Missing exposure columns: ", paste(missing_exp, collapse = ", "))
  }

  outcome_subset <- scad_std[SNP %in% exposure_std$SNP]

  cat("Exposure instruments:", nrow(exposure_std), "\n")
  cat("Found in SCAD:", nrow(outcome_subset), "\n")

  if (nrow(outcome_subset) == 0) {
    warning("No SNPs found in SCAD for ", exposure_id_value)
    next
  }

  exposure_dat <- format_data(
    as.data.frame(exposure_std),
    type = "exposure",
    snp_col = "SNP",
    beta_col = "beta",
    se_col = "se",
    effect_allele_col = "effect_allele",
    other_allele_col = "other_allele",
    eaf_col = "eaf",
    pval_col = "pval",
    samplesize_col = "samplesize"
  )

  exposure_dat$exposure <- exposure_label_value
  exposure_dat$id.exposure <- exposure_id_value

  outcome_dat <- format_data(
    as.data.frame(outcome_subset),
    type = "outcome",
    snp_col = "SNP",
    beta_col = "beta",
    se_col = "se",
    effect_allele_col = "effect_allele",
    other_allele_col = "other_allele",
    eaf_col = "eaf",
    pval_col = "pval",
    samplesize_col = "samplesize"
  )

  outcome_dat$outcome <- "SCAD"
  outcome_dat$id.outcome <- "scad"

  dat <- harmonise_data(
    exposure_dat = exposure_dat,
    outcome_dat = outcome_dat,
    action = 2
  )

  outfile <- file.path(
    "data/harmonised",
    paste0(exposure_id_value, "_scad.tsv")
  )

  fwrite(dat, outfile, sep = "\t")

  cat("Harmonised SNPs:", nrow(dat), "\n")
  cat("Kept for MR:", sum(dat$mr_keep, na.rm = TRUE), "\n")
  cat("Saved:", outfile, "\n")
}
