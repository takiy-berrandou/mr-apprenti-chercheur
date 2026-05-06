#!/usr/bin/env bash
set -euo pipefail

Rscript scripts/07_make_instruments_from_clumps.R
Rscript scripts/08_harmonise_with_scad.R
Rscript scripts/09_test_mr.R
python scripts/10_generate_colab_notebook.py

echo ""
echo "Pipeline complete."
echo "Check:"
echo "  data/harmonised/"
echo "  results/"
echo "  notebooks/MR_educatif_SCAD.ipynb"
