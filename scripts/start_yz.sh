#!/bin/bash
server_dir="/opt/monster"
cd $server_dir
#内网
eth0=`/sbin/ifconfig eth0|awk -F '[ :]+' 'NR==2{print $4}'`
#外网
eth1=`/usr/bin/curl -s -I http://www.alibaba.com | grep ali_apache_id |awk 'BEGIN{FS="[=.]";ORS="."} {for(i=2;i<=5;i++)print $i;printf "\n"}'|cut -d "." -f 1-4`
if [ -z $eth1 ];then
	read -p "Please input eth1:" eth1
fi
#local
local="0.0.0.0"
date=`date "+%Y-%m-%d-%H:%M:%S"`
sed -i '/start.sh/s/^#*//g' /var/spool/cron/root >/dev/null 2>&1
launch_dir="$(cd $(dirname $0) && pwd)"
cd $launch_dir


master(){
	process_master=`ps -ef |grep tcore|grep -v grep|grep master|wc -l`
		if [[ $process_master = "0" ]]
			then
				./tcore --name=master &
				echo "master ok!"
				echo "$date master is start">>/var/log/tcore_guard.log
			else
				echo "master is running"
		fi
	sleep 1
}

relation(){
	relation_port="5200"
	relation_count=`cat /etc/environment.yw | grep relation | awk -F":" '{print $2}'`
	flag=`expr $relation_count - 1`
	for i in `seq 0 $flag`
	do
		port=`expr $relation_port + $i`
		process_relation_1=`ps -ef | grep tcore | grep -v grep | grep relation | grep -w $port | wc -l`
			if [[ $process_relation_1 = "0" ]]
				then
					./tcore --name=relation --lan_ip=$eth0 --lan_port=$port &
					echo "relation-1 ok"
					echo "$date relation-1 is start">>/var/log/tcore_guard.log
				else
					echo "relation-1 is running"
			fi
	done
	sleep 1
}

balance()
{
	balance_port="6200"
	balance_count=`cat /etc/environment.yw | grep balance | awk -F":" '{print $2}'`
	flag=`expr $balance_count - 1`
	for i in `seq 0 $flag`
	do
		port=`expr $balance_port + $i`
		process_balance=`ps -ef |grep tcore| grep -v grep|grep balance|grep -w $port|grep -w 1$port|wc -l`
			if [[ $process_balance = "0" ]]
				then
					./tcore --name=balance --lan_ip=$eth0 --lan_port=$port --door_ip=$eth1 --door_port=1$port &
					echo "balance ok"
					echo "$date balance is start">>/var/log/tcore_guard.log
				else
					echo "balance is running"
			fi
	done
	sleep 1
}

gate()
{
	gate_port="7200"
	gate_count=`cat /etc/environment.yw | grep gate | awk -F":" '{print $2}'`
	flag=`expr $gate_count - 1`
	for i in `seq 0 $flag`
	do
		port=`expr $gate_port + $i`
		process_gate_1=`ps -ef |grep tcore| grep -v grep|grep gate|grep -w $port|grep -w 1$port|wc -l`
			if [[ $process_gate_1 = "0" ]]
				then
					./tcore --name=gate --lan_ip=$eth0 --lan_port=$port --door_ip=$eth1 --door_port=1$port &
					echo "gate1 ok"
					echo "$date gate-1 is start">>/var/log/tcore_guard.log
				else
					echo "gate1 is running"
			fi
	done
	sleep 1
}

logic()
{
	logic_port="8200"
	logic_count=`cat /etc/environment.yw | grep logic | awk -F":" '{print $2}'`
	flag=`expr $logic_count - 1`
	for i in `seq 0 $flag`
		do
			port=`expr $logic_port + $i`
			process_logic=`ps -ef |grep tcore| grep -v grep|grep logic|grep -w $port|wc -l`
			if [[ $process_logic = "0" ]]
				then
					./tcore --name=logic --lan_ip=$eth0 --lan_port=$port &
					echo "logic  ok"
					echo "$date logic is start">>/var/log/tcore_guard.log
				else
					echo "logic  is running"
			fi
		done
		sleep 1
}

gm()
{
	gm_port="3200"
	gm_count=`cat /etc/environment.yw | grep gm | awk -F":" '{print $2}'`
	flag=`expr $gm_count - 1`
	for i in `seq 0 $flag`
	do
		port=`expr $gm_port + $i`
		process_gm=`ps -ef |grep tcore| grep -v grep|grep gm |grep -w $port|grep -w 2$port|wc -l`
			if [[ $process_gm = "0" ]]
				then
					./tcore --name=gm --lan_ip=$eth0 --lan_port=$port --consoleip=$local --consoleport=2$port &
					echo "gm ok"
					echo "$date gm is start">>/var/log/tcore_guard.log
				else
					echo "gm  is running"
			fi
	done
		sleep 1
}

robot1()
{
    robot_port="9210"
    robot_count=`cat /etc/environment.yw | grep robot1 | awk -F":" '{print $2}'`
    flag=`expr $robot_count - 1`
    sleep 1
    for i in `seq 0 $flag`
    do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
            if [[ $process_robot = "0" ]]
                then
                    ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=1 --match_time=5000 --is_robot=true&
                    echo "robot ok"
                    echo "$date robot1 $port is start">>/var/log/tcore_guard.log
                else
                    echo "robot $port is running"
            fi
    done
        sleep 1
}

robot2()
 {
     robot_port="9220"
     robot_count=`cat /etc/environment.yw | grep robot2 | awk -F":" '{print $2}'`
     flag=`expr $robot_count - 1`
     sleep 1
     for i in `seq 0 $flag`
     do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
             if [[ $process_robot = "0" ]]
                 then
                     ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=2 --match_time=5000 --is_robot=true&
                     echo "robot ok"
                     echo "$date robot2 $port is start">>/var/log/tcore_guard.log
                 else
                     echo "robot $port is running"
             fi
     done
         sleep 1
 }

robot3()
 {
     robot_port="9230"
     robot_count=`cat /etc/environment.yw | grep robot2 | awk -F":" '{print $2}'`
     flag=`expr $robot_count - 1`
     sleep 1
     for i in `seq 0 $flag`
     do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
             if [[ $process_robot = "0" ]]
                 then
                     ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=3 --match_time=5000 --is_robot=true&
                     echo "robot ok"
                     echo "$date robot3 $port is start">>/var/log/tcore_guard.log
                 else
                     echo "robot $port is running"
             fi
     done
         sleep 1
 }

 robot4()
 {
     robot_port="9240"
     robot_count=`cat /etc/environment.yw | grep robot2 | awk -F":" '{print $2}'`
     flag=`expr $robot_count - 1`
     sleep 1
     for i in `seq 0 $flag`
     do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
             if [[ $process_robot = "0" ]]
                 then
                     ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=4 --match_time=5000 --is_robot=true&
                     echo "robot ok"
                     echo "$date robot4 $port is start">>/var/log/tcore_guard.log
                 else
                     echo "robot $port is running"
             fi
     done
         sleep 1
 }

robot5()
 {
     robot_port="9250"
     robot_count=`cat /etc/environment.yw | grep robot2 | awk -F":" '{print $2}'`
     flag=`expr $robot_count - 1`
     sleep 1
     for i in `seq 0 $flag`
     do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
             if [[ $process_robot = "0" ]]
                 then
                     ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=5 --match_time=5000 --is_robot=true&
                     echo "robot ok"
                     echo "$date robot5 $port is start">>/var/log/tcore_guard.log
                 else
                     echo "robot $port is running"
             fi
     done
         sleep 1
}

robot6()
 {
     robot_port="9260"
     robot_count=`cat /etc/environment.yw | grep robot2 | awk -F":" '{print $2}'`
     flag=`expr $robot_count - 1`
     sleep 1
     for i in `seq 0 $flag`
     do
		port=`expr $robot_port + $i`
        process_robot=`ps -ef |grep tcore| grep -v grep|grep robot|grep -w $port|grep -w 16200|wc -l`
             if [[ $process_robot = "0" ]]
                 then
                     ./tcore --name=robot --lan_ip=$eth0 --lan_port=$port --remoteip=$eth0 --remoteport=16200 --max=50 --connect_time=1000 --match_scene=6 --match_time=5000 --is_robot=true&
                     echo "robot ok"
                     echo "$date robot6 $port is start">>/var/log/tcore_guard.log
                 else
                     echo "robot $port is running"
             fi
     done
         sleep 1
}



stop(){
while
	sed -i '/start.sh/s/^/#&/g' /var/spool/cron/root >>/dev/null 2>&1
	pkill tcore
    sleep 3
do
    num=`ps -ef |grep tcore|grep -v grep|wc -l`
    if [ $num = 0 ]
        then
            echo "stop server ok"
            break
    fi
done           
}
start(){
	sed -i '/start.sh/s/^#*//g' /var/spool/cron/root >/dev/null 2>&1
	service=`cat /etc/environment.yw | tail -n +2 | awk -F":" '{print $1}'`
	for n in $service;do
		$n
	done
    echo "start server finish"
}

restart(){
	stop
	sleep 1
	start
}

case "$1" in
	start)start;;
	stop)stop;;
	restart)restart;;
	"")start;;
	*)echo "input error please input again";;
esac
