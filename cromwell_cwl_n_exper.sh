extract_process_dist_data()
{
    local resultsdir=$1

    find "${resultsdir}/cromwell-executions" -name "*tasks.txt" -exec cat {} \; | sort | uniq -c
}

if [ $# -ne 3 ]; then
    echo "Usage: cromwell_cwl_n_exper <num_procs> <expertype> <n>"
    exit 0
fi

# Get number of processors parameter
num_procs=$1
expertype=$2
n=$3

# Set toolname variable
toolname="cromwell_cwl"

# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Initialize variables for different directories
cromwelldir="${pkgdir}/software"
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

# Generate conf file
sed "s/CORES/${num_procs}/" "${infdir}/backend.conf" > "${resultsdir}/backend.conf"

# Generate yml file
sed "s/NTASKS/${n}/" "${infdir}/cwl_input_template.yml" > "${resultsdir}/input.yml"
sed -i "s/LOG1/host1_tasks${tasks}.txt/" "${resultsdir}/input.yml"
sed -i "s/LOG2/host2_tasks${tasks}.txt/" "${resultsdir}/input.yml"

# Execute experiment
pushd "${resultsdir}"
/bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" java -Dconfig.file="${resultsdir}/backend.conf" -jar "${cromwelldir}/cromwell-79.jar" run "${infdir}/${expertype}.cwl" -i "${resultsdir}/input.yml" --type cwl -o "${infdir}/cwl_workflow.options.json" > "${resultsdir}/${toolname}.log" 2>&1
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
