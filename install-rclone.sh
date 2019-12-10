#!/bin/bash

BASE_PATH=$(cd `dirname $0`; pwd)
WORK_PATH="/root/rclone-tmp"
DRIVE_NAME=
MNT_FORCE=
MNT_LOCAL_PATH=
MNT_REMOT_PATH=
START_ON_BOOT=

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
    
    #nohup rclone mount ${DRIVE_NAME}:${MNT_REMOT_PATH} ${MNT_LOCAL_PATH} \
    #    --copy-links --no-gzip-encoding --no-check-certificate \
    #    --allow-other --allow-non-empty --umask 000 \
    #    >/dev/null 2>&1 &
}

function generate_systemd_script()
{
    print_color ${COLOR_SYSTEM} "start rclone mount on boot system: "
    print_color ${COLOR_SYSTEM} "y) Yes"
    print_color ${COLOR_SYSTEM} "n) No"
    print_color ${COLOR_SYSTEM} "default No"
    read -p "$(print_color ${COLOR_SYSTEM} 'y/n> ')" START_ON_BOOT
    if [ "${START_ON_BOOT}" == "y" ] || [ "${START_ON_BOOT}" == "Y" ];
    then
        script_file=/etc/systemd/system/rclone.service
    else
        script_file=${BASE_PATH}"/rclone.service"
    fi
 
    echo "[Unit]" > ${script_file}
    echo "Description=Rclone" >> ${script_file}
    echo "After=network-online.target" >> ${script_file}
    echo "" >> ${script_file}
    echo "[Service]" >> ${script_file}
    echo "Type=simple" >> ${script_file}
    echo "User=root" >> ${script_file}
    echo "Restart=on-abort" >> ${script_file}
    echo "ExecStart=/usr/bin/rclone mount ${DRIVE_NAME}:${MNT_REMOT_PATH} ${MNT_LOCAL_PATH} --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000" >> ${script_file}
    echo "" >> ${script_file}
    echo "[Install]" >> ${script_file}
    echo "WantedBy=default.target" >> ${script_file}
    
    if [ "${START_ON_BOOT}" == "y" ] || [ "${START_ON_BOOT}" == "Y" ];
    then
        systemctl start rclone
        systemctl enable rclone
    else
        nohup rclone mount ${DRIVE_NAME}:${MNT_REMOT_PATH} ${MNT_LOCAL_PATH} \
            --copy-links --no-gzip-encoding --no-check-certificate \
            --allow-other --allow-non-empty --umask 000 \
            >/dev/null 2>&1 &
    fi
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
    
    print_color ${COLOR_WARNING} "初始化工作目录开始..."
    init_path
    print_color ${COLOR_SUCCESS} "初始化工作目录完成."
    
    print_color ${COLOR_WARNING} "安装rclone开始..."
    install
    print_color ${COLOR_SUCCESS} "安装rclone完成."
    
    print_color ${COLOR_WARNING} "配置rclone开始..."
    configure
    print_color ${COLOR_SUCCESS} "配置rclone完成."
    
    print_color ${COLOR_WARNING} "挂载rclone开始..."
    mount_drive
    print_color ${COLOR_SUCCESS} "挂载rclone完成."
    
    print_color ${COLOR_WARNING} "设置开机启动开始..."
    generate_systemd_script
    print_color ${COLOR_SUCCESS} "设置开机启动完成"

    print_color ${COLOR_WARNING} "清理临时文件开始 ..."
    clear_work_path
    print_color ${COLOR_SUCCESS} "清理临时文件完成."
}

man
