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

def_colors

# 显示所有 git project 的状态
#repo forall -c 'echo "\n${PWD}:";git status'

# 恢复干净的代码环境
repo forall -c 'echo "\n${PWD}:";git clean -f -d;git reset --hard HEAD'

# 恢复到3天前的代码线
#repo forall -c 'HAHA=`git log --before="3 days" -1 --pretty=format:"%H"`;git reset --hard $HAHA'
