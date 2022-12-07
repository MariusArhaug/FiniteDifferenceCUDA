echo
echo "Comparing serial solution with reference data"
echo "-----------------------------------------------------------"
echo "Grid size: 16, Max iteration: 5000, Snapshot frequency: 40"
echo
./serial_cu -n16 1>/dev/null
./check/compare_solutions 16 data/00001.bin check/references/n16/00001.bin
echo "-----------------------------------------------------------"
echo "Grid size: 128, Max iteration: 5000, Snapshot frequency: 40"
echo
./serial_cu -n128 1>/dev/null
./check/compare_solutions 128 data/00001.bin check/references/n128/00001.bin
echo
