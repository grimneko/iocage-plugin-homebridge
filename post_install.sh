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

# install process manager to keep homebridge running / booting on iocage restarts
# and provide the config ui with logs
npm install -g pm2
pm2 startup rcd

# enable pm2 service
sysrc -f /etc/rc.conf pm2_enable="YES"

# setup pm2
pm2 start homebridge -- -D
pm2 save
