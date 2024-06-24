extract_process_dist_data()
{
    local resultsdir=$1

    find "${resultsdir}/debasher_out/__exec__" -name "host?_*.stdout" -exec cat {} \; | awk '{print $NF}' | sort | uniq -c
}

if [ $# -ne 3 ]; then
    echo "Usage: debasher_n_exper <num_procs> <expertype> <n>"
    exit 0
fi

# Get number of processors parameter
num_procs=$1
expertype=$2
n=$3

# Set toolname variable
toolname="debasher"

# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Initialize variables for different directories
debasherdir="${pkgdir}/software/debasher"
baseresultsdir="${pkgdir}/results/n_values/${toolname}"

# Change directory
pushd "${pkgdir}"

# Create results directory
mkdir -p "${baseresultsdir}"

# Iterate over different values of n
echo "Experiment type: $expertype" >&2
pfile="${debasherdir}/examples/programs/debasher_${expertype}_expl_deps.sh"
echo "n= $n ..." >&2

# Define experiment directory
resultsdir="${baseresultsdir}/${expertype}/n_$n"
mkdir -p "${resultsdir}"

# Execute experiment
/bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" "${debasherdir}/bin/debasher_exec" '--pfile' "${pfile}" '--outdir' "${resultsdir}/debasher_out" '-n' ${n} '--sched' 'SLURM' '--builtinsched-cpus' '4' '--builtinsched-mem' '128' '--builtinsched-debug' '--conda-support' --wait > "${resultsdir}/${toolname}.log" 2>&1

# Extract time and memory data
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

# Extract process distribution data
extract_process_dist_data "${resultsdir}" > "${resultsdir}/distrib.out"

# Calculate deviation from optimal values
python "${pkgdir}/utils/calc_deviation.py" "${num_procs}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.dev"
echo "" >&2

# Restore directory
popd
