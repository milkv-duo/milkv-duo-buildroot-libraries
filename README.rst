============
Milk-V Duo Firmware First Stage Bootloader
============

This package is obtained from https://github.com/milkv-duo/duo-buildroot-sdk, from which we download the first stage bootloader source and compile it, generating the atf ``bl2.bin``. At the mean time, we will use the ``fiptool.py`` in this package to create the binary file ``fip.bin`` to pack the opensbi, u-boot and so on.

If you are using Buildroot to generate the whole SD card image or the ``fip.bin``, you must say Y to this package!


https://github.com/gtxzsxxk/milkv-duo-firmware-fsbl
