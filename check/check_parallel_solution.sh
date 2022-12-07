echo
echo "Comparing CUDA solution with reference data"
echo "-----------------------------------------------------------"
echo "Grid size: 16, Max iteration: 5000, Snapshot frequency: 40"
echo
./parallel_ad -n16 1>/dev/null
./check/compare_solutions 16 data/00050.bin check/references/n16/00050.bin
echo "-----------------------------------------------------------"
echo "Grid size: 32, Max iteration: 5000, Snapshot frequency: 40"
echo
./parallel_ad -n32 1>/dev/null
./check/compare_solutions 32 data/00050.bin check/references/n32/00050.bin
echo
echo "-----------------------------------------------------------"
echo "Grid size: 50, Max iteration: 5000, Snapshot frequency: 40"
echo
./parallel_ad -n50 1>/dev/null
./check/compare_solutions 50 data/00050.bin check/references/n50/00050.bin
echo
echo "-----------------------------------------------------------"
echo "Grid size: 128, Max iteration: 5000, Snapshot frequency: 40"
echo
./parallel_ad -n128 1>/dev/null
./check/compare_solutions 128 data/00050.bin check/references/n128/00050.bin
echo
