suppressPackageStartupMessages({
  library(data.table)
})

cfg_file <- "config/gwas_catalog_exposures.tsv"

cfg <- fread(cfg_file)

# Estradiol and SHBG files use hm_* columns for rsID and harmonised alleles/effects.
hm_ids <- c("estradiol", "shbg_bmiadj")

cfg[exposure_id %in% hm_ids, `:=`(
  snp_col = "hm_rsid",
  chrom_col = "hm_chrom",
  pos_col = "hm_pos",
  effect_col = "hm_beta",
  effect_type = "beta",
  se_col = "standard_error",
  effect_allele_col = "hm_effect_allele",
  other_allele_col = "hm_other_allele",
  eaf_col = "hm_effect_allele_frequency",
  pval_col = "p_value",
  samplesize = "NA"
)]

fwrite(
  cfg,
  cfg_file,
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

cat("Updated hm_* column mapping for:\n")
print(cfg[exposure_id %in% hm_ids])
