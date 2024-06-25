extract_process_dist_data()
{
    local logfile=$1

    grep "hostname_" "${logfile}" | awk '{print $NF}' | sort | uniq -c
}

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

get_num_jobs()
{
    local expertype=$1
    local n_par=$2
    local array_size=$3
    local njobs

    if [ "${array_size}" -eq 0 ]; then
        array_size=1
    fi

    if [ "${expertype}" = "host_process" ]; then
        njobs=$(echo "" | awk -v n_par=$n_par -v array_size=$array_size '{printf"%d", 1*(n_par/array_size)}')
    else
        njobs=$(echo "" | awk -v n_par=$n_par -v array_size=$array_size '{printf"%d", 2*(n_par/array_size)}')
    fi

    echo "${njobs}"
}

if [ $# -ne 7 ]; then
    echo "Usage: nextflow_n_exper <qsize> <mforks> <num_nodes> <num_procs> <expertype> <n_par> <array_size>"
    exit 0
fi

# Initialize variables
qsize=$1
mforks=$2
num_nodes=$3
num_procs=$4
expertype=$5
n_par=$6
n=$(get_n_val "${expertype}" "${n_par}")
array_size=$7
njobs=$(get_num_jobs "${expertype}" "${n_par}" "${array_size}")

# Set toolname variable
toolname="nextflow"

# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Initialize variables for different directories
nextflowdir="${pkgdir}/software"
infdir="${pkgdir}/input_files/${toolname}"
baseresultsdir="${pkgdir}/results/n_values/${toolname}_${array_size}"

# Change directory
pushd "${pkgdir}"

# Create results directory
mkdir -p "${baseresultsdir}"

# Execute experiment for n
echo "Experiment type: $expertype" >&2
echo "n= $n ..." >&2

# Define experiment directory
resultsdir="${baseresultsdir}/${expertype}/n_$n"
if [ -d  "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"

# Generate cfg file
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

# Execute experiment
pushd "${resultsdir}"
/bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" "${nextflowdir}"/nextflow -q run "${resultsdir}/workflow.nf" -c "${resultsdir}/cfg" -profile cluster --ntasks=${n} > "${resultsdir}/${toolname}.log" 2>&1
popd

# Extract time and memory data
awk -v tool="${toolname}_${array_size}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n -v njobs=$njobs '{printf "%s %s %d %d %d %s", tool, expertype, num_procs, n, njobs, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
awk -v tool="${toolname}_${array_size}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n -v njobs=$njobs '{printf "%s %s %d %d %d %s", tool, expertype, num_procs, n, njobs, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

# Extract process distribution data
extract_process_dist_data "${resultsdir}/${toolname}.log" > "${resultsdir}/distrib.out"

# Calculate deviation from optimal values
python "${pkgdir}/utils/calc_deviation.py" "${num_nodes}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.dev"
echo "" >&2

# Restore directory
popd
