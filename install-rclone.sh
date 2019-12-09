#!/bin/bash

BASE_PATH=$(cd `dirname $0`; pwd)
WORK_PATH="/root/rclone-tmp"
DRIVE_NAME=
MNT_FORCE=
MNT_LOCAL_PATH=
MNT_REMOT_PATH=

COLOR_ERROR="31m"
COLOR_SUCCESS="32m"
COLOR_WARNING="33m"
COLOR_SYSTEM="34m"

function print_color()
{
    echo -e "\033[${1}${2}\033[0m"
}


function init_path()
{
    mkdir -p ${WORK_PATH}
    cd ${WORK_PATH}
}

function install()
{
    yum -y install fuse
    
    wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P ${WORK_PATH}
    unzip rclone-current-linux-amd64.zip
    cd rclone-*-linux-amd64
    cp -f rclone /usr/bin/
    
    mkdir -p /usr/local/share/man/man1
    cp -f rclone.1 /usr/local/share/man/man1/
    mandb
    
    cd ${BASE_PATH}
}

function configure()
{
    rclone config
}

function clear_work_path()
{
    if [ -d ${WORK_PATH} ];
    then
        rm -rf ${WORK_PATH}
    fi
    sleep 2
    df -h
}

function mount_drive()
{
    read -p "$(print_color ${COLOR_SYSTEM} 'please input drive name: ')" DRIVE_NAME
    read -p "$(print_color ${COLOR_SYSTEM} 'please input remote path: ')" MNT_REMOT_PATH
    read -p "$(print_color ${COLOR_SYSTEM} 'please input local path: ')" MNT_LOCAL_PATH
    
    while true
    do
        if [ -d ${MNT_LOCAL_PATH} ];
        then
            print_color ${COLOR_WARNING} "目录已存在，挂载会清空，确认是否仍然挂载到此目录: "
            print_color ${COLOR_SYSTEM} "y) Yes"
            print_color ${COLOR_SYSTEM} "n) No"
            print_color ${COLOR_SYSTEM} "default No"
            read -p "$(print_color ${COLOR_SYSTEM} 'y/n> ')" MNT_FORCE
            if [ "${MNT_FORCE}" == "y" ] || [ "${MNT_FORCE}" == "Y" ];
            then
                break
            else
                continue
            fi
        else
            mkdir -p ${MNT_LOCAL_PATH}
            break
        fi
    done
    
    nohup rclone mount ${DRIVE_NAME}:${MNT_REMOT_PATH} ${MNT_LOCAL_PATH} \
        --copy-links --no-gzip-encoding --no-check-certificate \
        --allow-other --allow-non-empty --umask 000 \
        >/dev/null 2>&1 &
}

function server_entrance()
{
    clear
    print_color ${COLOR_SYSTEM} ""
    print_color ${COLOR_SYSTEM} ".......... openvpn client by WSHUAI .........."
    print_color ${COLOR_SYSTEM} ""
}

function man()
{
    server_entrance
    init_path
    install
    configure
    mount_drive
    clear_work_path
}

man
