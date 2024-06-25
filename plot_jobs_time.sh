get_n_val()
{
    local expertype=$1
    local n_par=$2
    local n_val
    if [ "${expertype}" = "host_process" ]; then
        n_val=$n_par
    else
        n_val=$((2 * n_par))
    fi

    echo "${n_val}"
}

if [ $# -ne 4 ]; then
    echo "Usage: plot_jobs_time <results_basedir> <expertype> <num_procs> <n_par>"
    exit 0
fi

# Get parameters
results_basedir=$1
expertype=$2
num_procs=$3
n_par=$4
n=$(get_n_val "${expertype}" "${n_par}")

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/plot_jobs_time"

# Create results directory
mkdir -p "${resultsdir}"

# Generate temporary file with n value experiments data
tmpfile=`mktemp`
find "${results_basedir}" -name "time.out" -exec awk '{printf"%s\n",$0}' {} \; | grep "${expertype} ${num_procs} ${n}" > "${tmpfile}"

# Generate csv file
python "${pkgdir}/utils/gen_jobs_time_expers_data.py" "${tmpfile}" > "${resultsdir}/jobs_time_expers_data.csv"

# Generate plot
cp "${pkgdir}/utils/jobs_time_expers.gp" "${resultsdir}"
pushd "${resultsdir}"
gnuplot "jobs_time_expers.gp"
popd

# Remove tmp file
rm "${tmpfile}"
