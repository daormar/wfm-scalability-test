if [ $# -ne 5 ]; then
    echo "Usage: nextflow_record <qsize> <mforks> <expertype> <n> <array_size>"
    exit 0
fi

# Get parameters
qsize=$1
mforks=$2
expertype=$3
n=$4
array_size=$5

# Set toolname variable
toolname="nextflow"

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
nextflowdir="${pkgdir}/software"
infdir="${pkgdir}/input_files/${toolname}"
resultsdir="${pkgdir}/results/${toolname}_${array_size}_record"

# Create results directory
if [ -d "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"

# Generate yml file
tmpfile=`mktemp`
sed "s/QSIZE/${qsize}/" "${infdir}/nf_cfg_template" > "${tmpfile}"
sed "s/MFORKS/${mforks}/" "${tmpfile}" > "${resultsdir}/cfg"
rm "${tmpfile}"

# Generate nf file
if [ "${array_size}" -eq 0 ]; then
    sed "s/ARRAY//" "${infdir}/${expertype}.nf" > "${resultsdir}/workflow.nf"
else
    sed "s/ARRAY/array ${array_size}/" "${infdir}/${expertype}.nf" > "${resultsdir}/workflow.nf"
fi

# Change directory
pushd "${pkgdir}"

# Execute experiment
pushd "${resultsdir}"
"${nextflowdir}"/nextflow -q run "${resultsdir}/workflow.nf" -c "${resultsdir}/cfg" -profile cluster --ntasks=${n} > "${resultsdir}/${toolname}.log" 2>&1 &
pid=$!
popd

# Execute psrecord
psrecord "${pid}" --interval 1 --log "${resultsdir}/${toolname}_record.txt" --plot "${resultsdir}/${toolname}_record.png"

wait "${pid}"

# Restore directory
popd
