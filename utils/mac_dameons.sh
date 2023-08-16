run_ledger() {
    sudo tee /Library/LaunchDaemons/com.namada.namadad.plist > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.namada.namadad</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>"namada node ledger run"</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/logs/ledger.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/logs/ledger_error.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>LimitNOFILE</key>
    <integer>65535</integer>
</dict>
</plist>
EOF
    sudo launchctl load /Library/LaunchDaemons/com.namada.namadad.plist
}

running_the_ledger() {
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
        echo "namada node ledger run"
    fi
}

delete_ledger_daemon() {
    sudo launchctl unload /Library/LaunchDaemons/com.namada.namadad.plist
    sudo rm /Library/LaunchDaemons/com.namada.namadad.plist
}
SCRIPT_DIR="$(pwd)"
NAMADA_BIN_DIR=$(dirname $(which namadac))
BASE_DIR=$($NAMADA_BIN_DIR/namadac utils default-base-dir)

# running_the_ledger
delete_ledger_daemon