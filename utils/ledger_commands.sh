#!/bin/sh

create_keys(){
    echo "Creating keys..."
    echo "Creating key alice"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" key gen --alias "alice" --unsafe-dont-encrypt
    echo "Creating key bob"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" key gen --alias "bob" --unsafe-dont-encrypt
    echo "Creating key charlie"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" key gen --alias "charlie" --unsafe-dont-encrypt
    echo "Creating key banker"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" key gen --alias "banker" --unsafe-dont-encrypt
}

masp_setup(){
    echo "Creating keys and payment addresses ..."
    echo "Creating key alice-masp"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-key --alias "alice-masp" --unsafe-dont-encrypt
    echo "Creating payment address pay-alice"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-addr --alias "pay-alice" --key "alice-masp"
    echo "Creating key bob-masp"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-key --alias "bob-masp" --unsafe-dont-encrypt
    echo "Creating payment address pay-bob"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-addr --alias "pay-bob" --key "bob-masp"
    echo "Creating key charlie-masp"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-key --alias "charlie-masp" --unsafe-dont-encrypt
    echo "Creating payment address pay-charlie"
    $NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" masp gen-addr --alias "pay-charlie" --key "charlie-masp"
}

fund_account(){
    # Takes 2 argument
    # $1 = account name
    # $2 = token name

    # Check if the account exists
    is_in_wallet=$($NAMADA_BIN_DIR/namadaw --base-dir "$BASE_DIR" address list | grep $1)
    if [ -z "$is_in_wallet" ]; then
        echo "Error: Account $1 does not exist in the wallet."
    else
        echo "Funding $1"
        $NAMADA_BIN_DIR/namadac --base-dir "$BASE_DIR" transfer \
            --amount 1000 \
            --token $2 \
            --source faucet \
            --target $1 \
            --signer $1
    fi
}

transfer_nam(){
    local from=$1
    local to=$2
    local amount=$3
    local token=$4

    $NAMADA_BIN_DIR/namadac --base-dir "$BASE_DIR" transfer \
        --amount=$amount \
        --token $token \
        --source $from \
        --target $to \
        --signer $from
}

basic_init(){
    # Create keys
    create_keys

    # Fund accounts
    fund_account alice nam
    fund_account bob nam
    fund_account charlie nam
    # Give the banker ample funds
    fund_account banker nam
    fund_account banker nam
    fund_account banker nam
    fund_account banker nam

    # Do a basic masp setup
    masp_setup

    # Send money from banker to the different payment addresses
    echo "Sending money from banker to the different payment addresses"
    transfer_nam banker pay-alice 1000 nam
    transfer_nam banker pay-bob 1000 nam
    transfer_nam banker pay-charlie 1000 nam

}