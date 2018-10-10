#!/bin/bash
nginx_1="10.1.0.242"
nginx_2="10.1.0.229"
fun=$1
ip=$2
port=$3

pick_node(){
	echo "===============================node $ip start==============================="
	ssh ubuntu@$nginx_1 "sudo sed -i '/'$ip'/s/^/#&/g' /etc/nginx/nginx.conf"
	ssh ubuntu@$nginx_1 "sudo /etc/init.d/nginx reload"
	echo "nginx-1上 $ip 节点已摘除"
	ssh ubuntu@$nginx_2 "sudo sed -i '/'$ip'/s/^/#&/g' /etc/nginx/nginx.conf"
	ssh ubuntu@$nginx_2 "sudo /etc/init.d/nginx reload"
	echo "nginx-2上 $ip 节点已摘除"
}

recovery_node(){
	ssh ubuntu@$nginx_1 "sudo sed -i '/'$ip'/s/^#*//g' /etc/nginx/nginx.conf"
	ssh ubuntu@$nginx_1 "sudo /etc/init.d/nginx reload"
	echo "nginx-1上 $ip 节点已恢复"
	ssh ubuntu@$nginx_2 "sudo sed -i '/'$ip'/s/^#*//g' /etc/nginx/nginx.conf"
	ssh ubuntu@$nginx_2 "sudo /etc/init.d/nginx reload"
	echo "nginx-2上 $ip 节点已恢复"
	echo "===============================node $ip end==============================="
}

check_status(){
	echo "进程启动,等待30秒"
    sleep 30
    echo "判断进程启动是否成功"
	while true;do
		curl http://$ip:8084/api/v1/member/current
		if [ $? == 0 ];then
			echo "进程启动完毕，注册节点"
			recovery_node
			break
		else
			echo "进程还在启动,等待30秒"
			sleep 10
		fi
	done
}

check_port(){
	echo "进程启动,等待30秒"
	sleep 40
	echo "判断进程启动是否成功"
	while true;do
		nc -vz $ip $port
		if [ $? == 0 ];then
			echo "端口已启用，启动完毕"
			break
		else
			echo "端口还未启用，等待30秒"
			sleep 30
		fi
	done
}

$fun
