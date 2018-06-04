#!/bin/sh
                                                                                                                                                                                                                                                                     
#################################################
# AnripDdns v3.08.09
# 基于DNSPod用户API实现的动态域名客户端
# 作者: 若海[mail@anrip.com]     
# 介绍: http://www.anrip.com/ddnspod
# 时间: 2013-08-08 23:25:00
#################################################
                                                                                                                                                                                                                                                                     
# 全局变量表
arPass=arMail=""
                                                                                                                                                                                                                                                                     
# 获得外网IP地址
arIpAdress() {
    local inter="http://members.3322.org/dyndns/getip"
    wget --quiet --no-check-certificate --output-document=- $inter
}
                                                                                                                                                                                                                                                                     
# 查询域名IP地址
# 参数: 待查询域名
arNslookup() {
    local dnsvr="119.29.29.29"
    nslookup ${1} $dnsvr | tail -2 | head -1 | awk '{print $2}'
}
                                                                                                                                                                                                                                                                     
# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
    local agent="AnripDdns/3.08(mail@anrip.com)"
    local inter="https://dnsapi.cn/${1:?'Info.Version'}"
    local param="login_email=${arMail}&login_password=${arPass}&format=json&${2}"
    wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
}
                                                                                                                                                                                                                                                                     
# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
    local domainID recordID recordRS recordCD
    # 获得域名ID
    domainID=$(arApiPost "Domain.Info" "domain=${1}")
    domainID=$(echo $domainID | sed 's/.\+{"id":"\([0-9]\+\)".\+/\1/')
    # 获得记录ID
    recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
    recordID=$(echo $recordID | sed 's/.\+\[{"id":"\([0-9]\+\)".\+/\1/')
    # 更新记录IP
    recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_line=默认")
    recordCD=$(echo $recordRS | sed 's/.\+{"code":"\([0-9]\+\)".\+/\1/')
    # 输出记录IP
    if [ "$recordCD" == "1" ]; then
        echo $recordRS | sed 's/.\+,"value":"\([0-9\.]\+\)".\+/\1/'
        return 1
    fi
    # 输出错误信息
    echo $recordRS | sed 's/.\+,"message":"\([^"]\+\)".\+/\1/'
}
# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
    local postRS
    local hostIP=$(arIpAdress)
    local lastIP=$(arNslookup "${2}.${1}")
    echo "hostIP: ${hostIP}"
    echo "lastIP: ${lastIP}"
    if [ "$lastIP" != "$hostIP" ]; then
        postRS=$(arDdnsUpdate $1 $2)
        echo "postRS: ${postRS}"
        if [ $? -ne 1 ]; then
            return 0
        fi
    fi
    return 1
}
                                                                                                                                                                                                                                                                     
###################################################
                                                                                                                                                                                                                                                                     
# 设置用户参数
arMail="xxx@xxx.com"
arPass="xxxxxx"
                                                                                                                                                                                                                                                                     
# 检查更新域名
arDdnsCheck "xxxx.com" "www"

###########        说明       ###########
# 我们只需要将上面的
# 设置用户参数
# arMail="自己的DNSPOD用户名" 
# arPass="自己的DNSPOD密码" 
# 检查更新域名
# arDdnsCheck"顶级域名" "二级域名前缀" //需要更新的域名为anrip.com，主机为lab，就是lab.anrip.com arDdnsCheck"anrip.net" "lab" 
# 修改成自己的信息即可

############        安装支持     ###########
#### yum -y install bind-utils

############      增加执行权限        ###########
#### chmod +x /root/dns.sh

##############      加入任务计划(5分钟执行一次)    #########################
#### echo "*/5  * * * * root /root/dns.sh" &gt;&gt; /etc/crontab