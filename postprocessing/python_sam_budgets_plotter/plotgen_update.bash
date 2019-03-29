#!/usr/bin/bash

# Loop script for updating all plots generated by plotgen_main.py
### Description of choices:
## Plot variables
# 1: CLUBB budgets
# 2: SAM 3D plots
# 3: CLUBB standalone
# 4: SAM budgets
# 5: SAM correlations and covariances (not implemented)
# 6: SAM CLUBB comparison
# 7: SAM standalone

## Cases
# 1: BOMEX 128x128
# 2: BOMEX 64x64
# 3: LBA
# 4: RICO
# 5: DYCOMS_RF01
# 6: DYCOMS_RF02

# Define loop entries
caseopts=(1 2 3 4 5 6)
# Comparison plots have to be treated separately as they require additional input
varopts=(1 3 4 5 7)
compinput=("y" "n")

# Loop over variable cases
# for vars in ${varopts[@]}
# do
#   # Loop over setup cases
#   for case in ${caseopts[@]}
#   do
#     echo "vars = $vars, case=$case"
#     python plotgen_main.py <<< "$vars
#     $case"
#   done
# done

# Generate comparison plots
# Loop over setup cases
# vars=6
# for case in ${caseopts[@]}
# do
#   echo "vars = $vars, case=$case"
#   python plotgen_main.py <<< "$vars
#   $case
# y"
# done

# Generate horizontal plots
# Loop over setup cases
vars=2
for ((i=1;i<=2;i++ ))
do
  for case in ${caseopts[@]}
  do
    echo "vars = $vars, case=$case"
    python plotgen_main.py <<< "$vars
    $case
    $i"
  done
done
