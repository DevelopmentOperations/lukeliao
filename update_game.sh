#!/bin/bash
time=`date "+%Y%m%d%H%M"`
database=`cat /etc/environment.yw |awk -F'#' '/#/{print $2}'` 

stop()
{
	count=`ps -ef | grep tcore | grep -v grep | wc -l`
	if [ $count != 0 ];then
		pkill tcore
	fi
	# sed -i '/start.sh/s/^#*//g' 
	sed -i '/start.sh/s/^/#&/g' /var/spool/cron/root #关闭service守护进程，注释掉任务计划
	sleep 1
}

backup()
{		
	[ -d /opt/backup/server/ ] || mkdir -p /opt/backup/server/ && cp -ar /opt/$database /opt/backup/server/$time/  || echo -e "\e[31m\e[1mserverbackup is not\e[0m"
#service备份
	
	[ -d /opt/backup/tcloud/ ] || mkdir -p /opt/backup/tcloud/  && cp -ar /opt/tcloud /opt/backup/tcloud/$time/  ||  echo -e "\e[31m\e[1mtcloudbackup is not\e[0m"
#tcloud备份
	sleep 1
}

update()
{	
	package=`ls -lt /opt/version/ | grep -v extract | sed -n '2p' | awk '{print $NF}'` #更新包名
	echo -e "\e[34m\e[1m$package will be update\e[0m"
	extract_dir=/opt/version/extract #更新包解压目录
	[ -d $extract_dir ] || mkdir -p $extract_dir && rm -rf /opt/version/extract/*
	
	tar xvf /opt/version/$package -C $extract_dir >/dev/null 2>&1
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mtar is not\e[0m"
		exit
	fi
	
	server_pkg=$extract_dir/`ls $extract_dir|grep -v tcloud` #service包名
	tc_pkg=$extract_dir/`ls $extract_dir|grep tcloud` #tcloud包名
	#rm -rf /opt/$database/log
	
	[ -d /opt/$database ] || mkdir -p /opt/$database
	tar -xvf $server_pkg -C /opt/$database/ >/dev/null 2>&1
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mservice tar is not\e[0m"
	fi
	
	[ -d /opt/tcloud ] || mkdir -p /opt/tcloud
	tar -xvf $tc_pkg -C /opt/tcloud/ >/dev/null 2>&1
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mtcloud tar is not\e[0m"
	fi
	
	config_dir=`ls -lt /opt/backup/tcloud/ | sed -n '2p' | awk '{print $NF}'` #配置文件名
	cp /opt/backup/tcloud/$config_dir/app/$database/info/config.php /opt/tcloud/app/$database/info/
	chmod +x /opt/$database/*.sh
	chown -R nginx.nginx /opt/tcloud/
	sleep 1
}


stop
backup
update
