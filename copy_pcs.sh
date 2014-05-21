#!/bin/bash

def_colors () {
        # 特性
        normal='\033[0m';       bold='\033[1m';         dim='\033[2m';          under='\033[4m';
        italic='\033[3m';       noitalic='\033[23m';    blink='\033[5m';
        reverse='\033[7m';      conceal='\033[8m';      nobold='\033[22m';
        nounder='\033[24m';     noblink='\033[25m';
        # 前景
        black='\033[30m';       red='\033[31m';         green='\033[32m';       yellow='\033[33m';
        blue='\033[34m';        magenta='\033[35m';     cyan='\033[36m';        white='\033[37m';
        # 背景
        bblack='\033[40m';      bred='\033[41m';
        bgreen='\033[42m';      byellow='\033[43m';
        bblue='\033[44m';       bmagenta='\033[245m';
        bcyan='\033[46m';       bwhite='\033[47m';
}

init () {
	PRODUCTS=`ls -lh pcs/ | awk -F ' ' '{print $9}'`
	PRODUCTS_LIST=( `echo $PRODUCTS` )
}

def_colors
init

if [[ -z ${ANDROID_BUILD_TOP} ]]
then
	echo -e "\n${red}Please set up android build env first...${normal}"
	exit 1
fi

pushd ${ANDROID_BUILD_TOP}
# init the products list under /pcs directory...
i=0
step=1
echo -e "${yellow}PRODUCT LIST IN PCS${normal}:"
for product in ${PRODUCTS}
do
	echo -e "\t[${i}] ${cyan}${product}${normal}"
	i=`expr ${i} + ${step}`
done

# select which product's overlay files while be copied...
while :
do
	if read -n 1 -p "Which key you will use?[] "
	then
		if ((${REPLY}>=${i}))
		then
			echo -e "\n${red}Wrong num...${normal}"
			continue
		else
			COPY=`echo ${PRODUCTS_LIST[${REPLY}]}`
			break
		fi
	fi
done

COPYPATH="pcs/${COPY}/overlay/*"
echo -e "\n${bblue}Copy ${normal}${byellow}${red}${COPYPATH}${normal}${bblue} to base code...${normal}"

# Copying....
cp -rfv ${COPYPATH} ./
popd
