#!/bin/bash
apt update
apt -y upgrade
rm -rf /tmp/* /var/tmp/*
rm -fr /var/lib/i2pd/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
apt -y autoremove
apt -y autoclean
apt clean
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
dd if=/dev/zero of=/zerofile; sync; rm /zerofile; sync
cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp
echo "[+] Cleaned VM"
