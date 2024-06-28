if [ $# -ne 1 ]; then
    echo "Usage: plot_cpu_evol <results_basedir>"
    exit 0
fi

# Get parameters
results_basedir=$1
expertype=$2
num_procs=$3

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/plot_cpu_evol"

# Create results directory
mkdir -p "${resultsdir}"

# Generate temporary file with n value experiments data
find "${results_basedir}" -name "*record.txt" -exec cp {} "${resultsdir}" \;

# Generate plot
cp "${pkgdir}/utils/cpu_evol_template.gp" "${resultsdir}/cpu_evol.gp"
pushd "${resultsdir}"
i=1
plot_command="plot "
for file in "${resultsdir}"/*record.txt; do
    basefile="$(basename $file)"
    basefile_corrected="$(basename $file).corrected"
    awk '{if($2 < 0.0001) $2=0.0001; print $0}' "$file" > "${basefile_corrected}"
    if [ "$i" -eq 1 ]; then
        sep=""
    else
        sep=","
    fi
    plot_command="${plot_command} ${sep} \"${basefile_corrected}\" using 1:2 with lines linestyle ${i} title '${basefile}'"
    i=$((i + 1))
done

echo "${plot_command}" >> "${resultsdir}/cpu_evol.gp"

gnuplot "cpu_evol.gp"
popd
