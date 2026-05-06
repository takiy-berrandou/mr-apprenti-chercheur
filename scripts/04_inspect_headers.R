suppressPackageStartupMessages({
  library(data.table)
})

cat("\n================ SCAD ================\n")
outcome_cfg <- fread("config/outcome_scad.tsv")
scad_file <- outcome_cfg$outcome_file[1]

if (file.exists(scad_file)) {
  x <- fread(scad_file, nrows = 5)
  cat("File:", scad_file, "\n")
  cat("Size:", round(file.info(scad_file)$size / 1024^2, 1), "MB\n")
  print(names(x))
  print(x)
} else {
  cat("SCAD file missing:", scad_file, "\n")
}

cat("\n================ EXPOSURES ================\n")

files <- list.files(
  "data/exposures_full",
  pattern = "\\.tsv\\.gz$",
  full.names = TRUE
)

if (length(files) == 0) {
  cat("No exposure files found in data/exposures_full/\n")
} else {
  for (f in files) {
    cat("\n--------------------------------------------\n")
    cat("File:", f, "\n")
    cat("Size:", round(file.info(f)$size / 1024^2, 1), "MB\n")
    x <- fread(f, nrows = 5)
    print(names(x))
    print(x)
  }
}
