#!/bin/sh

CONFIG=/etc/milkv-duo.conf
source ${CONFIG}

/opt/milkv-duo/usb-hub-ctrl.sh device >> /tmp/usb.log 2>&1
/opt/milkv-duo/usb-run.sh probe msc ${DUO_USB_MASS_STORAGE_ROOT} >> /tmp/usb.log 2>&1
/opt/milkv-duo/usb-run.sh start >> /tmp/usb.log 2>&1

[ $? = 0 ] && echo "Mass Storage started successfully" || echo "Fail to start Mass Storage"
