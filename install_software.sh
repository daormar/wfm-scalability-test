# Get the directory where the package is stored
pkgdir="$(cd "$(dirname "$0")" && pwd)"

# Change directory
pushd "${pkgdir}"

# Create software directory
mkdir -p software

# Install the different software packages
pushd software

## Installing debasher
echo "Installing DeBasher..." >&2
git clone git@github.com:daormar/debasher.git
pushd debasher
./reconf > reconf.log 2>&1
./configure --prefix="$PWD"/ > configure.log 2>&1
make > make.log 2>&1
make install > make_install.log 2>&1
popd
echo "" >&2

## Installing cromwell
echo "Installing Cromwell..." >&2
wget https://github.com/broadinstitute/cromwell/releases/download/86/cromwell-86.jar > cromwell_86.log 2>&1
wget https://github.com/broadinstitute/cromwell/releases/download/79/cromwell-79.jar > cromwell_79.log 2>&1
echo "" >&2

## Installing toil
echo "Installing Toil..." >&2
conda create -y -n toil bioconda::toil
echo "" >&2

## Installing nextflow
echo "Installing Nextflow..." >&2
curl -s https://get.nextflow.io | bash > nextflow.log 2>&1
echo "" >&2

# Restore directory
popd
popd
