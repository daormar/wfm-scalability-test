extract_process_dist_data()
{
    local resultsdir=$1

    cat "${resultsdir}"/toil_out/* | sort | uniq -c
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
    local njobs

    if [ "${expertype}" = "host_process" ]; then
        njobs=$n_par
    else
        njobs=$((2 * n_par))
    fi

    echo "${njobs}"
}

if [ $# -ne 4 ]; then
    echo "Usage: toil_cwl_n_exper <num_nodes> <num_procs> <expertype> <n_par>"
    exit 0
fi

# Initialize variables
num_nodes=$1
num_procs=$2
expertype=$3
n_par=$4
n=$(get_n_val "${expertype}" "${n_par}")
njobs=$(get_num_jobs "${expertype}" "${n_par}")
max_mem=1024M

# Set toolname variable
toolname="toil_cwl"

# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Initialize variables for different directories
infdir="${pkgdir}/input_files/${toolname}"
baseresultsdir="${pkgdir}/results/n_values/${toolname}"

# Change directory
pushd "${pkgdir}"

# Create results directory
mkdir -p "${baseresultsdir}"

# Iterate over different values of n
echo "Experiment type: $expertype" >&2
echo "n= $n ..." >&2

# Define experiment directory
resultsdir="${baseresultsdir}/${expertype}/n_$n"
if [ -d  "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"
mkdir -p "${resultsdir}/toil_executions"

# Generate yml file
sed "s/NTASKS/${n_par}/" "${infdir}/cwl_input_template.yml" > "${resultsdir}/input.yml"
sed -i "s/LOG1/host1_tasks${tasks}.txt/" "${resultsdir}/input.yml"
sed -i "s/LOG2/host2_tasks${tasks}.txt/" "${resultsdir}/input.yml"

# Execute experiment
pushd "${resultsdir}"
conda activate toil
/bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" toil-cwl-runner --jobStore myStore --batchSystem slurm --outdir toil_out --workDir toil_executions --maxCores $n --maxMemory $max_mem --disableCaching "${infdir}/${expertype}.cwl" "${resultsdir}/input.yml" > "${resultsdir}/${toolname}.log" 2>&1
conda deactivate
popd

# Extract time and memory data
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n -v njobs=$njobs '{printf "%s %s %d %d %d %s", tool, expertype, num_procs, n, njobs, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n -v njobs=$njobs '{printf "%s %s %d %d %d %s", tool, expertype, num_procs, n, njobs, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

# Extract process distribution data
extract_process_dist_data "${resultsdir}" > "${resultsdir}/distrib.out"

# Calculate deviation from optimal values
python "${pkgdir}/utils/calc_deviation.py" "${num_nodes}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.dev"
echo "" >&2

# Restore directory
popd
