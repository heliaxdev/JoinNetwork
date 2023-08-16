# !/bin/sh

run_ledger(){
    
sudo tee /etc/systemd/system/namadad.service > $SCRIPT_DIR/logs/ledger.log <<EOF
[Unit]
Description=namada
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment=CMT_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=$NAMADA_BIN_DIR/namada node ledger run 
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable namadad
}

running_the_ledger(){
    echo "Do you want to start the node? (y/n)"
    read -p "Enter (y/n): " START_NODE

    if [ "$START_NODE" = "y" ]; then
        mkdir -p logs
        echo "The node is starting in the background. You can check the logs in the logs/ledger.log file"

        # Run the ledger
        run_ledger

        echo "Do you want to have a basic setup for the node? This adds some default keys and funds them (y/n)"
        read -p "Enter (y/n): " BASIC_SETUP
        if [ "$BASIC_SETUP" = "y" ]; then

            # Check if the node is caught up
            local status=$(curl localhost:26657/status)


            source $SCRIPT_DIR/utils/ledger_commands.sh
            basic_init
        fi
    else
        echo "You can start the node by running the following command:"
        echo "namada ledger run"
    fi
}

delete_ledger_daemon(){
    sudo systemctl stop namadad
    sudo systemctl disable namadad
    sudo rm /etc/systemd/system/namadad.service
    sudo systemctl daemon-reload
    rm /etc/systemd/system/namada* -rf
}

SCRIPT_DIR="$(pwd)"
NAMADA_BIN_DIR=$(dirname $(which namadac))
BASE_DIR=$($NAMADA_BIN_DIR/namadac utils default-base-dir)

running_the_ledger