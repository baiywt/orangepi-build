#!/bin/bash

cd /opt/linuxpg
#mac_head="c0:74:2b:ff"
mac_head=$(cat 8125BGEF.cfg |grep NODEID |awk -F '= ' '{print $2}' |sed 's/\s\+/:/g' |tr '[A-Z]' '[a-z]' |cut -b -11)

#efuse_write_cnt=$(./rtnicpg /efuse /r  /# 1 |grep Efuse |awk -F '=' '{print $2}')
#efuse_write_cnt=$(./rtnicpg /efuse /r  /# 1 |grep Efuse |awk -F '=' '{print $2}')
#./rtnicpg /efuse /r  /# 1 |grep NODEID |awk -F '= ' '{print $2}' |sed 's/\s\+/:/g' |tr '[A-Z]' '[a-z]'

function go_loop()
{
	while true
	do
	        sleep 3
	        :
	done
}

function display_alert()
{

        local tmp=""
        [[ -n $2 ]] && tmp="[\e[0;33m $2 \x1B[0m]"

        case $3 in
                err)
                echo -e "[\e[0;31m error \x1B[0m] $1 $tmp"
                ;;

                wrn)
                echo -e "[\e[0;35m warn \x1B[0m] $1 $tmp"
                ;;

                ext)
                echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0m $tmp"
                ;;

                info)
                echo -e "[\e[0;32m o.k. \x1B[0m] $1 $tmp"
                ;;

                *)
                echo -e "[\e[0;32m .... \x1B[0m] $1 $tmp"
                ;;
        esac
}

eth_arr=($(ls /sys/class/net/ | grep "enP"))
eth_arr_len=${#eth_arr[@]}
eth_arr_all=${eth_arr[@]}
display_alert "Ethernet" "found ${eth_arr_len} ethernet card: ${eth_arr_all}" "info"

for((i=0;i<${eth_arr_len};i++));
do
        MAC=$(cat /sys/class/net/${eth_arr[i]}/address)
        if [[ $MAC =~  ${mac_head} ]];then
                display_alert "${eth_arr[i]}" "mac is already write !" "info"
		go_loop
        fi
done

display_alert "rmmod" "r8125 pgdrv"
lsmod |grep r8125 2>&1 > /dev/null && rmmod r8125
lsmod |grep pgdrv 2>&1 > /dev/null && rmmod pgdrv
modprobe pgdrv

display_alert "Ethernet" "start write mac..."

mac1=$(cat 8125BGEF.cfg | grep NODEID |awk -F '= ' '{print $2}' |sed 's/\s\+/:/g' |tr '[A-Z]' '[a-z]')
display_alert "Ethernet" "start write mac to phy 1: ${mac1}"
./rtnicpg /efuse /w /# 1 2>&1 > /dev/null

mac2=$(cat 8125BGEF.cfg | grep NODEID |awk -F '= ' '{print $2}' |sed 's/\s\+/:/g' |tr '[A-Z]' '[a-z]')
display_alert "Ethernet" "start write mac to phy 2: ${mac2}"
./rtnicpg /efuse /w /# 2 2>&1 > /dev/null

lsmod |grep pgdrv 2>&1 > /dev/null && rmmod pgdrv
display_alert "modprobe" " r8125 pgdrv"
modprobe r8125 pgdrv

eth_arr=($(ls /sys/class/net/ | grep "enP"))
eth_arr_len=${#eth_arr[@]}
eth_arr_all=${eth_arr[@]}

display_alert "Ethernet" "found ${eth_arr_len} ethernet card: ${eth_arr_all}" "info"

for((i=0;i<${eth_arr_len};i++));
do
        MAC=$(cat /sys/class/net/${eth_arr[i]}/address)
        if [[ $MAC =~  ${mac_head} ]];then
                display_alert "${eth_arr[i]}" "write mac successful: ${MAC}" "info"
        else
                display_alert "${eth_arr[i]}" "write mac fail ${MAC}" "err"
        fi
done

sync

go_loop
