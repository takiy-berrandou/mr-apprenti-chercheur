suppressPackageStartupMessages({
  library(data.table)
})

dir.create("config", showWarnings = FALSE, recursive = TRUE)

# SCAD outcome.
# Based on the downloaded GWAS Catalog harmonised file inspected on the server.
outcome <- data.table(
  outcome_id = "scad",
  outcome_label = "SCAD",
  accession = "GCST90245878",
  url = "https://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/GCST90245001-GCST90246000/GCST90245878/harmonised/GCST90245878.h.tsv.gz",
  outcome_file = "data/raw/scad_GCST90245878.h.tsv.gz",
  snp_col = "rsid",
  effect_col = "beta",
  effect_type = "beta",
  se_col = "standard_error",
  effect_allele_col = "effect_allele",
  other_allele_col = "other_allele",
  eaf_col = "effect_allele_frequency",
  pval_col = "p_value",
  samplesize = "11209"
)

fwrite(
  outcome,
  "config/outcome_scad.tsv",
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

# Candidate exposures from GWAS Catalog.
# These are initial candidates. If one URL fails or columns differ, edit this file.
exposures <- data.table(
  exposure_id = c("bmi", "sbp", "ldl"),
  exposure_label = c("BMI", "Systolic blood pressure", "LDL cholesterol"),
  accession = c("GCST90018732", "GCST90310294", "GCST90239658"),
  url_override = c("", "", ""),

  snp_col = c("rsid", "rsid", "rsid"),
  chrom_col = c("chromosome", "chromosome", "chromosome"),
  pos_col = c("base_pair_location", "base_pair_location", "base_pair_location"),

  effect_col = c("beta", "beta", "beta"),
  effect_type = c("beta", "beta", "beta"),
  se_col = c("standard_error", "standard_error", "standard_error"),

  effect_allele_col = c("effect_allele", "effect_allele", "effect_allele"),
  other_allele_col = c("other_allele", "other_allele", "other_allele"),
  eaf_col = c("effect_allele_frequency", "effect_allele_frequency", "effect_allele_frequency"),
  pval_col = c("p_value", "p_value", "p_value"),

  samplesize = c("NA", "NA", "NA"),
  p_threshold = c("5e-8", "5e-8", "5e-8"),
  clump_r2 = c("0.001", "0.001", "0.001"),
  clump_kb = c("10000", "10000", "10000")
)

fwrite(
  exposures,
  "config/gwas_catalog_exposures.tsv",
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

# Local paths, to edit manually before clumping.
local_paths <- c(
  '# Edit these paths before running scripts/06_clump_with_plink.sh',
  '',
  '# Path to PLINK2 binary',
  'PLINK2_BIN="/shared/projects/utopia/work/software/bin/plink2"',
  '',
  '# PLINK reference panel prefix, without .bed/.bim/.fam',
  '# Example: REF_BFILE="/shared/projects/utopia/work/ref/ukbb_10k_eur"',
  'REF_BFILE="/path/to/eur_refpanel_prefix"'
)

writeLines(local_paths, "config/local_paths.sh")

cat("Wrote config/outcome_scad.tsv\n")
cat("Wrote config/gwas_catalog_exposures.tsv\n")
cat("Wrote config/local_paths.sh\n")
