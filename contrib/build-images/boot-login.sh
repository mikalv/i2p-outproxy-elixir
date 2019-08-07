#!/usr/bin/env bash
CONSOLE_DEV=${1:-"/dev/tty1"}
SSH_CONSOLE=$(tty | sed -e "s/.*tty\(.*\)/\1/")
export PATH=/usr/local/bin:$PATH
keyfile="/var/lib/i2pd/outproxy.key.dat"

function printconsole() {
    echo -en $@  > $CONSOLE_DEV
    file $SSH_CONSOLE > /dev/null && echo -en $@  > $SSH_CONSOLE
}

printconsole "\n\n\n\n\n"
printconsole "Welcome to the private outproxy setup for I2P users!\n\n\n"

if [[ ! -f "/var/lib/i2pd/outproxy.key.dat" ]]; then
  mkdir -p /var/lib/i2pd
  cd /var/lib/i2pd
  keygen outproxy.key.dat RED25519-SHA512
  chown -R i2pd:i2pd /var/lib/i2pd
  systemctl restart i2pd
fi
keydest=$(keyinfo -v -d $keyfile | head -n 1 | awk '{ print $2 }')
b32dest=$(keyinfo -v -d $keyfile | head -n+3 | tail -n1 | awk '{ print $3 }')
printconsole "Your destination base64 address is: $keydest\n\n"
printconsole "Your base32 address is:\n$b32dest\n\nThat base32 is probably the easiest to copy :)\n\n\n"
printconsole "You can backup your destination key, copy it from:\n$keyfile\n\n"

ownip=$(curl -s ifconfig.co)
printconsole "\nTo access I2Pd's console, connect to the server with:\n"
printconsole "ssh -L7070:127.0.0.1:7070 $(whoami)@${ownip}\nThen access the console at:\n"
printconsole "http://127.0.0.1:7070\n\n\n"

printconsole "NOTE: Please let the router run for 5-10min the first time before you start accessing the outproxy.\n"
printconsole "The reason for this is that the router will explore the i2p network and find more peers and not get a list from some centralized servers. :)\n\n"


