suppressPackageStartupMessages({
  library(data.table)
})

dir.create("data/instruments", showWarnings = FALSE, recursive = TRUE)

gws_files <- list.files(
  "data/exposure_gws",
  pattern = "_gws\\.tsv$",
  full.names = TRUE
)

if (length(gws_files) == 0) {
  stop("No GWS files found in data/exposure_gws/")
}

find_clump_file <- function(id) {
  candidates <- list.files(
    "data/exposure_clumped",
    pattern = paste0("^", id, ".*clump"),
    full.names = TRUE
  )

  candidates <- candidates[!grepl("\\.log$", candidates)]

  if (length(candidates) == 0) {
    return(NA_character_)
  }

  candidates[1]
}

extract_lead_snps <- function(clump_file) {
  cl <- fread(clump_file, fill = TRUE)

  possible <- c("SNP", "ID", "rsid", "SNPID")
  snp_col <- possible[possible %in% names(cl)][1]

  if (is.na(snp_col)) {
    cat("\nColumns in clump file:\n")
    print(names(cl))
    stop("Could not identify lead SNP column in: ", clump_file)
  }

  unique(as.character(cl[[snp_col]]))
}

for (gws_file in gws_files) {
  id <- sub("_gws\\.tsv$", "", basename(gws_file))

  cat("\n============================================\n")
  cat("Making instruments for:", id, "\n")
  cat("============================================\n")

  clump_file <- find_clump_file(id)

  if (is.na(clump_file)) {
    warning("No clump file found for ", id)
    next
  }

  cat("Clump file:", clump_file, "\n")

  gws <- fread(gws_file)
  lead_snps <- extract_lead_snps(clump_file)

  instruments <- gws[SNP %in% lead_snps]
  instruments <- unique(instruments, by = "SNP")
  instruments <- instruments[order(pval)]

  instruments <- instruments[, .(
    SNP,
    beta,
    se,
    effect_allele,
    other_allele,
    eaf,
    pval,
    samplesize
  )]

  outfile <- file.path("data/instruments", paste0(id, "_instruments.tsv"))

  fwrite(instruments, outfile, sep = "\t")

  cat("Lead SNPs in clump output:", length(lead_snps), "\n")
  cat("Instruments retained:", nrow(instruments), "\n")
  cat("Saved:", outfile, "\n")
}
