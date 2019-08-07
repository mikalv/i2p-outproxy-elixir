#!/usr/bin/env bash
# Start with installing required packages
apt update
apt install tmux libz-dev git vim libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-thread-dev make g++ libssl-dev wget libboost-system-dev gnupg -y
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
dpkg -i erlang-solutions_1.0_all.deb
apt update
# Erlang and Elixir
apt install esl-erlang elixir -y
# Download and build I2Pd
cd /usr/src
git clone https://github.com/PurpleI2P/i2pd-tools.git
cd i2pd-tools
git clone https://github.com/PurpleI2P/i2pd.git
cd i2pd
make || exit 1
cp i2pd /usr/sbin/i2pd
cd ..
make || exit 1
cp keygen keyinfo /usr/local/bin

# SystemD for I2Pd
groupadd i2pd
useradd -d /home/i2pd -m -g i2pd -s /usr/bin/bash i2pd
mkdir -p /etc/i2pd /var/lib/i2pd
cat <<EOF > /etc/systemd/system/i2pd.service
[Unit]
Description=I2P Router written in C++
Documentation=man:i2pd(1) https://i2pd.readthedocs.io/en/latest/
After=network.target

[Service]
User=i2pd
Group=i2pd
RuntimeDirectory=/var/lib/i2pd
RuntimeDirectoryMode=0700
Type=forking
ExecStart=/usr/sbin/i2pd --conf=/etc/i2pd/i2pd.conf --tunconf=/etc/i2pd/tunnels.conf --pidfile=/var/run/i2pd/i2pd.pid --logfile=/var/log/i2pd/i2pd.log --daemon --service
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/i2pd/i2pd.pid
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

cat <<EOF > /etc/i2pd/i2pd.conf
tunconf = /etc/i2pd/tunnels.conf
pidfile = /var/run/i2pd.pid
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
inbound.length=3
outbound.length=3
i2p.streaming.initialAckDelay=20
EOF
cp -r /usr/src/i2pd-tools/i2pd/contrib/certificates /var/lib/i2pd/
mkdir -p /var/run/i2pd /var/log/i2pd
chown -R i2pd:i2pd /etc/i2pd /var/lib/i2pd /var/run/i2pd /var/log/i2pd
systemctl enable i2pd
systemctl start i2pd

# Start building the outproxy software
mkdir /app
cd /app
# Get the code
git clone https://github.com/mikalv/i2p-outproxy-elixir.git
cd i2p-outproxy-elixir
# Install pkg managers
mix local.hex --force
mix local.rebar --force
# Install dependencies
mix deps.get
mix compile


