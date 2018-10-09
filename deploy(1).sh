#!/bin/sh
source /etc/profile
# Public Parameters start
erp_version=$(cat /etc/erp_version 2>/dev/null || echo www)
baseDirforScript=$(cd "$(dirname $0)";pwd)
cd $baseDirforScript
ftpserver=10.241.60.101
ftpuser=operation
ftppasswd=lO7x6yuxPP3e5uAjwz_U
updateApp='http://10.241.60.101:8001/updateApp'
if [[ $erp_version == "edgj" ]];then
    pkgServer="http://10.153.201.151:8088"
elif [[ $erp_version == "STG" ]];then
    pkgServer="http://10.132.168.37:8088"
else
    pkgServer="http://10.241.60.101:8088"
fi
logDir=/data/gyapp/logs/
[[ -d $logDir ]] || mkdir -p $logDir
# Public Parameters end

#--default config end
JAVA_OPTS='-Xms512M -Xmx1024M -XX:MaxPermSize=128M'
JAVA_HOME=/usr/local/java/latest

CLASSPATH=".:$baseDirforScript/approot/classes"
for jar in $baseDirforScript/approot/lib/*.jar;
do
    CLASSPATH+=":$jar"
done
export CLASSPATH
#--default config end

# get pgname start
if [[ -r $baseDirforScript/appconfig ]];then
    source $baseDirforScript/appconfig
    if [[ -z $packagename ]]; then
        packagename="$(basename $baseDirforScript)-1.0.0-bin.tar.gz"
        pgname=$(basename $baseDirforScript)
        echo -e "\033[34mPackageName from CurrDir is : $packagename\033[0m"
    else
        pgname=$(echo $packagename | sed  -e 's#-1.0.0-perf-bin.tar.gz##g' -e 's#-1.0.0-rc-bin.tar.gz##g' -e 's#-1.0.0-bin.tar.gz##g' -e 's#-bin.tar.gz##g')
        echo -e "\033[34mPackageName from appconfig is : $packagename\033[0m"
    fi
else
    packagename="$(basename $baseDirforScript)-1.0.0-bin.tar.gz"
    pgname=$(basename $baseDirforScript)
    echo -e "\033[34mPackageName from CurrDir is : $packagename\033[0m"
fi
MAIN_CLASS="*Main.class"
mainFunPath=$(find $baseDirforScript -name $MAIN_CLASS)
appName=$(echo ${mainFunPath##*classes/}|sed 's#/#.#g'|sed 's#.class##g')
# get pgname end

releaseDir="/home/deployment/packages/$pgname/$(date +%Y%m%d)"
[[ -d $releaseDir ]] || mkdir -p $releaseDir

show_usage() {
    echo -e "`printf %-8s "Usage: $0"` [-h|--help] 显示此帮助信息并退出"
    echo -e "`printf %-8s ` [stop]         关闭应用"
    echo -e "`printf %-8s ` [start]        启动应用"
    echo -e "`printf %-8s ` [restart]      重启应用"
    echo -e "`printf %-8s ` [pull]         更新应用"
    echo -e "`printf %-8s ` [status]       查看应用状态"
    echo -e "`printf %-8s ` [jvmhis]       导出应用堆栈"
    echo -e "`printf %-8s ` [rollback]     用且只能用最近一次备份的内容回滚"
    echo -e "`printf %-8s "Example : $0"` status"
}

getapp() {
    httpStatus=$(curl -R -w "%{http_code}\n" -s -m 600 --connect-timeout 20 $pkgServer/$packagename -o $releaseDir/$packagename --stderr /dev/null)
    if [ "$httpStatus" -ne "200" ]; then
        echo -e "\033[31m$packagename download failed\033[0m"
        exit 201
    else
    	echo $(ls -l $releaseDir/$packagename | awk '{for(i=6;i<10;i++)printf $i" "}')
    fi

    packagefile=$releaseDir/$packagename
    bktime=$(date +%y%m%d%H%M%S)
    backupdir="/home/deployment/release-backup/$pgname/$bktime"
    [[ -d $backupdir ]] || mkdir -p $backupdir
    /bin/mv -f $baseDirforScript/approot $backupdir
    tar zxf $packagefile -C $baseDirforScript
    if [[ $? != 0 ]];then
    	echo -e "\033[31munpackage failed\033[0m"
    	exit 202
    fi

    #替换修改后的文件
    #echo ----------------cp Config File start----------------
    confdir=$baseDirforScript/config
    rootconfdir=$baseDirforScript/approot/classes
    logPath="/data/gyapp/logs/$pgname.log"
	if [[ -d $baseDirforScript/config ]]; then
        #    for file in $(ls $baseDirforScript/config)
        #    do
        #	for i in $(grep -v ^# $rootconfdir/$file |grep = | awk -F= '{print $1}')
        #	do
        #        grep $i $confdir/$file 2> /dev/null
        #	    if [[ $? == 0 ]] ;then
        #	        echo -n
        #	    else
        #	        add=1
        #	        grep --color $i $rootconfdir/$file 2>/dev/null
        #	    fi
        #	done
        #    if [[ $add == 1 ]] ;then
        #	    echo $confdir/$file
        #	    echo
        #    fi
        #	add=0
        #   done
            /bin/cp -af $baseDirforScript/config/* $rootconfdir/
        fi
    #echo ----------------cp Config File End----------------


    if [[ ! -f $baseDirforScript/approot/classes/logback.xml ]] ;then
    	rm -f $baseDirforScript/approot/lib/logback-classic-1.0.13.jar
    	rm -f $baseDirforScript/approot/lib/logback-core-1.0.13.jar
    elif [[ -f $baseDirforScript/config/logback.xml ]]; then
        sed -i -e "/java.sql.ResultSet/{n;s/debug/warn/g}" -e "/java.sql.PreparedStatement/{n;s/debug/warn/g}" -e "/java.sql.Statement/{n;s/debug/warn/g}" -e "/java.sql.Connection/{n;s/debug/warn/g}" -e "/com.apache.ibatis/{n;s/debug/warn/g}" -e "/com.alibaba.dubbo/{n;s/debug/warn/g}" $baseDirforScript/config/logback.xml
        sed -i -e "/java.sql.ResultSet/{n;s/info/warn/g}" -e "/java.sql.PreparedStatement/{n;s/info/warn/g}" -e "/java.sql.Statement/{n;s/info/warn/g}" -e "/java.sql.Connection/{n;s/info/warn/g}" -e "/com.apache.ibatis/{n;s/info/warn/g}" -e "/com.alibaba.dubbo/{n;s/info/warn/g}" $baseDirforScript/config/logback.xml
        sed -i -e "/user\.home/d" -e '/appender-ref ref="STDOUT"/d' $baseDirforScript/config/logback.xml
    elif [[ -f $baseDirforScript/approot/classes/logback.xml ]]; then
        sed -i -e "/java.sql.ResultSet/{n;s/debug/warn/g}" -e "/java.sql.PreparedStatement/{n;s/debug/warn/g}" -e "/java.sql.Statement/{n;s/debug/warn/g}" -e "/java.sql.Connection/{n;s/debug/warn/g}" -e "/com.apache.ibatis/{n;s/debug/warn/g}" -e "/com.alibaba.dubbo/{n;s/debug/warn/g}" $baseDirforScript/approot/classes/logback.xml
        sed -i -e "/java.sql.ResultSet/{n;s/info/warn/g}" -e "/java.sql.PreparedStatement/{n;s/info/warn/g}" -e "/java.sql.Statement/{n;s/info/warn/g}" -e "/java.sql.Connection/{n;s/info/warn/g}" -e "/com.apache.ibatis/{n;s/info/warn/g}" -e "/com.alibaba.dubbo/{n;s/info/warn/g}" $baseDirforScript/approot/classes/logback.xml
        sed -i -e "/user\.home/d" -e '/appender-ref ref="STDOUT"/d' $baseDirforScript/approot/classes/logback.xml
    elif [[ -f $baseDirforScript/approot/lib/ons-client-1.1.8.jar ]]; then
        /bin/cp -af /opt/script/app/log4j_rocketmq_client.xml $baseDirforScript/approot/classes/
        /bin/cp -af /opt/script/app/logback_rocketmq_client.xml $baseDirforScript/approot/classes/
    elif [[ -f $baseDirforScript/approot/classes/log4j.properties ]]; then
        sed -i -e "s#log4j.appender.A1.File=.*#log4j.appender.A1.File=$logPath#g" -e "s#<param name=\"File\" value=\".*\"/>#<param name=\"File\" value=\"$logPath\"/>#g" $baseDirforScript/approot/classes/log4j.properties
    elif [[ -f $baseDirforScript/config/log4j.xml ]]; then
        sed -i -e "s#log4j.appender.A1.File=.*#log4j.appender.A1.File=$logPath#g" -e "s#<param name=\"File\" value=\".*\"/>#<param name=\"File\" value=\"$logPath\"/>#g"$baseDirforScript/config/log4j.xml
    else
        echo 203
    fi

    #Extra operation
    if [ -r $baseDirforScript/ExOpr.sh ]; then
        bash $baseDirforScript/ExOpr.sh
    fi
    #echo ----------------grep 192.168 start----------------
    echo -e "\e[1;31m"
    grep -l '^[^#].*192.168'  $baseDirforScript/approot/classes/*.properties 2>/dev/null
    echo -e "\e[0;30m"
    #echo ----------------grep 192.168 End----------------
}

stop() {
    if [[ -z $mainFunPath ]];then
       echo not find Main.class
       exit 203
    fi
    echo stop "$appName"
    pid=$(ps -fwwC java|grep "$appName" | awk '{print $2}')
    var=$(echo -n $pid|grep -c '')
    if [ $var -gt 0 ]; then
        ps -fwwp $pid
        kill $pid
        sleep 1
        kill -9 $pid 2>/dev/null
        ps -fwwp $pid
    else
        echo -e "\n\e[1;31m$appName not start\e[0;30m"
    fi
}

start() {
    if [[ -z $mainFunPath ]];then
       echo not find Main.class
       exit 203
    fi
    pid=$(ps -fwwC java|grep "$appName" | awk '{print $2}')
    var=$(echo -n $pid|grep -c '')
    if [ $var -gt 0 ]; then
        ps -fwwp $pid
        echo -e "\n\e[1;31m$appName is already running, Please stop it first\e[0;30m"
        exit 204
    fi

    echo start "$appName"
    "$JAVA_HOME"/bin/java $JAVA_OPTS  "$appName" &> $logDir/$pgname.log.console.$(date +%Y%m%d) &
    pid=$!
    cmdline=$(cat /proc/$pid/cmdline)
    sleep 1
    ps -fwwp $(pgrep -f "$appName")
    if [[ $erp_version != "edgj" ]];then
        curl  $updateApp -d dir=$baseDirforScript"/" -d name=$packagename -d group=$erp_version -d cmdline=$cmdline -d pid=$pid -d isweb=0 --stderr /dev/null
    fi
    bash /opt/script/tools/checkAutoStart.sh
}

jvmhis() {
    BIZ_PID=`ps -fC java | grep $appName | grep -v 'grep "$appName"' | awk '{print $2}'`
    IP=`ifconfig | grep -v '127.0.0.1' | grep -m1 'inet ' | awk '{print $2}' | cut -d: -f2`
    BIZ_NAME="$pgname-$IP-$BIZ_PID-$(date +%F_%H.%M.%S)"
    [ -d /tmp/jvmhis ] || mkdir -p /tmp/jvmhis
    MainDir=/tmp/jvmhis
    $JAVA_HOME/bin/jmap -heap $BIZ_PID > $MainDir/$BIZ_NAME.heap
    $JAVA_HOME/bin/jmap -histo $BIZ_PID > $MainDir/$BIZ_NAME.instances
    $JAVA_HOME/bin/jstack -l $BIZ_PID > $MainDir/$BIZ_NAME.jstack
    [ -x /usr/bin/lftp ]  || yum install lftp -y  > /dev/null  2>&1
    lftp $ftpserver -u $ftpuser:$ftppasswd -e "mkdir -p $erp_version/$pgname; exit"
    lftp -c "put $MainDir/$BIZ_NAME.heap -o ftp://$ftpuser:$ftppasswd@$ftpserver/$erp_version/$pgname/"
    lftp -c "put $MainDir/$BIZ_NAME.instances -o ftp://$ftpuser:$ftppasswd@$ftpserver/$erp_version/$pgname/"
    lftp -c "put $MainDir/$BIZ_NAME.jstack -o ftp://$ftpuser:$ftppasswd@$ftpserver/$erp_version/$pgname/"
    echo -e "\033[32mPlease visit ftp://$ftpserver/$erp_version/$pgname/$BIZ_NAME.heap\033[0m"
    echo -e "\033[32mPlease visit ftp://$ftpserver/$erp_version/$pgname/$BIZ_NAME.instances\033[0m"
    echo -e "\033[32mPlease visit ftp://$ftpserver/$erp_version/$pgname/$BIZ_NAME.jstack\033[0m"
}

restart() {
    stop
    sleep 1
    start
}

rollback() {
    LastBack=$(ls /home/deployment/release-backup/$pgname/ -lrt | tail -1 | awk '{print $NF}')
    if [[ -d /home/deployment/release-backup/$pgname/$LastBack/approot ]]; then
        /bin/rm -fr $baseDirforScript/approot
	stop
        /bin/cp -pr /home/deployment/release-backup/$pgname/$LastBack/approot $baseDirforScript/
        start
    fi
}

status() {
    if [[ -z $mainFunPath ]];then
       echo not find Main.class
       exit 203
    fi
    pid=$(ps -fwwC java|grep "$appName" | awk '{print $2}')
    var=$(echo -n $pid|grep -c '')
    if [ $var -gt 0 ];then
        date -d "$(ps -p $pid -o lstart|grep -v STARTED)"
        ps -fwwp $pid
    else
        echo -e "\n\e[1;31m$appName not start\e[0;30m"
    fi
}

pull() {
    getapp
    $baseDirforScript/restartApp.sh
#    stop
#    sleep 1
#    start
}


case "$1" in
    -h|--help)
        show_usage; exit 0
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    jvmhis)
        jvmhis
        ;;
    rollback)
        rollback
        ;;
    pull)
        pull
        ;;
    "")
        restart
        ;;
    *)
        status
esac
