if [ $# -ne 3 ]; then
    echo "Usage: plot_n_expers <results_basedir> <expertype> <num_procs>"
    exit 0
fi

# Get parameters
results_basedir=$1
expertype=$2
num_procs=$3

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/plot_n_expers"

# Create results directory
mkdir -p "${resultsdir}"

# Generate temporary file with n value experiments data
tmpfile=`mktemp`
find "${results_basedir}" -name "time.out" -exec awk '{printf"%s\n",$0}' {} \; | grep "${expertype} ${num_procs}" > "${tmpfile}"
cat $tmpfile
# Generate csv file
python "${pkgdir}/utils/gen_n_expers_data.py" "${tmpfile}" > "${resultsdir}/n_expers_data_unsorted.csv"

# Sort csv file
(head -n 1 "${resultsdir}/n_expers_data_unsorted.csv" && tail -n +2 "${resultsdir}/n_expers_data_unsorted.csv" | sort -t, -k1,1n) > "${resultsdir}/n_expers_data.csv"

# Generate plot
cp "${pkgdir}/utils/n_expers.gp" "${resultsdir}"
pushd "${resultsdir}"
gnuplot "n_expers.gp"
popd

# Remove tmp file
rm "${tmpfile}"
