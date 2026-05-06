suppressPackageStartupMessages({
  library(data.table)
})

cfg <- fread("config/outcome_scad.tsv")

dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)

url <- cfg$url[1]
outfile <- cfg$outcome_file[1]

cat("SCAD URL:\n", url, "\n")
cat("Output:\n", outfile, "\n")

if (file.exists(outfile) && file.info(outfile)$size > 0) {
  cat("SCAD file already exists. Skipping download.\n")
  print(file.info(outfile)[, c("size", "mtime")])
} else {
  cmd <- sprintf(
    "wget -O %s %s 2>&1 | tee logs/download_scad.log",
    shQuote(outfile),
    shQuote(url)
  )
  status <- system(cmd)
  if (status != 0) {
    stop("SCAD download failed. See logs/download_scad.log")
  }
}

cat("\nInspecting SCAD header:\n")
x <- fread(outfile, nrows = 5)
print(names(x))
print(x)
