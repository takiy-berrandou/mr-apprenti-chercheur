#!/usr/bin/env bash
set -euo pipefail

Rscript scripts/01_install_packages.R
Rscript scripts/02_download_scad.R
Rscript scripts/03_make_and_download_exposure_urls.R
Rscript scripts/04_inspect_headers.R
Rscript scripts/05_extract_gws.R

echo ""
echo "Pipeline paused before clumping."
echo "Next step:"
echo "1. Edit config/local_paths.sh"
echo "2. Run: bash scripts/06_clump_with_plink.sh"
