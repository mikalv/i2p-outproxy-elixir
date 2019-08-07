#!/bin/bash

#
# Invoke this script with:
# curl https://github.com/mikalv/i2p-outproxy-elixir/raw/master/contrib/remote-install-script.sh | bash
#

command -v curl >/dev/null 2>&1 || apt install -y curl
TMPDIR=/tmp/outproxy_install$$
cd $TMPDIR
curl https://github.com/mikalv/i2p-outproxy-elixir/raw/master/contrib/build-images/boot-login.sh > boot-login.sh
curl https://github.com/mikalv/i2p-outproxy-elixir/raw/master/contrib/build-images/build-script.sh > build-script.sh
chmod +x build-script.sh boot-login.sh
./build-script.sh
systemctl start outproxy-keygen.service i2pd.service
# Let's now trigger the info script
/app/boot-login.sh

