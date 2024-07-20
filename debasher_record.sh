if [ $# -ne 2 ]; then
    echo "Usage: debasher_record <expertype> <n_par>"
    exit 0
fi

# Get parameters
expertype=$1
n_par=$2

# Set toolname variable
toolname="debasher"

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/${toolname}_record"

# Create results directory
if [ -d "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"

# Initialize variables for different directories
debasherdir="${pkgdir}/software/debasher"

# Change directory
pushd "${pkgdir}"

# Execute experiment
pfile="${debasherdir}/examples/programs/debasher_${expertype}_medium.sh"
"${debasherdir}/bin/debasher_exec" '--pfile' "${pfile}" '--outdir' "${resultsdir}/${toolname}_out" '-n' ${n_par} '--sched' 'SLURM' '--builtinsched-cpus' '4' '--builtinsched-mem' '128' '--builtinsched-debug' '--conda-support' --wait > "${resultsdir}/${toolname}_record.log" 2>&1 &
pid=$!

# Execute psrecord
psrecord "${pid}" --interval 1 --log "${resultsdir}/${toolname}_record.txt" --plot "${resultsdir}/${toolname}_record.png"

wait "${pid}"

# Restore directory
popd
