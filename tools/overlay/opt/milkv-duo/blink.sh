#!/bin/sh

CONFIG=/etc/milkv-duo.conf
source ${CONFIG}

if test -d ${LED_PATH}; then
    echo "GPIO${LED_GPIO} already exported"
else
    ${DUO_WRITE} ${LED_GPIO} >/sys/class/gpio/export
fi

${DUO_WRITE} out >${LED_PATH}/direction

while true; do
    source ${CONFIG}
    if [ "$ENABLE_BLINK" == "1" ]; then
        ${DUO_WRITE} 0 >${LED_PATH}/value
        sleep 0.5
        ${DUO_WRITE} 1 >${LED_PATH}/value
        sleep 0.5
    else
        ${DUO_WRITE} 0 >${LED_PATH}/value
        sleep 2
    fi
done
