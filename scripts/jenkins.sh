#! /bin/sh

if [ $# -lt 2 ];then
        echo "Usage:build_with_params.sh <jobName> <param_1_name=param_1_value> <param_2_name=param_2_value&> <...>"
        exit 1
fi

params=$2
for((i=$#;i>2;i--))
    do
        params="$params""&""${!i}"
    done
echo "jenkins job<$1> build with params:<$params>"
curl -X POST "http://jenkins.exa.center:8080/jenkins/job/$1/buildWithParameters?$params" --user username:password
