repos <- c(
  "https://mrcieu.r-universe.dev",
  "https://cloud.r-project.org"
)

pkgs <- c(
  "data.table",
  "dplyr",
  "ggplot2",
  "TwoSampleMR"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = repos)
  }
}

cat("Package versions:\n")
for (p in pkgs) {
  cat(p, as.character(packageVersion(p)), "\n")
}
