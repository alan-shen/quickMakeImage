#!/bin/bash

#
# Author: pengru.shen@borqs.com
# Date:   2013/11/03
#

SCRIPTNAME=`basename $0`

clear
BUILDDATE=`date +%m%d`
MAKEIMAGE_STARTTIME=`date +%H:%M:%S`
MAKEIMAGE_ENDTIME=

# Define Pars Of Color Output
GP="\033[32;49;1m"
GE="\033[39;49;0m"
RP="\033[31;49;1m"
RE="\033[31;49;0m"
BP="\033[34;49;1m"
BE="\033[34;49;0m"
AP="\033[36;49;1m"
AE="\033[36;49;0m"

#
# 1.Check Android Build Env
#
if [ -z ${ANDROID_PRODUCT_OUT} ];then
	echo -e "\n${RP}ERROR: Plz create android build env first... ${RE}\n"
	echo -e "\t${RP} # source build/envsetup.sh;lunch 19;./${SCRIPTNAME}${RE}\n\n"
	exit 1
fi

#
# 2.Define A Important Path
#
ANDROIDOUT=out/target/product/redhookbay
if [ -z ${ANDROIDOUT} ];then
	echo -e "\n${RP}ERROR: Plz define OUT path par first... ${RE}\n"
	echo -e "\t${RP} # export ANDROIDOUT=out/target/product/redhookbay; ${RE}\n\n"
	exit 1
fi
CMDLINE_BOOT=`cat ${ANDROIDOUT}/boot_cmdline`
CMDLINE_RECO=`cat ${ANDROIDOUT}/recovery_cmdline`
CMDLINE_FAST=`cat ${ANDROIDOUT}/droidboot_cmdline`

#
# Output Directory
#
USER_OUT=${BUILDDATE}_${TARGET_BUILD_VARIANT}_${TARGET_BUILD_TYPE}_${USER}
rm -rf ${USER_OUT}
mkdir -p ${USER_OUT}

#
# Check CMDLINE(Full Build Output) In Android OUT Directory
#
echo -e "${RP}================================================================================================${RE}"
if [ -z "${CMDLINE_BOOT}" ] || [ -z "${CMDLINE_RECO}" ] || [ -z "${CMDLINE_FAST}" ];then
	echo -e "\n${RP}ERROR: Can find commandline file under OUT directory... ${RE}"
	echo -e   "${RP}ERROR: Please make sure you did a full build... ${RE}\n"
	echo -e "\t${RP} # make redhookbay -j4; ${RE}\n\n"
	exit 1
else
	echo -e "\t\t\t\t${AP}         [DV] QUICK MAKE  BOOT/RECOVERY/DROIDBOOT IMAGES               ${AE}"
	echo -e   "\t\t\t\t${RP}         ...............................................               ${RE}\n\n"
fi

#
# Path Of Tools & Directory & Images
#
MKBOOTFS=out/host/linux-x86/bin/mkbootfs
MINIZIP=out/host/linux-x86/bin/minigzip
MKBOOTIMG=vendor/intel/support/mkbootimg
KERNEL=${ANDROIDOUT}/kernel
RAMDISK_PATH=${ANDROIDOUT}/root
RAMDISK=${ANDROIDOUT}/ramdisk.img
RAMDISK_RECO_PATH=${ANDROIDOUT}/recovery/root
RAMDISK_RECO=${ANDROIDOUT}/ramdisk-recovery.img
RAMDISK_DROID_PATH=${ANDROIDOUT}/droidboot/root
RAMDISK_DROID=${ANDROIDOUT}/ramdisk-droidboot.img

#
# Quick Make Boot Image
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Boot Ramdisk & BIN... ${GE}\n"
${MKBOOTFS} ${RAMDISK_PATH} | ${MINIZIP} > ${RAMDISK}
${MKBOOTIMG} --sign-with isu  --bootstub out/target/product/redhookbay/bootstub --kernel ${KERNEL} --ramdisk ${RAMDISK}       --cmdline "${CMDLINE_BOOT}" --type mos      --output ${ANDROIDOUT}/boot.img
#vendor/intel/support/mkbootimg --sign-with isu --bootstub out/target/product/redhookbay/bootstub  --kernel out/target/product/redhookbay/kernel --ramdisk out/target/product/redhookbay/ramdisk.img --cmdline "init=/init pci=noearly console=ttyS0 console=logk0 earlyprintk=nologger loglevel=4 kmemleak=off ptrace.ptrace_can_access=1 androidboot.bootmedia=sdcard androidboot.hardware=redhookbay androidboot.spid="xxxx:xxxx:xxxx:xxxx:xxxx:xxxx" androidboot.serialno=01234567890123456789012345678901 ip=50.0.0.2:50.0.0.1::255.255.255.0::usb0:on nmi_watchdog=panic softlockup_panic=1 vmalloc=172M" --type mos --output out/target/product/redhookbay/boot.img
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/boot.img ${USER_OUT};fi

#
# Quick Make Recovery Image
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Recovery Ramdisk & Image... ${GE}\n"
${MKBOOTFS} ${RAMDISK_RECO_PATH} | ${MINIZIP} > ${RAMDISK_RECO}
${MKBOOTIMG} --sign-with isu  --bootstub out/target/product/redhookbay/bootstub --kernel ${KERNEL} --ramdisk ${RAMDISK_RECO}  --cmdline "${CMDLINE_RECO}" --type recovery --output ${ANDROIDOUT}/recovery.img
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/recovery.img ${USER_OUT};fi

#
# Quick Make Droidboot & Droidboot.POS
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Droidboot Ramdisk & Image... ${GE}\n"
${MKBOOTFS} ${RAMDISK_DROID_PATH} | ${MINIZIP} > ${RAMDISK_DROID}
${MKBOOTIMG} --sign-with isu --bootstub out/target/product/redhookbay/bootstub  --kernel ${KERNEL} --ramdisk ${RAMDISK_DROID} --cmdline "${CMDLINE_FAST}" --type droidboot --output ${ANDROIDOUT}/droidboot.img
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/droidboot.img ${ANDROIDOUT}/droidboot.img.POS.bin ${USER_OUT};fi

for i in $(seq 1)
do
	#/usr/bin/beep -f 800 -l 125 -D 125 -r 2
	/usr/bin/beep
	sleep 0.5
done
