#!/bin/bash

data_collection(){
tcpdump -i eth0 -nne > /datacache/test &
sleep 3
kill -9 `pidof tcpdump`
}

data_processing(){
arp_times=`cat test | grep ARP -wc`
echo "${arp_times}"
#此处自定义设置，当3s内arp报文大于5000则认为网络环路了
if [ ${arp_times} > 5000 ];then
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
   data_collection
   data_processing
   sleep 30
fi
done