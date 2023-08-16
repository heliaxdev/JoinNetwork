#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Access the command_exists function
. $SCRIPT_DIR/utils/command_not_found.sh

echo "This script will allow you to join a namada chain"

echo "What is the chain-id of the chain you want to join?"
read -p "Enter a chain-id: " CHAIN_ID

# TODO: Check if the chain-id is valid
# Check that the chain-id is a valid string that contains the word "internal-devnet" or "testnet"
if ! echo "$CHAIN_ID" | grep -qE 'internal-devnet|testnet';
then
    echo "Please provide a valid chain-id"
    exit 1
fi


echo "Do you have the respective namada binaries installed for this chain? (y/n)"
read -p "Enter (y/n): " HAS_BINARIES

if [ "$HAS_BINARIES" = "y" ]; then
    # Check if the binaries are in the PATH
    if ! command -v namada &> /dev/null
    then
        echo "Please provide the path to the folder containing the namada binaries"
        read -p "Enter the path: " NAMADA_BIN_DIR

        # Check if the path provided is a valid directory and contains the namada binaries
        if [ -d "$NAMADA_BIN_DIR" ] && [ -f "$NAMADA_BIN_DIR/namada" ] && [ -f "$NAMADA_BIN_DIR/namadac" ]
        then
            echo "The path provided is a valid directory and contains the namada binaries"
        else
            echo "The path provided is not a valid directory or does not contain the namada binaries"
            exit 1
        fi
    fi
    NAMADA_BIN_DIR=$(dirname $(which namada))
elif [ "$HAS_BINARIES" = "n" ]; then
    echo "Make sure you install the correct version of the namada binaries for the chain you want to join"
    read -p "Enter a version (ex. 0.1.0): " NAMADA_VERSION

    # Check if the version is provided
    if [ -z "$NAMADA_VERSION" ]
    then
        echo "Please provide the version of the binaries to download in the format x.y.z"
        exit 1
    fi
    # Attempt to download the binaries
    echo "Downloading namada binaries v$NAMADA_VERSION"
    . $SCRIPT_DIR/utils/download_binaries.sh
    download_namada_binaries $NAMADA_VERSION
    NAMADA_BIN_DIR="$SCRIPT_DIR/namada_binaries"
else
    echo "Please enter either y or n"
    exit 1
fi

echo "Do you have a custom base directory you would like to use? (y/n)"
read -p "Enter (y/n): " HAS_BASE_DIR

if [ "$HAS_BASE_DIR" = "y" ]; then
    echo "Please provide the path to the base directory"
    read -p "Enter the path: " BASE_DIR

    # Check if the path provided is a valid directory
    if [ -d "$BASE_DIR" ]
    then
        echo "The path provided is a valid directory"
    else
        echo "The path provided is not a valid directory"
        exit 1
    fi
elif [ "$HAS_BASE_DIR" = "n" ]; then
    echo "Using default base directory: $($NAMADA_BIN_DIR/namadac utils default-base-dir)"
    BASE_DIR=$($NAMADA_BIN_DIR/namadac utils default-base-dir)
else
    echo "Please enter either y or n"
    exit 1
fi

# Join the network

echo "Are you a genesis-validator? (y/n)"
read -p "Enter (y/n): " IS_GENESIS_VALIDATOR

if [ "$IS_GENESIS_VALIDATOR" = "y" ]; then
    echo "Please provide the alias of your genesis-validator"
    read -p "Enter the alias: " alias

    # Check if the alias is provided
    if [ -z "$alias" ]
    then
        echo "Please provide the alias of your genesis-validator"
        exit 1
    fi

    $NAMADA_BIN_DIR/namadac --base-dir "$BASE_DIR" utils join-network --chain-id $CHAIN_ID --genesis-validator $alias > /dev/null
else
    $NAMADA_BIN_DIR/namadac --base-dir "$BASE_DIR" utils join-network --chain-id $CHAIN_ID > /dev/null
fi

echo "You have successfully joined the network"

# Check that cometbft is installed before running the ledger
if ! command_exists cometbft;
then
    echo "Cometbft was not found on path, would you like to install it now? (y/n)"
    read -p "Enter (y/n): " INSTALL_COMETBFT

    # Check if the path provided is a valid directory and contains the cometbft binaries
    if [ "$INSTALL_COMETBFT" = "y" ]
    then
        . $SCRIPT_DIR/utils/download_binaries.sh
        download_cometbft_binaries
    else
        echo "Please install cometbft (and put them onto path) before running the ledger"
        exit 1
    fi
fi

echo "Please run the ledger in a separate terminal window by copying and pasting the following command:"
# if namada is on path then print the command without the namada_bin_dir path

if command_exists namada;
then
    echo ""
    printf "${BOLD}${YELLOW} namada node ledger run ${RESET}\n"
    echo ""
else
    echo ""
    printf "${BOLD}${YELLOW} $NAMADA_BIN_DIR/namada node ledger run ${RESET}\n"
    echo ""
fi


echo "Is the ledger running? (y/n)"
read -p "Enter (y/n): " IS_LEDGER_RUNNING

if [ "$IS_LEDGER_RUNNING" = "y" ]; then

    if ! command_exists jq; then
        if command_exists apt-get; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq jq
        elif command_exists yum; then 
            sudo yum install -y -q jq
        else
            echo "Error: Unable to install jq. Please install jq manually."
            exit 1
        fi
    fi
    catching_up=$(curl -s localhost:26657/status | jq -r ".result.sync_info.catching_up")

    while [ "$catching_up" = "true" ]; do
        echo "The node is not caught up yet. Sleeping for 5 seconds..."
        sleep 5
        catching_up=$(curl -s localhost:26657/status | jq -r ".result.sync_info.catching_up")
    done

    echo "Do you want to have a basic setup for the node? This adds some default keys and funds them (y/n)"
    read -p "Enter (y/n): " BASIC_SETUP
    if [ "$BASIC_SETUP" = "y" ]; then

        # Check if the node is caught up
    
        . $SCRIPT_DIR/utils/ledger_commands.sh
        basic_init
    fi
else
    echo "Please run the ledger in a separate terminal window by copying and pasting the following command:"
    echo "$NAMADA_BIN_DIR/namada node ledger run"
fi

rm -f *.tar.gz





