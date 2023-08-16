#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo $SCRIPT_DIR
echo "What version of namada do you want to use?"
echo "The latest version available is:"
curl -sL https://api.github.com/repos/anoma/namada/releases/latest | jq -r ".tag_name"

read -p "Enter a version (ex. 0.1.0): " NAMADA_VERSION

# Check if the version is provided
if [ -z "$NAMADA_VERSION" ]
then
    echo "Please provide the version of the binaries to download in the format x.y.z"
    exit 1
fi
# Attempt to download the binaries
echo "Downloading namada binaries v$NAMADA_VERSION"
$SCRIPT_DIR/utils/download_binaries.sh
download_namada_binaries $NAMADA_VERSION

echo "Downloading cometbft binaries"
download_cometbft_binaries