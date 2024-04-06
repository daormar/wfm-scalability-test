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

# Generate csv file
python "${pkgdir}/utils/gen_n_expers_data.py" "${tmpfile}" > "${pkgdir}/n_expers_data.csv"

# Generate plot
gnuplot "${pkgdir}/utils/n_expers.gp"

# Move files
mv "${pkgdir}/n_expers_data.csv" "${resultsdir}"
mv "${pkgdir}/n_expers_plot.png" "${resultsdir}"

# Remove tmp file
rm "${tmpfile}"
