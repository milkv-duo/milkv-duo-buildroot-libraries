CONFIG=/etc/milkv-duo.conf
source ${CONFIG}

case "$2" in
  acm)
	CLASS=acm
	;;
  msc)
	CLASS=mass_storage
	PID=$MSC_PID
	;;
  cvg)
	CLASS=cvg
	;;
  rndis)
	CLASS=rndis
	PID=$RNDIS_PID
	PRODUCT=$PRODUCT_RNDIS
	;;
  uvc)
	CLASS=uvc
	PID=$UVC_PID
	PRODUCT=$PRODUCT_UVC
	;;
  uac1)
	CLASS=uac1
	PID=$UAC_PID
	PRODUCT=$PRODUCT_UAC
	;;
  adb)
	CLASS=ffs.adb
	VID=$ADB_VID
	PID=$ADB_PID
	PRODUCT=$PRODUCT_ADB
	;;
  *)
	if [ "$1" = "probe" ] ; then
	  echo "Usage: $0 probe {acm|msc|cvg|rndis|uvc|uac1|adb}"
	  exit 1
	fi
esac

calc_func() {
  FUNC_NUM=$(ls $CVI_GADGET/functions -l | grep ^d | wc -l)
  echo "$FUNC_NUM file(s)"
}

res_check() {
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "acm*" | wc -l)
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  TMP_NUM=$(($TMP_NUM * 2))
  EP_IN=$(($EP_IN+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "mass_storage*" | wc -l)
  EP_IN=$(($EP_IN+$TMP_NUM))
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "cvg*" | wc -l)
  EP_IN=$(($EP_IN+$TMP_NUM))
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "rndis*" | wc -l)
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  TMP_NUM=$(($TMP_NUM * 2))
  EP_IN=$(($EP_IN+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "uvc*" | wc -l)
  TMP_NUM=$(($TMP_NUM * 2))
  EP_IN=$(($EP_IN+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name "uac1*" | wc -l)
  TMP_NUM=$(($TMP_NUM * 2))
  EP_IN=$(($EP_IN+$TMP_NUM))
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))
  TMP_NUM=$(find $CVI_GADGET/functions/ -name ffs.adb | wc -l)
  EP_IN=$(($EP_IN+$TMP_NUM))
  EP_OUT=$(($EP_OUT+$TMP_NUM))
  INTF_NUM=$(($INTF_NUM+$TMP_NUM))

  if [ "$CLASS" = "acm" ] ; then
    EP_IN=$(($EP_IN+2))
    EP_OUT=$(($EP_OUT+1))
  fi
  if [ "$CLASS" = "mass_storage" ] ; then
    EP_IN=$(($EP_IN+1))
    EP_OUT=$(($EP_OUT+1))
  fi
  if [ "$CLASS" = "cvg" ] ; then
    EP_IN=$(($EP_IN+1))
    EP_OUT=$(($EP_OUT+1))
  fi
  if [ "$CLASS" = "rndis" ] ; then
    EP_IN=$(($EP_IN+2))
    EP_OUT=$(($EP_OUT+1))
  fi
  if [ "$CLASS" = "uvc" ] ; then
    EP_IN=$(($EP_IN+2))
  fi
  if [ "$CLASS" = "uac1" ] ; then
    EP_IN=$(($EP_IN+1))
    EP_OUT=$(($EP_OUT+1))
  fi
  if [ "$CLASS" = "ffs.adb" ] ; then
    EP_IN=$(($EP_IN+1))
    EP_OUT=$(($EP_OUT+1))
  fi
  echo "$EP_IN in ep"
  echo "$EP_OUT out ep"
  if [ $EP_IN -gt $MAX_EP_NUM ]; then
    echo "reach maximum resource"
    exit 1
  fi
  if [ $EP_OUT -gt $MAX_EP_NUM ]; then
    echo "reach maximum resource"
    exit 1
  fi
}

probe() {
  if [ ! -d $CVI_DIR ]; then
    mkdir $CVI_DIR
  fi
  if [ ! -d $CVI_DIR/usb_gadget ]; then
    # Enale USB ConfigFS
    mount none $CVI_DIR -t configfs
    # Create gadget dev
    mkdir $CVI_GADGET
    # Set the VID and PID
    ${DUO_WRITE} $VID >$CVI_GADGET/idVendor
    ${DUO_WRITE} $PID >$CVI_GADGET/idProduct
    # Set the product information string
    mkdir $CVI_GADGET/strings/0x409
    ${DUO_WRITE} $MANUFACTURER>$CVI_GADGET/strings/0x409/manufacturer
    ${DUO_WRITE} $PRODUCT>$CVI_GADGET/strings/0x409/product
    ${DUO_WRITE} $SERIAL>$CVI_GADGET/strings/0x409/serialnumber
    # Set the USB configuration
    mkdir $CVI_GADGET/configs/c.1
    mkdir $CVI_GADGET/configs/c.1/strings/0x409
    ${DUO_WRITE} "config1">$CVI_GADGET/configs/c.1/strings/0x409/configuration
    # Set the MaxPower of USB descriptor
    ${DUO_WRITE} 120 >$CVI_GADGET/configs/c.1/MaxPower
  fi
  # get current functions number
  calc_func
  # assign the class code for composite device
  if [ ! $FUNC_NUM -eq 0 ]; then
    ${DUO_WRITE} 0xEF >$CVI_GADGET/bDeviceClass
    ${DUO_WRITE} 0x02 >$CVI_GADGET/bDeviceSubClass
    ${DUO_WRITE} 0x01 >$CVI_GADGET/bDeviceProtocol
  fi
  # resource check
  res_check
  # create the desired function
  if [ "$CLASS" = "ffs.adb" ] ; then
    # adb shall be the last function to probe. Override the pid/vid
    ${DUO_WRITE} $VID >$CVI_GADGET/idVendor
    ${DUO_WRITE} $PID >$CVI_GADGET/idProduct
    # choose pid for different function number
    if [ $INTF_NUM -eq 1 ]; then
      ${DUO_WRITE} $ADB_PID_M1 >$CVI_GADGET/idProduct
    fi
    if [ $INTF_NUM -eq 2 ]; then
      ${DUO_WRITE} $ADB_PID_M2 >$CVI_GADGET/idProduct
    fi
    mkdir $CVI_GADGET/functions/$CLASS
  else
    mkdir $CVI_GADGET/functions/$CLASS.usb$FUNC_NUM
  fi
  if [ "$CLASS" = "mass_storage" ] ; then
    ${DUO_WRITE} $MSC_FILE >$CVI_GADGET/functions/$CLASS.usb$FUNC_NUM/lun.0/file
  fi
  if [ "$CLASS" = "rndis" ] ; then
    #OS STRING
    ${DUO_WRITE} 1 >$CVI_GADGET/os_desc/use
    ${DUO_WRITE} 0xcd >$CVI_GADGET/os_desc/b_vendor_code
    ${DUO_WRITE} MSFT100 >$CVI_GADGET/os_desc/qw_sign
    #COMPATIBLE ID
    ${DUO_WRITE} RNDIS >$CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/compatible_id
    #MAKE c.1 THE ONE ASSOCIATED WITH OS DESCRIPTORS
    ln -s $CVI_GADGET/configs/c.1 $CVI_GADGET/os_desc
    #MAKE "Icons" EXTENDED PROPERTY
    mkdir $CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Icons
    ${DUO_WRITE} 2 >$CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Icons/type
    ${DUO_WRITE} "%SystemRoot%\\system32\\shell32.dll,-233" >$CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Icons/data
    #MAKE "Label" EXTENDED PROPERTY
    mkdir $CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Label
    ${DUO_WRITE} 1 >$CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Label/type
    ${DUO_WRITE} "XYZ Device" >$CVI_FUNC/rndis.usb$FUNC_NUM/os_desc/interface.rndis/Label/data
  fi

}

start() {
  # link this function to the configuration
  calc_func
  if [ $FUNC_NUM -eq 0 ]; then
    echo "Functions Empty!"
    exit 1
  fi
  if [ -d $CVI_GADGET/functions/ffs.adb ]; then
    FUNC_NUM=$(($FUNC_NUM-1))
  fi
  for i in `seq 0 $(($FUNC_NUM-1))`;
  do
    find $CVI_GADGET/functions/ -name "*.usb$i" | xargs -I % ln -s % $CVI_GADGET/configs/c.1
  done
  if [ -d $CVI_GADGET/functions/ffs.adb ]; then
    ln -s $CVI_GADGET/functions/ffs.adb $CVI_GADGET/configs/c.1
    mkdir /dev/usb-ffs/adb -p
    mount -t functionfs adb /dev/usb-ffs/adb
    if [ -f $ADBD_PATH/adbd ]; then
	$ADBD_PATH/adbd &
    fi
  else
    # Start the gadget driver
    UDC=`ls /sys/class/udc/ | awk '{print $1}'`
    ${DUO_WRITE} ${UDC} >$CVI_GADGET/UDC
  fi
}

stop() {
  if [ -d $CVI_GADGET/configs/c.1/ffs.adb ]; then
    pkill adbd
    rm $CVI_GADGET/configs/c.1/ffs.adb
  else
    ${DUO_WRITE} "" >$CVI_GADGET/UDC
  fi
  find $CVI_GADGET/configs/ -name "*.usb*" | xargs rm -f
  rmdir $CVI_GADGET/configs/c.*/strings/0x409/
  tmp_dirs=$(find $CVI_GADGET/os_desc/c.* -type d)
  if [ -n tmp_dirs ]; then
    echo "remove os_desc!"
    rm -rf $CVI_GADGET/os_desc/c.*/
    find $CVI_GADGET/functions/ -name Icons | xargs rmdir
    find $CVI_GADGET/functions/ -name Label | xargs rmdir
  fi
  rmdir $CVI_GADGET/configs/c.*/
  rmdir $CVI_GADGET/functions/*
  rmdir $CVI_GADGET/strings/0x409/
  rmdir $CVI_GADGET
  umount $CVI_DIR
  rmdir $CVI_DIR
}

case "$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  probe)
	probe
	;;
  UDC)
	ls /sys/class/udc/ >$CVI_GADGET/UDC
	;;
  *)
	echo "Usage: $0 probe {acm|msc|cvg|uvc|uac1} {file (msc)}"
	echo "Usage: $0 start"
	echo "Usage: $0 stop"
	exit 1
esac
exit $?
