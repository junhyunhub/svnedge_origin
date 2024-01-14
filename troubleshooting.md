## 사전 테스트

기존 svnedge 에서 추출한 스크립트로 CentOS 에서 svnedge 파일만 업로드하여 동작시 Error 없음.

### 문제 증상 1

테스트 완료된 Centos 스크립트 → ubuntu 로만 변경시 아래와 같이 error 발생함

스크립트 수정 필요.

```bash
csvn-dev-ubuntu  | [cont-init.d] 30-start-httpd.sh: executing... 
csvn-dev-ubuntu  | httpd: Syntax error on line 2 of /home/svnedge/csvn/data/conf/httpd.conf: Could not open configuration file /home/svnedge/csvn/data/conf/csvn_modules_httpd.conf: No such file or directory
csvn-dev-ubuntu  | Starting Subversion Edge Apache Server: -en 
csvn-dev-ubuntu  | -en 
csvn-dev-ubuntu  | FAILED-en 
csvn-dev-ubuntu  | 
csvn-dev-ubuntu  | [cont-init.d] 30-start-httpd.sh: exited 1.
csvn-dev-ubuntu  | [cont-init.d] done.
```

[30-start-httpd.sh](http://30-start-httpd.sh) 가 실행되기 전에 아래 파일들이 생성되는것 확인. (오른쪽이 정상)

추가 파일들은 [10-start-console.sh](http://10-start-console.sh/) 가 실행될때 생성되는것 확인

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e615eb50-e278-4c47-8bb1-332dd8fc2fc8/15c98e44-d2b8-4743-bd5e-ee864c3d6272/Untitled.png)

10-start-console 이 어떻게 동작하는지 확인하기위해 스크립트 동작 로그 추출

```bash
# svnedge 사용자로 스크립트 실행, sh -x 옵션으로 스크립트 동작 로그 추출
su - svnedge -c "sh -x /home/svnedge/csvn/bin/csvn start > /home/svnedge/csvn/ubuntu-start-csvn.log"
su - svnedge -c "sh -x /home/svnedge/csvn/bin/csvn start > /home/svnedge/csvn/centos-start-csvn.log"
```

로그 비교시 차이가 보이지 않음.

```bash
# csvn 의 1262 번째 Line 에 있는 start() 옵션이 실제 스크립트 실행 위치임.

start() {
    eval echo `gettext 'Starting $APP_LONG_NAME...'`
    getpid
    if [ "X$pid" = "X" ]
    then 
        prepAdditionalParams "$@" 
        # The string passed to eval must handles spaces in paths correctly.
        COMMAND_LINE="$CMDNICE \"$WRAPPER_CMD\" \"$WRAPPER_CONF\" wrapper.syslog.ident=\"$APP_NAME\" wrapper.pidfile=\"$PIDFILE\" wrapper.name=\"$APP_NAME\" wrapper.displayname=\"$APP_LONG_NAME\" wrapper.daemonize=TRUE $ANCHORPROP $IGNOREPROP $STATUSPROP $COMMANDPROP $LOCKPROP wrapper.script.version=3.5.26 $ADDITIONAL_PARA"
        eval $COMMAND_LINE
    else 
        eval echo `gettext '$APP_LONG_NAME is already running.'`
        exit 1
    fi   
    
    startwait
}
```

# sh -x 옵션으로 확인했을때 실제 변수값은 아래와 같다.

```bash
COMMAND_LINE= "/home/svnedge/csvn/bin/./wrapper-linux-x86-64" "/home/svnedge/csvn/bin/../data/conf/csvn-wrapper.conf" wrapper.syslog.ident="csvn" wrapper.pidfile="/home/svnedge/csvn/bin/../data/run/csvn.pid" wrapper.name="csvn" wrapper.displayname="CSVN Console" wrapper.daemonize=TRUE   wrapper.statusfile="/home/svnedge/csvn/bin/../data/run/csvn.status" wrapper.java.statusfile="/home/svnedge/csvn/bin/../data/run/csvn.java.status"   "wrapper.script.version=3.5.26"
```

Reference: https://wrapper.tanukisoftware.com/doc/english/debugging.html

wrapper-linux-x86-64 에 대해 좀 찾아보니 Java Service Wrapper 라는 놈이 있음 로그를 보기위해 wrapper.debug=TRUE 옵션을 start() 변수에 넣어줌. wrapper-linux-x86-64 는 실행시 data/conf/csvn-wrapper.conf 참조하고 로그파일 경로는 wrapper.logfile=../../data/logs/console_YYYYMMDD.log 로 되어있다.

logs 점검 결과 파이썬 설치가 필요하여 DockerFile 에 추가함.

```bash
...
java.io.IOException: Cannot run program "python" (in directory "/home/svnedge/csvn"): error=2, No such file or directory
...
```

s6 V3 버전에서 변경된 구조로 스크립트 실행시 스크립트가 대기하지 못하고 바로 죽는 현상이 있다. github 에서 찾아보니 wait 대기값이 0.5초이므로 환경변수에서 wait 시간이 무제한이 되도록 변경함.

```bash
bms_svnedge  | s6-rc: info: service 10-start-console: starting
bms_svnedge  | Starting CSVN Console...
bms_svnedge  | ...
bms_svnedge  | CSVN Console started
bms_svnedge  | Initializing CSVN Console at http://localhost:3343/csvn. Please wait a moment for server to become available.
bms_svnedge  | s6-rc: info: service 10-start-console successfully started
bms_svnedge  | s6-rc: info: service 20-wait: starting
bms_svnedge  | Waiting for SVN Edge console
bms_svnedge  | s6-rc: fatal: timed out
bms_svnedge  | s6-sudoc: fatal: unable to get exit status from server: Operation timed out
```

`S6_CMD_WAIT_FOR_SERVICES_MAXTIME` (default = 5000): The maximum time (in milliseconds) the services could take to bring up before proceding to CMD executing. Note that this value also includes the time setting up legacy container initialization (`/etc/cont-init.d`) and services (`/etc/services.d`), and that it is taken into account even if you are not running a CMD. In other words: no matter whether you're running a CMD or not, if you have scripts in `/etc/cont-init.d` that take a long time to run, you should set this variable to either 0, or a value high enough so that your scripts have time to finish without s6-overlay interrupting them and diagnosing an error.