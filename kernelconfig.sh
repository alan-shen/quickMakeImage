#!/bin/bash 

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
if [ -z ${ANDROID_BUILD_TOP} ];then
    echo -e "\n${RP}ERROR: Plz create android build env first... ${RE}\n"
    echo -e "\t${RP} # source build/envsetup.sh;lunch xx;./${SCRIPTNAME}${RE}\n\n"
    exit 1
fi

echo -e "\n${RP}......KERNEL CONFIG......${RE}"
pushd ${ANDROID_BUILD_TOP}
CROSS_COMPILE=x86_64-linux-android- PATH=${PATH}:${ANDROID_BUILD_TOP}/prebuilts/gcc/linux-x86/x86/x86_64-linux-android-4.7/bin CCACHE_SLOPPINESS= make SHELL=/bin/bash -C linux/kernel ARCH=i386 INSTALL_MOD_PATH=modules_install INSTALL_MOD_STRIP=1 DEPMOD=/bin/true ANDROID_TOOLCHAIN_FLAGS=-mno-android O=../../out/target/product/redhookbay/linux/kernel menuconfig -j4
popd

