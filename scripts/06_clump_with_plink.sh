#!/usr/bin/env bash
set -euo pipefail

source config/local_paths.sh

mkdir -p data/exposure_clumped
mkdir -p logs

if [ ! -x "${PLINK2_BIN}" ]; then
  echo "PLINK2_BIN is not executable: ${PLINK2_BIN}"
  echo "Edit config/local_paths.sh"
  exit 1
fi

if [ ! -f "${REF_BFILE}.bed" ] || [ ! -f "${REF_BFILE}.bim" ] || [ ! -f "${REF_BFILE}.fam" ]; then
  echo "Reference panel not found for REF_BFILE=${REF_BFILE}"
  echo "Expected files:"
  echo "${REF_BFILE}.bed"
  echo "${REF_BFILE}.bim"
  echo "${REF_BFILE}.fam"
  echo "Edit config/local_paths.sh"
  exit 1
fi

shopt -s nullglob
files=(data/exposure_gws/*_for_clump.tsv)

if [ ${#files[@]} -eq 0 ]; then
  echo "No clump input files found in data/exposure_gws/"
  echo "Run: Rscript scripts/05_extract_gws.R"
  exit 1
fi

for f in "${files[@]}"
do
  id=$(basename "${f}" _for_clump.tsv)

  echo ""
  echo "============================================"
  echo "Clumping: ${id}"
  echo "Input: ${f}"
  echo "============================================"

  out_prefix="data/exposure_clumped/${id}"

  # First try PLINK2-style field options.
  set +e
  "${PLINK2_BIN}" \
    --bfile "${REF_BFILE}" \
    --clump "${f}" \
    --clump-id-field SNP \
    --clump-p-field P \
    --clump-p1 5e-8 \
    --clump-r2 0.001 \
    --clump-kb 10000 \
    --out "${out_prefix}" \
    > "logs/clump_${id}.log" 2>&1

  status=$?
  set -e

  if [ ${status} -ne 0 ]; then
    echo "PLINK2-style clump options failed. Trying PLINK1-style options..."

    set +e
    "${PLINK2_BIN}" \
      --bfile "${REF_BFILE}" \
      --clump "${f}" \
      --clump-snp-field SNP \
      --clump-field P \
      --clump-p1 5e-8 \
      --clump-r2 0.001 \
      --clump-kb 10000 \
      --out "${out_prefix}" \
      >> "logs/clump_${id}.log" 2>&1

    status=$?
    set -e

    if [ ${status} -ne 0 ]; then
      echo "Clumping failed for ${id}. See logs/clump_${id}.log"
      exit 1
    fi
  fi

  echo "Clumping done for ${id}"
  ls -lh data/exposure_clumped/${id}* || true
done
