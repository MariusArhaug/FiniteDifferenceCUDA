help()
{
    echo
    echo "Plot 2D shallow water equations"
    echo
    echo "Syntax"
    echo "---------------------------------------------"
    echo "./plot_solution.sh [-n|h]                    "
    echo
    echo "Option    Description     Arguments   Default"
    echo "---------------------------------------------"
    echo "n         Grid size       Optional    256    "
    echo "h         Help            None               "
    echo
    echo "Example"
    echo "---------------------------------------------"
    echo "./plot_solution.sh -n 256                    "
    echo
}

#-----------------------------------------------------------------
set -e

N=256

while getopts ":n:h" opt; do
    case $opt in
        n)
            N=$OPTARG;;
        h)
            help
            exit;;
        \?)
            echo "Invalid option"
            help
            exit;;
    esac
done

#-----------------------------------------------------------------
SIZE=`echo $N | bc`

for FILE in `ls data/*.bin`
do
OUTFILE=`echo $FILE | sed s/^data/plots/ |  sed s/\.bin/.png/`
cat <<END_OF_SCRIPT | gnuplot -
set term png
set output "$OUTFILE"
set zrange [0.9:1.1]
set cbrange [0.95:1.0]
set palette defined (0 "grey", 1 "blue", 2 "white")
splot "$FILE" binary array=${SIZE}x${SIZE} format='%double' with pm3d
END_OF_SCRIPT
echo $OUTFILE
done
