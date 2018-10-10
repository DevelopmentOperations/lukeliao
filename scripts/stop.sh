#!/bin/bash


#set app name
app=disney_cross

ps ux | grep $app | grep -v grep


function echohelp()
{
	echo "1.If you input all will kill all $app process"
	echo "2.If you input id will kill id process"
	echo "3.Enter an ID or character that does not exist"
}
while
echo -e "Please input id:\c"
read id
do
    if [ $id = 'all' ];
		then
			pkill $app
			ps ux | grep $app | grep -v grep
			break
		else
			process=`ps ux | grep $app | grep -v grep|grep -w "node=$id"|wc -l`
				if [[ $process = "0" ]]
					then
						echo "NODE-$i input error ,please input again!"
						echohelp
					else
						pid=`ps ux | grep $app | grep -v grep|grep -w "node=$id"|awk '{print $2}'`
						kill $pid
						ps ux | grep $app | grep -v grep
						break
				fi
    fi            
done
