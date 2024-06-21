extract_process_dist_data()
{
    local resultsdir=$1

    cat "${resultsdir}"/toil_out/* | sort | uniq -c
}

if [ $# -ne 3 ]; then
    echo "Usage: toil_cwl_n_exper <num_procs> <expertype> <n>"
    exit 0
fi

# Get number of processors parameter
num_procs=$1
expertype=$2
n=$3

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
pfile="/home/dortiz/bio/software/debasher/examples/programs/debasher_${expertype}_expl_deps.sh"
echo "n= $n ..." >&2

# Define experiment directory
resultsdir="${baseresultsdir}/${expertype}/n_$n"
if [ -d  "${resultsdir}" ]; then
    rm -rf "${resultsdir}"
fi
mkdir -p "${resultsdir}"
mkdir -p "${resultsdir}/toil_executions"

# Generate yml file
sed "s/NTASKS/${n}/" "${infdir}/cwl_input_template.yml" > "${resultsdir}/input.yml"
sed -i "s/LOG1/host1_tasks${tasks}.txt/" "${resultsdir}/input.yml"
sed -i "s/LOG2/host2_tasks${tasks}.txt/" "${resultsdir}/input.yml"

# Execute experiment
pushd "${resultsdir}"
conda activate toil
/bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" toil-cwl-runner --jobStore myStore --batchSystem slurm --outdir toil_out --workDir toil_executions --maxCores $n --disableCaching "${infdir}/${expertype}.cwl" "${resultsdir}/input.yml" > "${resultsdir}/${toolname}.log" 2>&1
conda deactivate
popd

# Extract time and memory data
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

# Extract process distribution data
extract_process_dist_data "${resultsdir}" > "${resultsdir}/distrib.out"

# Calculate Pearson's correlation coefficient
python "${pkgdir}/utils/pearson.py" "${num_procs}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.r"
echo "" >&2

# Restore directory
popd
