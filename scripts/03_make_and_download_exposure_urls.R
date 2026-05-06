suppressPackageStartupMessages({
  library(data.table)
})

make_gcst_group <- function(accession) {
  num_str <- sub("^GCST", "", accession)
  width <- nchar(num_str)
  num <- as.integer(num_str)

  start <- ((num - 1) %/% 1000) * 1000 + 1
  end <- start + 999

  paste0(
    "GCST",
    sprintf(paste0("%0", width, "d"), start),
    "-GCST",
    sprintf(paste0("%0", width, "d"), end)
  )
}

make_gcst_url <- function(accession) {
  group <- make_gcst_group(accession)
  paste0(
    "https://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/",
    group, "/",
    accession, "/harmonised/",
    accession, ".h.tsv.gz"
  )
}

cfg <- fread("config/gwas_catalog_exposures.tsv")

cfg[, auto_url := vapply(accession, make_gcst_url, character(1))]
cfg[, url := ifelse(
  is.na(url_override) | url_override == "",
  auto_url,
  url_override
)]

fwrite(
  cfg,
  "config/gwas_catalog_exposure_urls.tsv",
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

cat("Wrote config/gwas_catalog_exposure_urls.tsv\n")
print(cfg[, .(exposure_id, exposure_label, accession, url)])

dir.create("data/exposures_full", showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)

for (i in seq_len(nrow(cfg))) {
  exposure_id <- cfg$exposure_id[i]
  label <- cfg$exposure_label[i]
  accession <- cfg$accession[i]
  url <- cfg$url[i]

  outfile <- file.path(
    "data/exposures_full",
    paste0(exposure_id, "_", accession, ".h.tsv.gz")
  )

  logfile <- file.path("logs", paste0("download_", exposure_id, ".log"))

  cat("\n============================================\n")
  cat("Exposure:", label, "\n")
  cat("Accession:", accession, "\n")
  cat("URL:", url, "\n")
  cat("Output:", outfile, "\n")
  cat("============================================\n")

  if (file.exists(outfile) && file.info(outfile)$size > 0) {
    cat("Already exists. Skipping download.\n")
    print(file.info(outfile)[, c("size", "mtime")])
    next
  }

  cmd <- sprintf(
    "wget -O %s %s 2>&1 | tee %s",
    shQuote(outfile),
    shQuote(url),
    shQuote(logfile)
  )

  status <- system(cmd)

  if (status != 0) {
    warning("Download failed for ", exposure_id, ". See: ", logfile)
    next
  }

  if (!file.exists(outfile) || file.info(outfile)$size == 0) {
    warning("Downloaded file missing or empty for ", exposure_id)
    next
  }

  cat("Downloaded successfully:\n")
  print(file.info(outfile)[, c("size", "mtime")])
}
