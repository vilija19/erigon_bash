#!/bin/bash
sudo apt update -y && apt upgrade -y && apt autoremove -y

#Prerequisites
sudo apt-get install -y build-essential

sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null

if [[ -f .env ]]; then
  source .env
  else
    echo "env file doesn't exists!!!"
    exit 1
fi

#Golang
cd $HOME
curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
if [[ -f "/usr/bin/go" ]]; then
  sudo rm /usr/bin/go
fi
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source $HOME/.profile
rm go${GO_VERSION}.linux-amd64.tar.gz

#Erigon
cd $HOME
curl -LO https://github.com/ledgerwatch/erigon/archive/refs/tags/v${ERIGON_VERSION}.tar.gz
tar xvf v${ERIGON_VERSION}.tar.gz
cd erigon-${ERIGON_VERSION}
make erigon
cd $HOME
sudo cp erigon-${ERIGON_VERSION}/build/bin/erigon /usr/local/bin/
rm v${ERIGON_VERSION}.tar.gz
rm -r erigon-${ERIGON_VERSION}

if ! id "erigon" >/dev/null 2>&1; then
  sudo useradd --no-create-home --shell /bin/false erigon
  sudo mkdir -p ${ERIGON_DATA_DIR}
  sudo chown -R erigon:erigon ${ERIGON_DATA_DIR}
fi





#Lighthouse Beacon

cd ~
curl -LO https://github.com/sigp/lighthouse/releases/download/v$LIGHTHOUSE_VERSION/lighthouse-v${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz
tar xvf lighthouse-v${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
rm lighthouse-v${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz
rm lighthouse

if ! id "lighthousebeacon" >/dev/null 2>&1; then
  sudo useradd --no-create-home --shell /bin/false lighthousebeacon
  sudo mkdir -p ${LIGHTHOUSE_DATA_DIR}/beacon
  sudo chown -R lighthousebeacon:lighthousebeacon ${LIGHTHOUSE_DATA_DIR}
fi


service_file_path="/etc/systemd/system/erigon.service"


echo "[Unit]
Description=Erigon Execution Client (Mainnet)
After=network.target
Wants=network.target
[Service]
User=erigon
Group=erigon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/erigon \
  --datadir=${ERIGON_DATA_DIR} \
  --rpc.gascap=50000000 \
  --http \
  --ws \
  --rpc.batch.concurrency=100 \
  --state.cache=2000000 \
  --http.addr="0.0.0.0" \
  --http.port=8545 \
  --http.api="eth,erigon,web3,net,debug,trace,txpool" \
  --authrpc.port=8551 \
  --private.api.addr="0.0.0.0:9595" \
  --http.corsdomain="*" \
  --torrent.download.rate 90m \
  --authrpc.jwtsecret=/var/lib/jwtsecret/jwt.hex \
  --metrics 
[Install]
WantedBy=default.target"  | sudo tee ${service_file_path} \


service_file_path="/etc/systemd/system/lighthousebeacon.service"

echo "[Unit]
Description=Lighthouse Consensus Client BN (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=lighthousebeacon
Group=lighthousebeacon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse bn \
  --network mainnet \
  --datadir ${LIGHTHOUSE_DATA_DIR} \
  --http \
  --execution-endpoint http://localhost:8551 \
  --execution-jwt /var/lib/jwtsecret/jwt.hex \
  --checkpoint-sync-url ${CHECKPOINT_SYNC_URL} \
  --metrics
[Install]
WantedBy=multi-user.target" | sudo tee ${service_file_path} \


sudo systemctl daemon-reload
sudo systemctl enable erigon
sudo systemctl enable lighthousebeacon
sudo systemctl start erigon
sudo systemctl start lighthousebeacon

