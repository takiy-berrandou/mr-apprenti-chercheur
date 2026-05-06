suppressPackageStartupMessages({
  library(data.table)
})

cfg <- fread("config/gwas_catalog_exposure_urls.tsv")

dir.create("data/exposure_gws", showWarnings = FALSE, recursive = TRUE)

check_cols <- function(dt, cols, label) {
  missing <- cols[!cols %in% names(dt)]
  if (length(missing) > 0) {
    cat("\nAvailable columns for", label, ":\n")
    print(names(dt))
    stop("Missing columns: ", paste(missing, collapse = ", "))
  }
}

get_samplesize <- function(dt, samplesize_value) {
  v <- as.character(samplesize_value)

  if (length(v) == 0 || is.na(v) || v == "" || v == "NA") {
    return(rep(NA_real_, nrow(dt)))
  }

  if (v %in% names(dt)) {
    return(as.numeric(dt[[v]]))
  }

  return(rep(as.numeric(v), nrow(dt)))
}

for (i in seq_len(nrow(cfg))) {
  ec <- cfg[i]

  infile <- file.path(
    "data/exposures_full",
    paste0(ec$exposure_id, "_", ec$accession, ".h.tsv.gz")
  )

  if (!file.exists(infile)) {
    warning("Missing exposure file: ", infile)
    next
  }

  cat("\n============================================\n")
  cat("Extracting genome-wide significant SNPs for:", ec$exposure_label, "\n")
  cat("Input:", infile, "\n")
  cat("============================================\n")

  dt <- fread(infile)

  needed <- c(
    ec$snp_col,
    ec$chrom_col,
    ec$pos_col,
    ec$effect_col,
    ec$se_col,
    ec$effect_allele_col,
    ec$other_allele_col,
    ec$pval_col
  )

  if (!is.na(ec$eaf_col) && ec$eaf_col != "") {
    needed <- c(needed, ec$eaf_col)
  }

  check_cols(dt, needed, ec$exposure_label)

  beta <- as.numeric(dt[[ec$effect_col]])

  if (ec$effect_type == "or") {
    beta <- log(beta)
  }

  out <- data.table(
    CHR = dt[[ec$chrom_col]],
    BP = dt[[ec$pos_col]],
    SNP = as.character(dt[[ec$snp_col]]),
    beta = beta,
    se = as.numeric(dt[[ec$se_col]]),
    effect_allele = toupper(as.character(dt[[ec$effect_allele_col]])),
    other_allele = toupper(as.character(dt[[ec$other_allele_col]])),
    pval = as.numeric(dt[[ec$pval_col]]),
    samplesize = get_samplesize(dt, ec$samplesize)
  )

  if (!is.na(ec$eaf_col) && ec$eaf_col != "") {
    out[, eaf := as.numeric(dt[[ec$eaf_col]])]
  } else {
    out[, eaf := NA_real_]
  }

  out <- out[
    !is.na(SNP) & SNP != "" &
      !is.na(CHR) &
      !is.na(BP) &
      !is.na(beta) &
      !is.na(se) &
      !is.na(pval) &
      effect_allele %in% c("A", "C", "G", "T") &
      other_allele %in% c("A", "C", "G", "T")
  ]

  out <- unique(out, by = "SNP")
  out <- out[order(pval)]

  pthr <- as.numeric(ec$p_threshold)
  gws <- out[pval <= pthr]

  gws_file <- file.path(
    "data/exposure_gws",
    paste0(ec$exposure_id, "_gws.tsv")
  )

  clump_file <- file.path(
    "data/exposure_gws",
    paste0(ec$exposure_id, "_for_clump.tsv")
  )

  fwrite(gws, gws_file, sep = "\t")

  # PLINK clump input.
  # Keep only SNP and P to avoid ambiguity.
  fwrite(
    gws[, .(SNP, P = pval)],
    clump_file,
    sep = "\t"
  )

  cat("Total variants after QC:", nrow(out), "\n")
  cat("Genome-wide significant SNPs:", nrow(gws), "\n")
  cat("Saved:", gws_file, "\n")
  cat("Saved:", clump_file, "\n")
}
