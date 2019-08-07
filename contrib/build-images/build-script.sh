#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Move the script first of all
mkdir /app
mv $SCRIPT_DIR/boot-login.sh /app/boot-login.sh
# Start with installing required packages
apt update
apt install tmux libz-dev git vim gnupg -y || exit 1
apt install libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev -y || exit 1
apt install libboost-thread-dev make g++ libssl-dev wget libboost-system-dev -y || exit 1
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
dpkg -i erlang-solutions_1.0_all.deb
apt update
# Erlang and Elixir
apt install esl-erlang elixir -y
# Install NodeJS
apt install npm -y
# Download and build I2Pd
cd /usr/src
git clone https://github.com/PurpleI2P/i2pd-tools.git
cd i2pd-tools
git clone https://github.com/PurpleI2P/i2pd.git
cd i2pd
make -j $(nproc) || exit 1
cp i2pd /usr/sbin/i2pd
cd ..
make -j $(nproc) || exit 1
cp keygen keyinfo /usr/local/bin

# SystemD for I2Pd
groupadd i2pd
useradd -d /home/i2pd -m -g i2pd i2pd
mkdir -p /etc/i2pd /var/lib/i2pd
cat <<EOF > /etc/systemd/system/i2pd.service
[Unit]
Description=I2P Router written in C++
Documentation=man:i2pd(1) https://i2pd.readthedocs.io/en/latest/
After=network.target

[Service]
User=i2pd
Group=i2pd
WorkingDirectory=/var/lib/i2pd
Type=forking
ExecStart=/usr/sbin/i2pd --conf=/etc/i2pd/i2pd.conf --tunconf=/etc/i2pd/tunnels.conf --pidfile=/var/lib/i2pd/i2pd.pid --logfile=/var/log/i2pd/i2pd.log --daemon --service
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/lib/i2pd/i2pd.pid
### Uncomment, if auto restart needed
Restart=always
#Restart=on-failure

#KillSignal=SIGQUIT
# If you have the patience waiting 10 min on restarting/stopping it, uncomment this.
# i2pd stops accepting new tunnels and waits ~10 min while old ones do not die.
KillSignal=SIGINT
TimeoutStopSec=10m

# If you have problems with hanging i2pd, you can try enable this
#LimitNOFILE=65536
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/outproxy-keygen.service
[Unit]
ConditionFileNotEmpty=/var/lib/i2pd/outproxy.key.dat
Before=i2pd.service

[Service]
WorkingDirectory=/var/lib/i2pd
ExecStart=/usr/local/bin/keygen outproxy.key.dat RED25519-SHA512
ExecStartPost=/bin/chown i2pd:i2pd /var/lib/i2pd/outproxy.key.dat
ExecStartPost=/bin/chmod 640 /var/lib/i2pd/outproxy.key.dat
Type=oneshot
RemainAfterExit=yes

[Install]
RequiredBy=i2pd.service
EOF

cat <<EOF > /etc/i2pd/i2pd.conf
tunconf = /etc/i2pd/tunnels.conf
pidfile = /var/lib/i2pd.pid
log = file
logfile = /var/log/i2pd/i2pd.log
loglevel = warn
datadir = /var/lib/i2pd
service = true
host = $(curl -s ifconfig.co)
ipv4 = true
ntcp = true
ssu  = true
nat  = false
[limits]
transittunnels = 1000
[precomputation]
elgamal = true
[reseed]
verify = true
threshold = 150
urls = https://reseed.i2p-projekt.de/,https://i2p.mooo.com/netDb/,https://netdb.i2p2.no/
[addressbook]
defaulturl = http://joajgazyztfssty4w2on5oaqksz6tqoxbduy553y34mf4byv6gpq.b32.i2p/export/alive-hosts.txt
subscriptions = http://inr.i2p/export/alive-hosts.txt,http://stats.i2p/cgi-bin/newhosts.txt,http://rus.i2p/hosts.txt
[http]
enabled = true
address = 127.0.0.1
port = 7070
[i2pcontrol]
enabled = true
address = 127.0.0.1
port = 7650
EOF

cat <<EOF > /etc/i2pd/tunnels.conf
[private-outproxy]
type=server
host=127.0.0.1
port=4480
keys=outproxy.key.dat
inbound.quantity=25
outbound.quantity=25
inbound.length=1
outbound.length=1
i2p.streaming.initialAckDelay=20
EOF
cp -r /usr/src/i2pd-tools/i2pd/contrib/certificates /var/lib/i2pd/
mkdir -p /var/log/i2pd
chown -R i2pd:i2pd /etc/i2pd /var/lib/i2pd /var/log/i2pd

# Ensure startup stuff
systemctl enable outproxy-keygen.service
systemctl enable i2pd.service
#systemctl start i2pd

# Start building the outproxy software
export MIX_ENV=prod
export USER=i2pd
export HOME=/home/i2pd
cd /app
# Get the code
git clone https://github.com/mikalv/i2p-outproxy-elixir.git
cd i2p-outproxy-elixir
chown -R i2pd:i2pd /app
# Install pkg managers
sudo -u i2pd mix local.hex --force
sudo -u i2pd mix local.rebar --force
# Install dependencies
sudo -u i2pd mix deps.get
sudo -u i2pd mix compile
cd /app/i2p-outproxy-elixir/apps/admin_console/
# Install nodejs dependencies for the admin console
npm i
touch /app/i2p-outproxy-elixir/apps/admin_console/config/prod.secret.exs
sudo -u i2pd mix phx.digest
cd /app/i2p-outproxy-elixir
chown -R i2pd:i2pd /app /home/i2pd

cat <<EOF > /etc/systemd/system/outproxy.service
[Unit]
Description=I2P Outproxy Application
After=network.target

[Service]
User=i2pd
Group=i2pd
RuntimeDirectory=/app/i2p-outproxy-elixir
RuntimeDirectoryMode=0700
WorkingDirectory=/app/i2p-outproxy-elixir
Type=simple
Environment="MIX_ENV=prod"
ExecStart=/usr/bin/mix run --no-halt
ExecReload=/bin/kill -HUP $MAINPID
#PIDFile=/var/lib/i2pd/i2pd.pid
### Uncomment, if auto restart needed
Restart=always
#Restart=on-failure
KillSignal=SIGINT
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Make boot info script run at boot and login.
echo /app/boot-login.sh >> /etc/rc.local
ln -sf /app/boot-login.sh /etc/profile.d/outproxy-info.sh

systemctl enable outproxy
systemctl start outproxy

# Cleanup if any
apt update
apt upgrade -y
apt update
apt autoremove -y

echo "[+] Success! We are done!"
