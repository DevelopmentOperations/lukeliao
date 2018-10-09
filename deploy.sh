#!/bin/bash
time=`date "+%Y%m%d%H%M"`
log_time=`date "+%Y-%m-%d-%H:%M:%S"`
database=`cat /etc/environment.yw |awk -F'#' '/#/{print $2}'` 
pwd_redis=`cat /opt/tcloud/app/$database/info/config.php |grep -m 1 "'REDIS_AUTH'"|awk -F'=>' '{print $2}'|awk -F'"' '{print $2}'`


mysql -uroot -e"show databases;" >>/dev/null 2>&1
	if [ $? != 0 ];then
		pwd=`cat /opt/tcloud/app/$database/info/config.php |grep -m 1 "'MYSQL_PASSWORD'"|awk -F'=>' '{print $2}'|awk -F'"' '{print $2}'`
		really_pwd="-p$pwd"
	else
		really_pwd=""
	fi
#判断是否需要输入数据库密码
use_db=`mysql -uroot $really_pwd -e "show databases" | grep $database`

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
	[ -d /opt/backup/mysql/ ] || mkdir -p /opt/backup/mysql/
	for i in $use_db;do
		mysqldump -uroot $really_pwd $i > /opt/backup/mysql/$i$time.sql
		if [ $? != 0 ];then
			echo -e "\e[31m\e[1$i backup is not\e[0m"
		fi
	done
	
#mysql备份

	redis-cli -h 127.0.0.1 -a $pwd_redis save
	[ -d /opt/backup/redis/ ] || mkdir -p /opt/backup/redis/
	cp /opt/data/redis/dump.rdb /opt/backup/redis/$database$time.rdb
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mredisbackup is not\e[0m"	
	fi
#redis备份
	
	[ -d /opt/backup/server/ ] || mkdir -p /opt/backup/server/ && cp -ar /opt/$database /opt/backup/server/$time/  || echo -e "\e[31m\e[1mserverbackup is not\e[0m"
#service备份
	
	[ -d /opt/backup/tcloud/ ] || mkdir -p /opt/backup/tcloud/  && cp -ar /opt/tcloud /opt/backup/tcloud/$time/  ||  echo -e "\e[31m\e[1mtcloudbackup is not\e[0m"
#tcloud备份
	sleep 1
}

flush()
{	
	read -p "Are you suer you want to clean up the DB?(Yes/No)" tab
	if [ $tab != Yes ];then
		echo "quit"
		exit
	fi
	if [ -e "/etc/exclude_table" ];then
		if [ -s "/etc/exclude_table" ];then
			exclude_tablename=`cat /etc/exclude_table`
		else 
			exclude_tablename=""
		fi
	else
		exclude_tablename=""
	fi
	for i in $use_db;do
		table=`mysql -uroot $really_pwd -e "use $i;show tables;"|tail -n +2 |grep -Ev $exclude_tablename` #该数据库全部表名
		for j in $table;do
			`mysql -uroot $really_pwd -e "use $i;truncate table $j"`
			table_count=`mysql -uroot $really_pwd -e "use $i;select count(*) from $j"|tail -n +2` #表里的数据条数
			if [ $table_count = 0 ];then
				echo -e "\e[32m\e[1mtable $j flush is ok\e[0m"
			else
				echo -e "\e[31m\e[1mtable $j flush is not\e[0m"
			fi
		done
	done
#清空mysql数据

	redis-cli -a $pwd_redis flushdb
	redis_size=`redis-cli -a $pwd_redis dbsize`
	if [ $redis_size == 0 ];then
		redis-cli -a $pwd_redis save
	else 
		echo -e "\e[31m\e[1mredis flush is not\e[0m"
	fi
#请空redis数据
	ntpdate time.pool.aliyun.com
	sleep 1
}

update()
{	
	#read -p "Please input md5:" upload_md
	#pull_md=`md5sum /opt/version/$package | awk '{print $1}'`
	#if [ $upload_md != $pull_md ];then
	#	echo -e "\e[31m\e[1mThe downloaded package is wrong!\e[0m"
	#	exit
	#fi
	package=`ls -lt /opt/version/ | grep -v extract | sed -n '2p' | awk '{print $NF}'` #更新包名
	
	extract_dir=/opt/version/extract #更新包解压目录
	[ -d $extract_dir ] || mkdir -p $extract_dir && rm -rf /opt/version/extract/*
	
	tar xvf /opt/version/$package -C $extract_dir >/dev/null 2>&1
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mtar is not\e[0m"
		exit
	fi
	
	server_pkg=$extract_dir/`ls $extract_dir|grep -v tcloud` #service包名
	tc_pkg=$extract_dir/`ls $extract_dir|grep tcloud` #tcloud包名
	rm -rf /opt/$database/log
	previous_version=`cat /var/log/tcore_guard.log |grep update|tail -1|awk '{print $2}'`
	echo "============= previous_version is $previous_version ============"
	echo "==================$log_time `basename $server_pkg` update=================="
	
	[ -d /opt/$database ] || mkdir -p /opt/$databases
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

	
	echo "==================$log_time `basename $server_pkg` update==================">>/var/log/tcore_guard.log
	sleep 1
}

load_db()
{
	read -p "Please input SQL path:" sql_path
	if [ -f $sql_path ];then
		mysql -uroot $really_pwd $database < $sql_path 
		if [ $? != 0 ];then
			echo -e "\e[31m\e[1mFailed to upload database\e[0m"
		fi
	else	
		echo -e "\e[31m\e[1mNo such file or directory\e[0m"
	fi
	sleep 1
}

while
	echo -e "\e[33m\e[4m0.break\e[0m"
	echo -e "\e[33m\e[4m1.stop service\e[0m"
	echo -e "\e[33m\e[4m2.backup\e[0m"
	echo -e "\e[33m\e[4m3.flush mysql redis\e[0m"
	echo -e "\e[33m\e[4m4.update service tcloud\e[0m"
	echo -e "\e[33m\e[4m5.update database\e[0m"
	echo -e "\e[33m\e[4m6.all\e[0m"
	echo -e "Please input start num:\c"
	read num
do
	for i in $num;do
		case $i in
			1)stop;;
			2)backup;;
			3)flush;;
			4)update;;
			5)load_db;;
			6)stop
			backup
			flush
			update
			exit;;
			0)exit;;
			*)echo "input error please input again";;
		esac
	done
done