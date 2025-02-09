echo "### ###  ####       ##     ###  ##    ##     ### ##    ## ##   ##  ##             ## ##    ## ##    ## ##   "
echo " ##  ##   ##         ##      ## ##     ##     ##  ##  ##   ##  ##  ##            ##   ##  ##   ##  ##   ##  "
echo " ##       ##       ## ##    # ## #   ## ##    ##  ##  ##       ##  ##            ##       ####     ####     "
echo " ## ##    ##       ##  ##   ## ##    ##  ##   ## ##   ##        ## ##            ##        #####    #####   "
echo " ##       ##       ## ###   ##  ##   ## ###   ## ##   ##         ##              ##           ###      ###  "
echo " ##  ##   ##  ##   ##  ##   ##  ##   ##  ##   ##  ##  ##   ##    ##              ##   ##  ##   ##  ##   ##  "
echo "### ###  ### ###  ###  ##  ###  ##  ###  ##  #### ##   ## ##     ##               ## ##    ## ##    ## ##   "
echo "                                                                                                            "

                                                                                                            

# ========================================
#  Made BY ELANARCY CSS
# ========================================

#!/bin/bash

# Prompt user for EVM-based reward address
echo "Enter your EVM-based reward address (0x...):"
read REWARD_ADDRESS

sudo apt install curl -y
sudo apt install supervisor -y
sudo apt update -y
sudo apt upgrade -y

# Download and run setup script with reward address
curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_prover.sh -o ~/setup_prover.sh
chmod +x ~/setup_prover.sh
bash ~/setup_prover.sh "$REWARD_ADDRESS"

mkdir -p cysic-prover/~/.cysic/assets/
cp *.key cysic-prover/~/.cysic/assets/

# Change directory and verify checksum
cd
sha256sum cysic-prover/*.so cysic-prover/prover

# Download dependencies and verify checksums
mkdir -p cysic-prover/~/.cysic/assets/scroll/v1/params
mkdir -p .scroll_prover/params

curl -L --retry 999 -C - https://circuit-release.s3.us-west-2.amazonaws.com/setup/params20 -o .scroll_prover/params/params20
curl -L --retry 999 -C - https://circuit-release.s3.us-west-2.amazonaws.com/setup/params24 -o .scroll_prover/params/params24
curl -L --retry 999 -C - https://circuit-release.s3.us-west-2.amazonaws.com/setup/params25 -o .scroll_prover/params/params25

cp .scroll_prover/params/* cysic-prover/~/.cysic/assets/scroll/v1/params/
sha256sum .scroll_prover/params/*

# Create Supervisor config
echo '[unix_http_server]
file=/tmp/supervisor.sock

[supervisord]
logfile=/tmp/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info
pidfile=/tmp/supervisord.pid
nodaemon=false
silent=false
minfds=1024
minprocs=200
strip_ansi=true

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[program:cysic-prover]
command=/home/ubuntu/cysic-prover/prover
numprocs=1
directory=/home/ubuntu/cysic-prover
priority=999
autostart=true
redirect_stderr=true
stdout_logfile=/home/ubuntu/cysic-prover/cysic-prover.log
stdout_logfile_maxbytes=1GB
stdout_logfile_backups=1
environment=LD_LIBRARY_PATH="/home/ubuntu/cysic-prover",CHAIN_ID="534352",REWARD_ADDRESS="$REWARD_ADDRESS"' > supervisord.conf

# Start Supervisor
supervisord -c supervisord.conf

echo "Installation complete. Prover is running under Supervisor."
supervisorctl tail -f cysic-prover