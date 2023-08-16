l#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Access the command_exists function
. $SCRIPT_DIR/utils/ledger_commands.sh

# Directory of the namada binaries
NAMADA_BIN_DIR="$(which namada | xargs dirname)"
echo "NAMADA_BIN_DIR: $NAMADA_BIN_DIR"
echo "This will setup a bunch of keys and addresses for you to use in the tutorial"
basic_init
