#!/bin/sh
# enable services
sysrc -f /etc/rc.conf dbus_enable="YES"
sysrc -f /etc/rc.conf avahi_daemon_enable="YES"

# link dns_sd.h to the place where its expected
ln -s /usr/local/include/avahi-compat-libdns_sd/dns_sd.h /usr/include/dns_sd.h

# enable avahi to use dbus
sed -i -e 's/#enable-dbus/enable-dbus/' /usr/local/etc/avahi/avahi-daemon.conf

# enable mdns usage for host resolution
sed -i -e 's/hosts: file dns/hosts: file dns mdns/' /etc/nsswitch.conf

# start services
service dbus start
service avahi-daemon start

# begin install of homebridge and the config-ui
npm install -g --unsafe-perm homebridge
npm install -g --unsafe-perm homebridge-config-ui-x

# generate mac for homebridge
HOMEMAC=`env LC_ALL=C tr -c -d '0123456789abcdef' < /dev/urandom | head -c 12 | sed 's!^M$!!;s!\-!!g;s!\.!!g;s!\(..\)!\1:!g;s!:$!!' | tr [:lower:] [:upper:]`

# insert generated mac into config (unless you change the mac/pin homebridge wont work properly)
sed -i -e "s/CC:22:3D:E3:CE:30/$HOMEMAC/" /root/.homebridge/config.json

# generate new pin for this installation
HOMEPIN=`env LC_ALL=C tr -c -d '0123456789' < /dev/urandom | head -c 8 | sed 's/^\(...\)\(..\)\(...\)/\1-\2-\3/'`

# insert new pin into homebridge configuration
sed -i -e "s/031-45-154/$HOMEPIN/" /root/.homebridge/config.json

# install process manager to keep homebridge running / booting on iocage restarts
# and provide the config ui with logs
npm install -g pm2
pm2 startup rcd

# enable pm2 service
sysrc -f /etc/rc.conf pm2_enable="YES"

# setup pm2
pm2 start homebridge -- -D
pm2 save
