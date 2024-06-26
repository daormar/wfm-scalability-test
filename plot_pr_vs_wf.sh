if [ $# -ne 3 ]; then
    echo "Usage: plot_proc_vs_workflow <results_basedir> <toolname> <num_procs>"
    exit 0
fi

# Get parameters
results_basedir=$1
toolname=$2
num_procs=$3

# Initialize variables for different directories
pkgdir="$(cd "$(dirname "$0")" && pwd)"
resultsdir="${pkgdir}/results/plot_pr_vs_wf_expers"

# Create results directory
mkdir -p "${resultsdir}"

# Generate temporary file with n value experiments data
tmpfile=`mktemp`
find "${results_basedir}" -name "time.out" -exec awk -v toolname=$toolname -v num_procs=$num_procs '{if($1==toolname && $3==num_procs) printf"%s\n",$0}' {} \; > "${tmpfile}"

# Generate csv file
python "${pkgdir}/utils/gen_pr_vs_wf_expers_data.py" "${tmpfile}" > "${resultsdir}/pr_vs_wf_expers_data_unsorted.csv"

# Sort csv file
(head -n 1 "${resultsdir}/pr_vs_wf_expers_data_unsorted.csv" && tail -n +2 "${resultsdir}/pr_vs_wf_expers_data_unsorted.csv" | sort -t, -k1,1n) > "${resultsdir}/pr_vs_wf_expers_data.csv"

# Generate plot
cp "${pkgdir}/utils/pr_vs_wf_expers.gp" "${resultsdir}"
pushd "${resultsdir}"
gnuplot "pr_vs_wf_expers.gp"
popd

# Remove tmp file
rm "${tmpfile}"
