#!/bin/bash
dir="$(cd $(dirname $0) && pwd)"
date=`date "+%Y-%m-%d"`
processs_count=`ps -ef | grep tcore | grep -v grep | wc -l`
if [ $processs_count == 0 ];then
	echo -e "\e[31m\e[1mtcore is not start!\e[0m"
else
	process_details=`ps -ef|grep tcore|grep -v grep |awk '{print $9}'|awk -F'=' '{print $2}'|sort |uniq -c`
	ps_details=`ps -ef|grep tcore |grep -v grep`
	echo -e "\e[32m\e[1m======================================================\e[0m"
	echo -e "\e[32m\e[1m进程总数:$processs_count\e[0m"
	echo -e "\e[32m\e[1m进程详情:\e[0m"
	echo -e "\e[32m\e[1m$process_details\e[0m"
	echo -e "\e[32m\e[1m======================================================\e[0m"
	echo "$ps_details"
	read -p "DO you want to tail error log?[y/n]:" flag
	
	if [ $flag == y ];then
		echo -e "\e[32m\e[1m========nowtailing error log!===================\e[0m"
		tail -f $dir/log/* | grep error	|grep $date
	fi
fi



