if [ $# -ne 1 ]; then
    echo "Usage: plot_mem_evol <results_basedir>"
    exit 0
fi

# Get parameters
results_basedir=$1
expertype=$2
num_procs=$3

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/plot_mem_evol"

# Create results directory
mkdir -p "${resultsdir}"

# Generate temporary file with n value experiments data
find "${results_basedir}" -name "*record.txt" -exec cp {} "${resultsdir}" \;

# Generate plot
cp "${pkgdir}/utils/mem_evol_template.gp" "${resultsdir}/mem_evol.gp"
pushd "${resultsdir}"
i=1
for file in "${resultsdir}"/*record.txt; do
    basefile="$(basename $file)"
    basefile_corrected="$(basename $file).corrected"
    awk '{if($2 < 0.0001) $2=0.0001; print $0}' "$file" > "${basefile_corrected}"
    if [ "$i" -eq 1 ]; then
        echo plot \"${basefile_corrected}\" using 1:3 with linespoints linestyle "${i}" title \'${basefile}\'\, "\\" >> "${resultsdir}/mem_evol.gp"
    else
        echo \"${basefile_corrected}\" using 1:3 with linespoints linestyle "${i}" title \'${basefile}\' >> "${resultsdir}/mem_evol.gp"
    fi

    i=$((i + 1))
done

gnuplot "mem_evol.gp"
popd
