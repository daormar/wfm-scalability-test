get_n_values()
{
    local expertype=$1

    case ${expertype} in
        "host_process")
#            echo "1 10 100"
            echo "10"
            ;;
        "host_workflow")
            echo "1 10 100"
            ;;
    esac
}

extract_process_dist_data()
{
    local resultsdir=$1

    find "${resultsdir}"/toil_out -name "*.txt" -exec cat {} \; | sort | uniq -c
}

if [ $# -ne 1 ]; then
    echo "Usage: toil_wdl_n_exper <num_procs>"
    exit 0
fi

# Get number of processors parameter
num_procs=$1

# Set toolname variable
toolname="toil_wdl"

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
#for expertype in "host_process" "host_workflow"; do
for expertype in "host_process"; do
    echo "Experiment type: $expertype" >&2
    pfile="/home/dortiz/bio/software/debasher/examples/programs/debasher_${expertype}_expl_deps.sh"
    n_values=$(get_n_values "$expertype")
    for n in $n_values; do
        echo "n= $n ..." >&2

        # Define experiment directory
        resultsdir="${baseresultsdir}/${expertype}/n_$n"
        if [ -d  "${resultsdir}" ]; then
            rm -rf "${resultsdir}"
        fi
        mkdir -p "${resultsdir}"
        mkdir -p "${resultsdir}/toil_out"
        mkdir -p "${resultsdir}/toil_executions"

        # Generate yml file
        sed "s/NTASKS/${n}/" "${infdir}/wdl_input_template.${expertype}.json" > "${resultsdir}/input.json"
	sed -i "s/LOG1/host1_tasks${tasks}.txt/" "${resultsdir}/input.json"
	sed -i "s/LOG2/host2_tasks${tasks}.txt/" "${resultsdir}/input.json"

        # Execute experiment
        pushd "${resultsdir}"
        conda activate toil
        /bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" toil-wdl-runner "${infdir}/${expertype}".wdl "${resultsdir}/input.json" --batchSystem slurm --outputDirectory toil_out --jobStore myStore > "${resultsdir}/${toolname}.log" 2>&1
        conda deactivate
        popd

        # Extract time and memory data
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

        # NOTE: Node distribution data cannot be obtained correctly
        # since apparently toil is not executing the workflow processes
        # in the native OS (perhaps it uses some sort of container?). In
        # any case, the required code is included below
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

        # Extract process distribution data
        extract_process_dist_data "${resultsdir}" > "${resultsdir}/distrib.out"

        # Calculate Pearson's correlation coefficient
        python "${pkgdir}/utils/pearson.py" "${num_procs}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.r"
    done
    echo "" >&2
done

# Restore directory
popd
