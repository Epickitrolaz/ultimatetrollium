#!/bin/bash

KISMET_LOG_DIR="captured"
KISMET_SESSION_LOG="$KISMET_LOG_DIR/$(date +%Y-%m-%d-%H-%M-%S)-wardrive/kismet-log.txt"
SESSION_NAME="wardrive"

echo "Stopping gpsd..."
sudo systemctl disable gpsd
sudo systemctl stop gpsd
sudo pkill gpsd 2>/dev/null
sudo systemctl disable gpsd.socket
sudo systemctl stop gpsd.socket


echo "Bringing interfaces down..."
sudo ifconfig $INTERFACE down

echo "Starting gpsd..."
sudo gpsd -N -G -n udp://0.0.0.0:10110 > /tmp/gpsd.log 2>&1 &
PID_GPSD=$!
sleep 5

echo "Testing gps..."
if ! netstat -tulnp | grep -q 'tcp.*:2947.*LISTEN'; then
    echo "ERROR: gpsd is not listening on TCP port 2947. Aborting."
    sudo kill "$PID_GPSD" 2>/dev/null
    exit 1
fi
echo "gpsd is listening on port 2947."


echo "Waiting for 3D GPS fix (up to 60 seconds)..."
FIX_FOUND=0
TIMEOUT_SECONDS=60

( gpspipe -w | grep -qm 1 '"mode":3' ) &
GPSPIPE_PID=$!

# Wait loop
for ((i=0; i<TIMEOUT_SECONDS; i++)); do
    # Check if the gpspipe process is still running
    if ! kill -0 "$GPSPIPE_PID" 2>/dev/null; then
        wait "$GPSPIPE_PID"
        FIX_RESULT=$?
        if [ "$FIX_RESULT" -eq 0 ]; then
            FIX_FOUND=1
        fi
        break
    fi
    sleep 1
done

# If gpspipe is still running after timeout, kill it
if kill -0 "$GPSPIPE_PID" 2>/dev/null; then
    kill "$GPSPIPE_PID" 2>/dev/null
    wait "$GPSPIPE_PID" 2>/dev/null
fi

if [ "$FIX_FOUND" -eq 1 ]; then
    echo "3D GPS fix acquired."
else
    echo "ERROR: GPSD did not get a 3D fix within $TIMEOUT_SECONDS seconds. Exiting."
    kill "$PID_GPSD" 2>/dev/null
    exit 1
fi

UTCDATE=$(gpspipe -w | grep -m 1 "TPV" | sed -r 's/.*"time":"([^"]*)".*/\1/' | sed -e 's/^\(.\{10\}\)T\(.\{8\}\).*/\1 \2/')
if [ -n "$UTCDATE" ]; then # Check if UTCDATE is not empty
    sudo date -u -s "$UTCDATE"
    echo "System date set to: $(date)"
else
    echo "WARNING: Could not get UTCDATE from gpsd. System date not set."
fi

echo "Setting wifi mode..."
sudo ifconfig ${INTERFACE} down
sudo iwconfig ${INTERFACE} mode monitor
sudo ifconfig ${INTERFACE} up

iwconfig ${INTERFACE}


echo "Starting tmux session for Kismet and gpsmon..."
tmux new-session -s "$SESSION_NAME" -d -n "Main"
tmux split-window -h -t "$SESSION_NAME:0"

tmux send-keys -t "$SESSION_NAME:0.0" "sudo kismet -p $KISMET_LOG_DIR -t wardrive --override wardrive -c $INTERFACE -c $INTERFACE_BT -g gpsd:host=localhost,port=2947,reconnect=true" C-m

tmux send-keys -t "$SESSION_NAME:0.1" "gpsmon" C-m

echo "Tmux session '$SESSION_NAME' started. Attaching..."
echo "Use Ctrl+b d to detach from the session."

tmux attach -t "$SESSION_NAME"

echo "Tmux session exited. Cleaning up processes..."

sudo pkill kismet 2>/dev/null
sudo pkill gpsd 2>/dev/null

echo "Kismet and gpsd stopped."
