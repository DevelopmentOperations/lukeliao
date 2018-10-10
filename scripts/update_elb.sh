#!/usr/bin/env bash
if [ -$# -lt 1 ]; then
    echo "Usage: $0 <function> <id> <ip>"
fi
fun=$1
id=$2
ip=$3
deregister_instance(){
    aws elbv2 deregister-targets --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:174032030615:targetgroup/customer/6b27d1fbdd8313c8 \
        --targets Id=$id,Port=8084
    return $?
}

describe-target-health(){
    aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:174032030615:targetgroup/customer/6b27d1fbdd8313c8 \
            --targets Id=$id,Port=8084 > /tmp/target.tmp
            grep 'State' /tmp/target.tmp | awk -F: '{print $2}' |awk -F\" '{print $2}'
            rm -f /tmp/target.tmp
    return $?
}

register_instance(){
    aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:174032030615:targetgroup/customer/6b27d1fbdd8313c8 \
        --targets Id=$id,Port=8084
    return $?
}

deregister(){
    #摘除节点
    deregister_instance

    #等待处理残余流量
    echo '等待60秒,处理剩余流量'
    sleep 60
    result=`describe-target-health`
    until [ $result = 'unused' ]
    do
        sleep 30
        echo '还有处理剩余流量,等待30秒'
        result=`describe-target-health`
    done

    echo '目标节点剩余流量处理完毕'
}

register(){
    #等待进程启动
    echo '进程启动,等待60秒'
    sleep 30

    echo '判断进程启动是否成功'
    url="curl http://$ip:8084/api/v1/member/current"
    result=`$url`
    echo $result

    until [ -n "$result" ]
    do
        echo '进程还在启动,等待30秒'
        sleep 10
        url="curl http://$ip:8084/api/v1/member/current"
        result=`$url`
    done

    #注册节点
    echo '注册节点'
    register_instance

    result=`describe-target-health`
    until [ $result = 'healthy' ]
    do
        sleep 30
        result=`describe-target-health`
    done
    echo '节点状态正常'
}

$fun
