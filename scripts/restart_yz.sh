#!/bin/bash
process_details=`ps -ef|grep tcore|grep -v grep |awk '{print $9}'|awk -F'=' '{print $2}'|sort |uniq`
echo -e "\e[32m\e[1m进程详情:\e[0m"
echo -e "\e[32m\e[1m$process_details\e[0m"
read -p "Please input restart process:" process
count=`ps -ef | grep tcore | grep -v grep | grep $process | wc -l ` 
all_process=`ps -ef | grep tcore | grep -v grep | grep $process`

if  [ $count != 1 ];then 
	echo "$all_process"
	read -p "Please input restart subprocess port :" subprocess_port
	pid=`ps -ef | grep tcore | grep -v grep | grep $process | grep -w  $subprocess_port | awk '{print $2}'`
	subprocess=`ps -ef | grep tcore | grep -v grep | grep $process | grep -w $subprocess_port | awk '{for(i=8;i<=NF;i++)printf $i""FS;print""}'`
	kill -9 $pid
	ps -p $pid >/dev/null 2>&1
	if [ $? != 0 ];then
		$subprocess
	elif [ $? == 0 ];then
		echo "process no kill"
	fi
	
elif [ $count == 1 ];then
	pid=`ps -ef | grep tcore | grep -v grep | grep $process | awk '{print $2}'`
	subprocess=`ps -ef | grep tcore |grep -v grep | grep $process | awk '{for(i=8;i<=NF;i++)printf $i""FS;print""}'`
	kill -9 $pid
	ps -p $pid >/dev/null 2>&1
	if [ $? != 0 ];then
		$subprocess
	elif [ $? == 0 ];then
		echo "process no kill"
	fi
	
fi
