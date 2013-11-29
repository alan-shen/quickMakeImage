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

####################################################################################################################
# Intel Soc Boot Mode(IA):
#+++++++++++++++++++++++++
#                                      +--------------------------+
#                                      |                          |
#                                      |     FW Boot Seq ...      |-----------------------
#                                      |                          |                       |
#                                      +--------------------------+                       |
#                                      |        |                 |                       |
#                                      |[POWER] |[POWER + VOL_UP] |[POWER + VOL_DOWN]     |
#                                      |        |                 |                       |
#                   ___________________/        |                 \__________________     |
#                  /                            |                                    \    |
#                  |                            |                                    |    |
#   ...............|............................|....................................|....|..................................
#                  |                            |                                    |    | [Boot/Droidboot/Recovery/Logo]
#                  |                            |                                    |    | [ALL Load By FW]
#                  |                            |                                    |    | [Need [ISU +] XFSTK-STITCHER] 
#                  |                            |                                    |    |  
#                  |  __________________________|____________________________________|___ |______________________
#                  |  |                         |                                    |  |                        |
#                  |  |  _______________________|__________________________________  |  |                        |
#                  |  |  |                   |  |                                 |  |  |                        |
#                  |  |  |  _________________|__|__ ____________________________  |  |  |                        |
#                  |  |  |  |                |  |  Y                           |  |  |  |                        |
#                  |  |  |  |                |  |  |                           |  |  |  |                        |
#                  |  |  |  |                |  |  |                           |  |  |  |                        |
#                  V  V  |  V                V  V  |                           V  V  V  |                        V
#    +--------------------------+      +--------------------------+      +--------------------------+    +--------------+
#    |        Normal Boot       |      |      Droidboot Mode      |      |      Recovery Mode       |    |  LOGO IMAGE  |
#    +--------------------------+      +--------------------------+      +--------------------------+    +--------------+
#                  |
#                  |
#                  |
#   ...............|...............................................................................
#                  |    [System/Data/Cache/Logs/...]
#                  |    [Are Load or Mount By Linux Kernel, So No Need to Do [ISU +] XFSTK-STITCHER ]
#                  |
#    +-------------V------------+
#    |                          |
#    |                          |
#    |                          |
#    |     SYSTEM(Android SYS)  |
#    |                          |
#    |                          |  
#    |                          |
#    +--------------------------+
#
####################################################################################################################
# DV logo/boot/recovery/droidboot Make Steps:
#++++++++++++++++++++++++++++++++++++++++++++
#
#                        MAKEFILE
#
#                        +-------------------------------+ \
#                        | kernel???(build/core/xxx)     | |
#                        +-------------------------------+ |
#                                                          >>>-+
#                        +-------------------------------+ |   |
#                        | vendor/intel/build/tasks/*.mk | |   |
#                        +-------------------------------+ /   |
#                                                               \       TOOL (SCRIPT)(SHELL/PAYTHON)
#                                                                \
#                                                                 +--------------------------------+     
#                                                                 | vendor/intel/support/mkbootimg |>>>-----+
#                                                                 +--------------------------------+        |
#                                                                                                           |
#                                                                                                           |
#                                                                 +---------------------------------+ \     |
#                                        _________________________|                                 | |     |
#                                       /                         | vendor/intel/support/stitch.sh  | |     |
#                                       |                         +---------------------------------+ |     |
#                                       |                                                             ><<---+
#                                       |                         +-----------------------------+---+ |     
#                                       |                      ___|                             |   | |     
#                                       |                     /   | vendor/intel/support/gen_os |   | |    
#                                       |                     |   +-----------------------------+---+ /
#      [Automatic IN Android Build]     |                     |
#     ..................................+.....................+......................................................
#      [Manual]                         |                     | 
#                                      \|/                   \|/
#                                       v                     v 
#                        #################################################################    
#                        #     STITCH   #          INPUT      #          OUTPUT          #                  
#                        #################################################################    
#                                       +------------------+        +-------------+
#                                       |          logo.bmp|        |     logo.img|
#                        0.BOOTSTUB\    +------------------+        +-------------+    
#                         1.KERNEL |    +------------------+        +-------------+
#                        /2.CMDLINE|>>>>|     boot.unsigned|>>>>>>>>|     boot.bin|
#          boot_cmdline -|         |    | recovery.unsigned|    ^   | recovery.img|
#      recovery_cmdline -|         |    |droidboot.unsigned|   /|\  |droidboot.img|
#     droidboot_cmdline -/         |    +------------------+    |   +-------------+-------+
#                                  |                            |   |droidboot.img.POS.bin|
#                        /3.RAMDISK/                            |   +---------------------+
#           ramdisk.img -|                                      |
#  ramdisk-recovery.img -|                                      |
# ramdisk-droidboot.img -/                                      |
#                                                               |
#                                    ___________________________/
#                                   /
#                 ++++++++++++++++++
#                 + xfstk-stitcher +
#                 ++++++++++++++++++ +----------------------------------------------+
#                                    | 1= x86 firmware software tool kit            |
#                                    | 2= SRC - /device/intel/xfstk-stitcher        |
#                                    | 3= CONFIG & XML...                           |
#                                    +----------------------------------------------+
# 
####################################################################################################################
# PV logo/boot/recovery/droidboot Make Steps:
#++++++++++++++++++++++++++++++++++++++++++++
#                                                                                           
#                        ###################################################################################           
#                        #     STITCH   #          INPUT      #       MIDDLE FILE        #        OUTPUT   #                  
#                        ###################################################################################           
#                                       +------------------+     +--------------------+      +-------------+
#                                       |          logo.bmp|     |     signed_logo.img|      |     logo.img|       
#                        0.BOOTSTUB\    +------------------+     +--------------------+      +-------------+
#                         1.KERNEL |    +------------------+     +--------------------+      +-------------+
#                        /2.CMDLINE|>>>>|     boot.unsigned|>>>>>|     signed_boot.bin|>>>>>>|     boot.bin|
#          boot_cmdline -|         |    | recovery.unsigned|  ^  | signed_recovery.img|  ^   | recovery.img|
#      recovery_cmdline -|         |    |droidboot.unsigned| /|\ |signed_droidboot.img| /|\  |droidboot.img|
#     droidboot_cmdline -/         |    +------------------+  |  +--------------------+  |   +-------------+-------+
#                                  |                          |                          |   |droidboot.img.POS.bin|
#                        /3.RAMDISK/                          |                          |   +---------------------+
#           ramdisk.img -|                                    |                          |
#  ramdisk-recovery.img -|                                    |                          |
# ramdisk-droidboot.img -/            ________________________/                          |
#                                    /                                                   |
#                                   /                                                    |
#                          +++++++++                                                     | 
#                          +  ISU  +                                                     |
#                          +++++++++ +----------------------------------------------+    |
#                                    | 1= ISU - Intel Signing Utility               |    |
#                                    | 2= SRC - /device/intel/intel_signing_utility |    |
#                                    | 3= KEY - "./key/key.pem"                     |    |
#                                    +----------------------------------------------+    |
#                                                                                        |
#                                    ____________________________________________________/
#                                   /
#                 ++++++++++++++++++
#                 + xfstk-stitcher +
#                 ++++++++++++++++++ +----------------------------------------------+
#                                    | 1= x86 firmware software tool kit            |
#                                    | 2= SRC - /device/intel/xfstk-stitcher        |
#                                    | 3= CONFIG & XML...                           |
#                                    +----------------------------------------------+
#
####################################################################################################################
#                        
#                                    [BOOT|RECOVERY|DROIDBOOT].UNSIGNED Structure    
#         [DV | PV] STITCH                        
#                                    +==============+=============+============+=============+==================+
#                                    |        START |         END |       SIZE |  Total Size |             FLAG |
#                                    +==============+=============+============+=============+==================+
#                                    |  0x0000 0000 |             |            |             |          CMDLINE |
#                                    |              | 0x0000 03FF | 1024 Bytes |             |   + Zero Padding |
#                                    +--------------+-------------+------------+             |------------------+
#                                    |  0x0000 0400 | 0x0000 0403 |    4 Bytes |             |      Kernel Size |
#                                    |  0x0000 0404 | 0x0000 0407 |    4 Bytes |   4 K Bytes |     Ramdisk Size |
#                                    |  0x0000 0408 | 0x0000 040B |    4 Bytes |             |               $5 |
#                                    |  0x0000 040C | 0x0000 040F |    4 Bytes |             |               $6 |
#                                    +--------------+-------------+------------+             |------------------+
#                                    |  0x0000 0410 |             |            |             |                  |
#                                    |              | 0x0000 0FFF | 3056 Bytes |             |   + Zero Padding |
#                                    +==============+=============+============+=============+==================+
#                                    |  0x0000 1000 |             |                          |         BOOTSTUB |
#                                    |              | 0x0000 1FFF |         4 K Bytes        |   + Zero Padding |
#                                    +==============+=============+==========================+==================+
#                                    |  0x0000 2000 |             |                          |           KERNEL |
#                                    |              | 0xXXXX XXXX |        XXXX Bytes        |        + RAMDISK |
#                                    +==============+=============+==========================+==================+
#                        
####################################################################################################################
#                        
#                                    SIGNED_[BOOT|RECOVERY|DROIDBOOT].[BIN|IMG] Structure??   
#         [PV] ISU                        
#                                    +==============+=============+============+=============+==================+
#                                    |        START |         END |       SIZE |  Total Size |             FLAG |
#                                    +==============+=============+============+=============+==================+
#                                    |  0x0000 0000 |             |                          |                  |
#                                    |              | 0x0000 01DF |         480 Bytes        |       ISU HEADER |
#                                    +==============+=============+==========================+==================+
#                                    |              |             |                          |                  |
#                                    |              |             |                          |     xxx.UNSIGNED |
#                                    |              |             |                          |               +  |
#                                    |              |             |                          |   "0xFF" PADDING |
#                                    |              |             |                          |                  |
#                                    +==============+=============+==========================+==================+
#                        
#                        
#                                    [BOOT|RECOVERY|DROIDBOOT].[BIN|IMG] Structure??  
#         [PV] ISU + XFSTK-STITCHER                        
#                                    +==============+=============+============+=============+==================+
#                                    |        START |         END |       SIZE |  Total Size |             FLAG |
#                                    +==============+=============+============+=============+==================+
#                                    |  0x0000 0000 |             |                          |                  |
#                                    |              | 0x0000 01FF |         512 Bytes        |XFSTK HEADER(55AA)|
#                                    +==============+=============+==========================+==================+
#                                    |              |             |                          |                  |
#                                    |              |             |                          |       SIGNED_xxx |
#                                    |              |             |                          |               +  |
#                                    |              |             |                          |   "0xFF" PADDING |
#                                    |              |             |                          |                  |
#                                    +==============+=============+==========================+==================+
#                        
####################################################################################################################
#                        
#                                    SIGNED_[BOOT|RECOVERY|DROIDBOOT].[BIN|IMG] Structure??   
#         [DV] XFSTK-STITCHER                        
#                                    +==============+=============+============+=============+==================+
#                                    |        START |         END |       SIZE |  Total Size |             FLAG |
#                                    +==============+=============+============+=============+==================+
#                                    |  0x0000 0000 |             |                          |                  |
#                                    |              | 0x0000 01FF |         512 Bytes        |XFSTK HEADER(55AA)|
#                                    +==============+=============+==========================+==================+
#                                    |              |             |                          |                  |
#                                    |              |             |                          |     xxx.UNSIGNED |
#                                    |              |             |                          |                + |
#                                    |              |             |                          |   "0xFF" PADDING |
#                                    |              |             |                          |                  |
#                                    +==============+=============+==========================+==================+
#                        
####################################################################################################################

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
# Quick Make Partition(NOTE: !!!First step, must done before make ramdisk!!!)
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Partition Table... ${GE}\n"

MAKEPART=./vendor/intel/support/partition.py
DEFAULT_PARTITION=./vendor/intel/common/storage/default_partition.json
DEFAULT_MOUNT=./vendor/intel/common/storage/default_mount.json
PART_MOUNT_OVERRIDE_FILE=./vendor/intel/clovertrail/storage/part_mount_override.json
PART_MOUNT_OUT="out/target/product/redhookbay"
TARGETDEVICE="redhookbay"

# Debug
if [ -e "./partition" ];then
	echo -e "HAD BACKUP THE PARTITION..."
else
	echo -e "INITIAL PARTITION FOR DIFF..."
	mkdir -p ./partition/root
	mkdir -p ./partition/droidboot/root/system/etc
	mkdir -p ./partition/recovery/root/etc
	cp -rf ${PART_MOUNT_OUT}/root/fstab.redhookbay                    ./partition/root/fstab.redhookbay
	cp -rf ${PART_MOUNT_OUT}/root/fstab.charger.redhookbay            ./partition/root/fstab.charger.redhookbay
	cp -rf ${PART_MOUNT_OUT}/partition.tbl                            ./partition/partition.tbl
	cp -rf ${PART_MOUNT_OUT}/recovery/root/fstab.redhookbay           ./partition/recovery/root/fstab.redhookbay
	cp -rf ${PART_MOUNT_OUT}/recovery/root/etc/recovery.fstab         ./partition/recovery/root/etc/recovery.fstab
	cp -rf ${PART_MOUNT_OUT}/droidboot/root/fstab.redhookbay          ./partition/droidboot/root/fstab.redhookbay
	cp -rf ${PART_MOUNT_OUT}/droidboot/root/system/etc/recovery.fstab ./partition/droidboot/root/system/etc/recovery.fstab
	echo;echo
fi
# Debug

OUTFILE_LIST="root/fstab.redhookbay root/fstab.charger.redhookbay partition.tbl recovery/root/fstab.redhookbay recovery/root/etc/recovery.fstab droidboot/root/fstab.redhookbay droidboot/root/system/etc/recovery.fstab"

for outfile in ${OUTFILE_LIST}
do
	echo -e "\n${GP}>>PARTITION : ${outfile} ${GE}\n"
	# NOTE: "PART_MOUNT_OUT_FILE" will use in partition.py!!
	PART_MOUNT_OUT_FILE=${PART_MOUNT_OUT}/${outfile}
	export PART_MOUNT_OUT_FILE
	${MAKEPART} ${DEFAULT_PARTITION} ${DEFAULT_MOUNT} ${PART_MOUNT_OVERRIDE_FILE} ${PART_MOUNT_OUT} ${TARGETDEVICE}
	#if [ $? -eq 0 ];then cp ${PART_MOUNT_OUT_FILE} ${USER_OUT}/partition;fi
done

# Debug
echo;echo
mkdir -p ${USER_OUT}/partition/root
mkdir -p ${USER_OUT}/partition/droidboot/root/system/etc
mkdir -p ${USER_OUT}/partition/recovery/root/etc
cp -rf ${PART_MOUNT_OUT}/root/fstab.redhookbay                    ${USER_OUT}/partition/root/fstab.redhookbay
cp -rf ${PART_MOUNT_OUT}/root/fstab.charger.redhookbay            ${USER_OUT}/partition/root/fstab.charger.redhookbay
cp -rf ${PART_MOUNT_OUT}/partition.tbl                            ${USER_OUT}/partition/partition.tbl
cp -rf ${PART_MOUNT_OUT}/recovery/root/fstab.redhookbay           ${USER_OUT}/partition/recovery/root/fstab.redhookbay
cp -rf ${PART_MOUNT_OUT}/recovery/root/etc/recovery.fstab         ${USER_OUT}/partition/recovery/root/etc/recovery.fstab
cp -rf ${PART_MOUNT_OUT}/droidboot/root/fstab.redhookbay          ${USER_OUT}/partition/droidboot/root/fstab.redhookbay
cp -rf ${PART_MOUNT_OUT}/droidboot/root/system/etc/recovery.fstab ${USER_OUT}/partition/droidboot/root/system/etc/recovery.fstab
mkdir -p ${USER_OUT}/partition_original
cp -rf ./partition/* ${USER_OUT}/partition_original
echo;echo
# Debug

#
# Quick Make Boot Image
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Boot Ramdisk & BIN... ${GE}\n"
${MKBOOTFS} ${RAMDISK_PATH} | ${MINIZIP} > ${RAMDISK}
${MKBOOTIMG} --sign-with isu  --kernel ${KERNEL} --ramdisk ${RAMDISK}       --cmdline "${CMDLINE_BOOT}" --product redhookbay --type mos                   --output ${ANDROIDOUT}/boot.bin
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/boot.bin ${USER_OUT};fi

#
# Quick Make Recovery Image
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Recovery Ramdisk & Image... ${GE}\n"
${MKBOOTFS} ${RAMDISK_RECO_PATH} | ${MINIZIP} > ${RAMDISK_RECO}
${MKBOOTIMG} --sign-with isu  --kernel ${KERNEL} --ramdisk ${RAMDISK_RECO}  --cmdline "${CMDLINE_RECO}" --product redhookbay --type recovery              --output ${ANDROIDOUT}/recovery.img
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/recovery.img ${USER_OUT};fi

#
# Quick Make Droidboot & Droidboot.POS
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Droidboot Ramdisk & Image... ${GE}\n"
${MKBOOTFS} ${RAMDISK_DROID_PATH} | ${MINIZIP} > ${RAMDISK_DROID}
${MKBOOTIMG} --sign-with isu  --kernel ${KERNEL} --ramdisk ${RAMDISK_DROID} --cmdline "${CMDLINE_FAST}" --product redhookbay --type droidboot             --output ${ANDROIDOUT}/droidboot.img
if [ $? -eq 0 ];then cp ${ANDROIDOUT}/droidboot.img ${ANDROIDOUT}/droidboot.img.POS.bin ${USER_OUT};fi
set -x
diff ${ANDROIDOUT}/droidboot.img ${ANDROIDOUT}/droidboot.img.POS.bin
set +x

#
# Quick Make LOGO Image
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Make Logo Image... ${GE}\n"
LOGO=prebuilts/intel/device/intel/prebuilts/fw/logo/logo.bmp
LOGO_OUTPUT_IMG=logo.img
ORIGINAL_LOGO_CNF=device/intel/xfstk-stitcher/share/xfstk-stitcher/logo-config.txt
ORIGINAL_LOGO_XML=device/intel/xfstk-stitcher/share/xfstk-stitcher/logo-platform.xml
XFSTK_STITCHER=device/intel/xfstk-stitcher/bin/xfstk-stitcher
#LOGO_ESCAPEDPATH=${LOGO_OUTPUT_IMG//\//\\\/}
LOGO_ESCAPEDPATH=${LOGO_OUTPUT_IMG}
MAJOR_REV=1
if [ -e ${LOGO} ] && [ -e ${ORIGINAL_LOGO_CNF} ] && [ -e ${ORIGINAL_LOGO_XML} ] ; then
	# prepare 3 files for make logo image
	cp -rf ${LOGO} ./logo.bmp
	sed "s/INPUTFILE_ABCD/${LOGO_ESCAPEDPATH}/"     ${ORIGINAL_LOGO_XML} > ./platform.xml
	sed "s/OUTPUTFILENAME_ABCD/${LOGO_OUTPUT_IMG}/" ${ORIGINAL_LOGO_CNF} > ./config.txt
	sed -i "s/MAJOR_REV_ABCD/${MAJOR_REV}/"                                ./platform.xml
	# do stitcher-xfstk
	${XFSTK_STITCHER} -k ./platform.xml -c ./config.txt
	# copy logo.img to directory USER_OUT
	if [ $? -eq 0 ];then mv ./logo.img ${USER_OUT};fi
	# remove 3 files for make logo
	rm -rfv ./logo.bmp ./platform.xml ./config.txt
else
	echo -e "\n\t${RP}WARNNING: Can't find LOGO BMP( ${LOGO} )!${RE}\n"
	ls -lh --color ${LOGO} ${ORIGINAL_LOGO_CNF} ${ORIGINAL_LOGO_XML} | grep "No such file or directory"
fi

#
# CMDLINE
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}CMDLINE FILE PATH... ${GE} ${RP}HOW to Modify cmdline${RE}\n...........................................\n"
echo -e "${GP}CMDLINE BASE:${GE}"
echo -e "${RP}vendor/intel/clovertrail/board/redhookbay/BoardConfig.mk - BOARD_KERNEL_CMDLINE ${RE}\n"
echo -e "${GP}RECOVERY CMDLINE:${GE}"
echo -e "${RP}vendor/intel/build/tasks/Recovery_Ota.mk - INTERNAL_RECOVERYIMAGE_ARGS += --cmdline BOARD_KERNEL_CMDLINE ${RE}\n"
echo -e "${GP}DROIDBOOT CMDLINE:${GE}"
echo -e "${RP}vendor/intel/clovertrail/BoardConfig.mk  - DROIDBOOT_SCRATCH_SIZE := 100 ${RE}"
echo -e "${RP}vendor/intel/clovertrail/BoardConfig.mk  - BOARD_KERNEL_DROIDBOOT_EXTRA_CMDLINE += g_android.fastboot=1 ${RE}"
echo -e "${RP}vendor/intel/clovertrail/BoardConfig.mk  - BOARD_KERNEL_DROIDBOOT_EXTRA_CMDLINE += droidboot.scratch=DROIDBOOT_SCRATCH_SIZE ${RE}"
echo -e "${RP}vendor/intel/build/tasks/Droidboot.mk    - INTERNAL_DROIDBOOTIMAGE_ARGS += --cmdline BOARD_KERNEL_CMDLINE BOARD_KERNEL_DROIDBOOT_EXTRA_CMDLINE ${RE}\n"

#
# Flash Package
#
echo -e "${RP}================================================================================================${RE}"
echo -e "${GP}Flash Package Make... ${GE}\n"
echo -e "${RP}make blank_flashfiles -j4${RE}"
echo -e "${RP}make flashfiles -j4${RE}"
echo -e "${RP}make -j40 blank_flashfiles flashfiles (CM Use)${RE}"



#
# #### END ####
#
MAKEIMAGE_ENDTIME=`date +%H:%M:%S`
#echo -e "\n\n"
#echo -e "\t${GP}Dear [${GE}${RP}${USER}${RE}${GP}], everything is complete now... ${GE}"
#echo -e "                                             \`-------------------------------+                "
#echo -e "                                                                             |                 "
#echo -e "                                                                             V                 "
echo -e "                                                                              +----------------+"
echo -e "                                                                              | ${AP}START${AE} ${RP}${MAKEIMAGE_STARTTIME}${RE} |"
echo -e "                                                                              | ${AP}  END${AE} ${RP}${MAKEIMAGE_ENDTIME}${RE} |"
echo -e "                                                                              +----------------+\n"
echo -e "                                                 ${RP}...............................................${RE}"
echo -e "                                                 ${AP}[DV] QUICK MAKE  BOOT/RECOVERY/DROIDBOOT IMAGES${AE}"
echo -e "${RP}================================================================================================${RE}"

#
# List Output Files
#
ls -lth --color ${USER_OUT};echo
#echo -e "${BP}CMDLINE_BOOT${BE}\n${CMDLINE_BOOT}\n"
#echo -e "${BP}CMDLINE_RECO${BE}\n${CMDLINE_RECO}\n"
echo -e "${BP}CMDLINE_FAST${BE}\n${CMDLINE_FAST}\n"
echo -e "${RP}================================================================================================${RE}"

#
# TODO List
#
echo
echo -e "${GP}QUESTION${GE} ${RP}: WHAT'S THE MEANING OF PARTITION FILE?(Done.)(partion.tbl is used in droidboot for format eMMC.)${RE}"
echo -e "${GP}QUESTION${GE} ${RP}: HOW TO MAKE FIRMWARE??(Just Copy???)${RE}"
echo
echo -e "${BP}WORK THIS WEEK${BE} ${RP}: TO MAKE PV OTA(Acer Ducati)${RE}"
echo
echo -e "${AP}TODO${AE} ${RP}: HOW TO MAKE Flash.xml(Need??) and flash package(???)${RE}"
echo
echo -e "${RP}================================================================================================${RE}"

for i in $(seq 1)
do
	#/usr/bin/beep -f 800 -l 125 -D 125 -r 2
	/usr/bin/beep
	sleep 0.5
done
