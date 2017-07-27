#!/bin/bash
data_processing(){
arp_times1=`timeout 1 tcpdump -i eth0 arp -nne 2>/dev/null 1>tmp; wc -l tmp | awk '{print $1}'; rm tmp`
arp_times2=`timeout 1 tcpdump -i eth0 arp -nne 2>/dev/null 1>tmp; wc -l tmp | awk '{print $1}'; rm tmp`
#当第二次检测突增1000个arp包时，判断此时环路
arp_times3=$[ arp_times2 - arp_times1 ]
echo "${arp_times1}"
echo "${arp_times2}"
echo "${arp_times3}"
#if [ ${arp_times3} -lt 0 ];then
#   arp_times3=`expr 0 - ${arp_times3}`
#  fi
if [ ${arp_times3} -gt 1000 ];then
   ifconfig eth0 down
   send_mail
  fi
}

#设置发送人和收件人
local_ip=`ifconfig eth1|grep Mask|awk '{print$2}'|awk -F ":" '{print$2}'` # 获取本地IP地址
sender=77160@sangfor.com # 发信人的email
reciver=77160@sangfor.com # 收信人的email
subject="Network failure ${local_ip}" # 邮件的标题
smtp='200.200.0.11' # 修改这里，邮件服务器地址

#发送邮件
send_mail(){
(
  sleep 5
  for comm in "helo sangfor.com" "mail from:$sender"
  do
     echo "$comm"
     sleep 3
  done
  #设置发送人员列表
  echo $reciver | sed 's/,/\n/g'| while read user
  do
        sleep 3
        echo "rcpt to:$user"
  done
  sleep 2
  #设置发送数据

  for data in "data" "From: <$sender>" "To:`echo $reciver|sed 's/,/;/g'`" "Subject: $subject" "Date: `date` +0800" "Mime-Version: 1.0" "content-Type: text/plain"
  do
     echo "$data"
     sleep 3
  done
   #test -r $OUTFILE && cat $OUTFILE
   echo -e "${subject}"
   echo "."
   sleep 5)|telnet $smtp  25
}

while true
do
result=`ethtool eth0 | grep yes`
if [ $? -ne 0 ];then
   sleep 300
else
   data_processing
   sleep 5
fi
done
