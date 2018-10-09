#!/bin/bash

#svn update
cd /opt/version/server/
/usr/bin/svn up


#set
time=`date "+%Y%m%d%H%M"`
database="monster"
#read -p "Please input database name:" database
#mysql -uroot -e"show databases;" >>/dev/null 2>&1
#	if [ $? != 0 ];then
#		read -sp "Please input database password:" pwd
#		really_pwd="-p$pwd"
#	else
#		really_pwd=""
#	fi
#判断是否需要输入数据库密码

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
	mysqldump -uroot $database >/opt/backup/mysql/$database$time.sql
	if [ $? != 0 ];then
		echo -e "\e[31m\e[1mmysqldump is not\e[0m"
	fi
#mysql备份

	redis-cli bgsave
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

	table=`mysql -uroot  -e "use $database;show tables;"|tail -n +2` #该数据库全部表名
	for i in $table;do
		`mysql -uroot -e "use $database;truncate table $i"`
		table_count=`mysql -uroot  -e "use $database;select count(*) from $i"|tail -n +2` #表里的数据条数
		if [ $table_count != 0 ];then
			echo -e "\e[31m\e[1mtable $i flush is not\e[0m"
		fi
	done
#清空mysql数据

	redis-cli flushdb
	redis_size=`redis-cli dbsize`
	if [ $redis_size == 0 ];then
		redis-cli save
	else
		echo -e "\e[31m\e[1mredis flush is not\e[0m"
	fi
#请空redis数据
	sleep 1
}

update()
{
	package=`ls -lt /opt/version/server | sed -n '2p' | awk '{print $NF}'` #更新包名
	echo -e "\e[34m\e[1m$package will be update\e[0m"
	echo $package > /tmp/updatelist
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

load_db()
{
	read -p "Please input SQL path:" sql_path
	if [ -f $sql_path ];then
		mysql -uroot $database < $sql_path
		if [ $? != 0 ];then
			echo -e "\e[31m\e[1mFailed to upload database\e[0m"
		fi
	else
		echo -e "\e[31m\e[1mNo such file or directory\e[0m"
	fi
	sleep 1
}



old_server=`cat /tmp/updatelist`
new_server=`ls -lt /opt/version/server | sed -n '2p' | awk '{print $NF}'`
if [ $old_server = $new_server ];
	then
		stop
		backup
		update
		cd /opt/$database
		sh start.sh
	else
		exit
fi



#while
#	echo -e "\e[33m\e[4m0.break\e[0m"
#	echo -e "\e[33m\e[4m1.stop service\e[0m"
#	echo -e "\e[33m\e[4m2.backup\e[0m"
#	echo -e "\e[33m\e[4m3.flush mysql redis\e[0m"
#	echo -e "\e[33m\e[4m4.update service tcloud\e[0m"
#	echo -e "\e[33m\e[4m5.update database\e[0m"
#	echo -e "\e[33m\e[4m6.all\e[0m"
#	echo -e "Please input start num:\c"
#	read num
#do
#	for i in $num;do
	#	case $i in
		#	1)stop;;
			#2)backup;;
			#3)flush;;
			#4)update;;
			#5)load_db;;
			#6)stop
			#backup
			#flush
			#update
			#exit;;
			#0)exit;;
			#*)echo "input error please input again";;
		#esac
	#done
#done
