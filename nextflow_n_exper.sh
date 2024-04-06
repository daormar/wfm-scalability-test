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
    local logfile=$1

    grep "hostname_" "${logfile}" | awk '{print $NF}' | sort | uniq -c
}

if [ $# -ne 3 ]; then
    echo "Usage: nextflow_n_exper <qsize> <mforks> <num_procs>"
    exit 0
fi

# Get number of processors parameter
qsize=$1
mforks=$2
num_procs=$3

# Set toolname variable
toolname="nextflow"

# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Initialize variables for different directories
nextflowdir="${pkgdir}/software"
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

        # Generate yml file
        sed "s/QSIZE/${qsize}/" "${infdir}/nf_cfg_template" > "${resultsdir}/cfg"
        sed "s/MFORKS/${mforks}/" "${resultsdir}/cfg"

        # Execute experiment
        pushd "${resultsdir}"
        /bin/time -f "%e %M" -o "${resultsdir}/time_command_$n" "${nextflowdir}"/nextflow -q run "${infdir}/${expertype}.nf" -c "${resultsdir}/cfg" -profile cluster --ntasks=${n} > "${resultsdir}/${toolname}.log" 2>&1
        popd

        # Extract time and memory data
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $1}' "${resultsdir}/time_command_$n" > "${resultsdir}/time.out"
        awk -v tool="${toolname}" -v expertype="${expertype}" -v num_procs=$num_procs -v n=$n '{printf "%s %s %d %d %s", tool, expertype, num_procs, n, $2}' "${resultsdir}/time_command_$n" > "${resultsdir}/mem.out"

        # Extract process distribution data
        extract_process_dist_data "${resultsdir}/${toolname}.log" > "${resultsdir}/distrib.out"

        # Calculate Pearson's correlation coefficient
        python "${pkgdir}/utils/pearson.py" "${num_procs}" "${resultsdir}/distrib.out" > "${resultsdir}/distrib.r"
    done
    echo "" >&2
done

# Restore directory
popd
