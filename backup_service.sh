#!/bin/bash
time=`date "+%Y%m%d%H%M"`
app=`cat /etc/environment.yw |awk -F'#' '/#/{print $2}'

backup_app()
{
	[ -d /opt/backup/server/ ] || mkdir -p /opt/backup/server/ && cp -ar /opt/$app /opt/backup/server/$time/  || echo -e "\e[31m\e[1mserverbackup is not\e[0m"	
}

backup_tcloud()
{
	[ -d /opt/backup/tcloud/ ] || mkdir -p /opt/backup/tcloud/  && cp -ar /opt/tcloud /opt/backup/tcloud/$time/  ||  echo -e "\e[31m\e[1mtcloudbackup is not\e[0m"
}

backup_app
backup_tclouds