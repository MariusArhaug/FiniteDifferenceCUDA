echo "------------------------------------------------------------"
echo "Benchmark small size"
echo "Grid size: 32, Max iteration: 5000, Snapshot frequency: 40"
echo "------------------------------------------------------------------"
echo "Serial"
time ./serial -n 32 1>/dev/null
echo
echo "CUDA"
time ./parallel -n 32 1>/dev/null
echo
echo "------------------------------------------------------------"
echo "Benchmark medium size"
echo "Grid size: 128, Max iteration: 5000, Snapshot frequency: 40"
echo "------------------------------------------------------------------"
echo "Serial"
time ./serial -n 128 1>/dev/null
echo
echo "CUDA"
time ./parallel -n 128 1>/dev/null
echo
echo
echo "------------------------------------------------------------"
echo "Benchmark large size"
echo "Grid size: 256, Max iteration: 5000, Snapshot frequency: 40"
echo "------------------------------------------------------------------"
echo "Serial"
time ./serial -n 256 1>/dev/null
echo
echo "CUDA"
time ./parallel -n 256 1>/dev/null
echo
echo "------------------------------------------------------------"
echo "Benchmark very large size"
echo "Grid size: 512, Max iteration: 5000, Snapshot frequency: 40"
echo "------------------------------------------------------------------"
echo "Serial"
time ./serial -n 512 1>/dev/null
echo
echo "CUDA"
time ./parallel -n 512 1>/dev/null
echo
