if [ $# -ne 4 ]; then
    echo "Usage: nextflow_record <qsize> <mforks> <expertype> <n>"
    exit 0
fi

# Get parameters
qsize=$1
mforks=$2
expertype=$3
n=$4

# Set toolname variable
toolname="nextflow"

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
nextflowdir="${pkgdir}/software"
infdir="${pkgdir}/input_files/${toolname}"
resultsdir="${pkgdir}/results/${toolname}_record"

# Create results directory
if [ -d "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"

# Generate yml file
sed "s/QSIZE/${qsize}/" "${infdir}/nf_cfg_template" > "${resultsdir}/cfg"
sed -i "s/MFORKS/${mforks}/" "${resultsdir}/cfg"

# Change directory
pushd "${pkgdir}"

# Execute experiment
pushd "${resultsdir}"
"${nextflowdir}"/nextflow -q run "${infdir}/${expertype}.nf" -c "${resultsdir}/cfg" -profile cluster --ntasks=${n} > "${resultsdir}/${toolname}.log" 2>&1 &
pid=$!
popd

# Execute psrecord
psrecord "${pid}" --interval 1 --log "${resultsdir}/${toolname}_record.txt" --plot "${resultsdir}/${toolname}_record.png"

wait "${pid}"

# Restore directory
popd
