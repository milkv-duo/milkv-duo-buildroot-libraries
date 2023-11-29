#!/bin/sh

CONFIG=/etc/milkv-duo.conf
source ${CONFIG}

/opt/milkv-duo/uhubon.sh device >> /tmp/usb.log 2>&1
/opt/milkv-duo/run_usb.sh probe msc ${DUO_USB_MASS_STORAGE_ROOT} >> /tmp/usb.log 2>&1
/opt/milkv-duo/run_usb.sh start >> /tmp/usb.log 2>&1

[ $? = 0 ] && echo "Mass Storage started successfully" || echo "Fail to start Mass Storage"
