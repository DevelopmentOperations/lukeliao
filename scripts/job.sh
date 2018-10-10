scp /var/lib/jenkins/workspace/dev-exchange/target/trade_platform-1.0.0-SNAPSHOT.jar ubuntu@172.31.7.224:/opt/app;
$
jarname=
ip=
scp $WORKSPACE/target/$jar ubuntu@$ip:/opt/app;
ssh ubuntu@$ip "/opt/app/deplog-$jarname.sh  >/dev/null 2>&1 &";
