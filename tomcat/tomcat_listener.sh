#!/bin/sh  
#echo $(date) >>/usr/local/work/logs/appserver.log 
#./etc/profile 
#.~/.bash_profile


export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin

SERVER_URL="http://127.0.0.1:10011"
EMAIL_URL="http://120.25.65.11:8888/send_mail"
LOG_FILE=/usr/local/work/logs/appserver.log
TOMCAT_PATH=/usr/local/work/tomcat_a/tomcat/tomcat_app
TOMCAT_NAME="tomcat_app"
WAIT_TOMCAT_STARTUP_TIME=120

EMAIL_TITLE="Restart Tomcat"
IP=$(ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk '{print $2}' | awk -F ':' '{print $2}')
EMAIL_CONTENT="IP:$IP%0ALOG_FILE:$LOG_FILE%0ATOMCAT_PATH:$TOMCAT_PATH"

echo $EMAIL_CONTENT

date +%Z--%A--%x--%T >>$LOG_FILE
echo "Start Detector Tomcat Progress!" >>$LOG_FILE


curlit()  
{  
    curl --connect-timeout 15 --max-time 20 --head --silent "$SERVER_URL" | grep '200'  
    #上面的15是连接超时时间，若访问localhost的HTTP服务超过15s仍然没有正确响应200头代码，则判断为无法访问。  
}  
doit()  
{   
    if ! curlit; then
    echo "Tomcat was dead!" >> $LOG_FILE
    echo "Restart Tomcat!" >> $LOG_FILE
    # 如果localhost的apache服务没有正常返回200头，即出现异常。执行下述命令：  
    sleep 10  
    kill  `ps -ef|grep $TOMCAT_NAME|grep -v grep |awk '{print $2}'` > /dev/null 2>&1  
    # 这条语句中ps -ef|grep $TOMCAT_NAME|grep -v grep为查询进程中java进程同时排除本身语句，用awk找到第二列信息，返回状态扔到黑洞中。  
    sleep 2 
    cd $TOMCAT_PATH/bin
    sh startup.sh 
    #sh $TOMCAT_PATH/startup.sh 
    echo "Tomcat Restart!" >> $LOG_FILE
    curl  -d "sub=$EMAIL_TITLE&content=$EMAIL_CONTENT&to_list=lsl@devondtech.com%3Bhexin@devondtech.com%3Bxiaojing@devondtech.com%3Bhuhuiming@devondtech.com"  "$EMAIL_URL"
    # 写入日志  
    sleep $WAIT_TOMCAT_STARTUP_TIME
    # 重启完成后等待，然后再次尝试一次 
    echo "Detector once more!"
    if  ! curlit; then  
    # 如果仍然无法访问，则:
    echo "Restart Failed!" >> $LOG_FILE
    # 写入apache依然重启失效的日志 
    else
    echo "Restart Success!" >> $LOG_FILE
    fi 
    else 
    echo "Tomcat is running!" >> $LOG_FILE
    fi
}  
sleep 3  
# 运行脚本后才开始正式工作（防止重启服务器后由于tomcat还没开始启动造成误判）  
# 主循环体  
doit 
echo "Detector Over!" >> $LOG_FILE
echo "---------------------------------------------------------------------------" >> $LOG_FILE