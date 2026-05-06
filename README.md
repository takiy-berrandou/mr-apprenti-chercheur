# Educational Mendelian Randomization project

Goal:
Prepare a simple Mendelian Randomization demonstration for students using SCAD as outcome.

Main workflow:
1. Download GWAS summary statistics.
2. Extract genome-wide significant variants for each exposure.
3. LD-clump instruments using a local reference panel.
4. Harmonise exposure and SCAD summary statistics.
5. Run TwoSampleMR.
6. Generate a lightweight Colab notebook for students.

Raw GWAS files are not pushed to GitHub.
Only small harmonised files and the notebook are pushed.
