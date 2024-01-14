# svnedge_origin

### changes from svnedge/app on dockerhub
- OS: Centos:7 -> ubuntu 22.04.3 LTS
- Supervisor: s6-overlay V2 -> s6-overlay V3
- App: CollabNetSubversionEdge-6.0.2-9_linux-x86_64.tar.gz

### how to use
docker build -t {name} .


---
## Purpose

- Svnedge 의 홈페이지가 사라짐, 더 이상 서비스 하지 않으므로 부서 내에서 사용하고 있는 svnedge 를 관리하기 위해 dockerfile 로 제작 필요.

## Content

- docker Image 는 그대로 유지되고 있고, Docker Official 에 svnedge 에 Dockerfile configuration 파일도 올라가 있다.

## Prerequisites

- OS 이미지가 Centos7 이 올라가 있으며 Maintenance Support set for June 30, 2024. 이므로 Ubuntu Server 22.04 로 교체한다.
- 도커파일로 만들어서 직접 이미지를 관리한다 (부서 git hub)
- 컨피그 파일 및 백업 폴더를 만든다.

svnedge 의 경우 이미 3년전 업데이트가 마지막이고 s6-overlay 의 경우 v1.22.1 버전을 사용했으나 현 시점에서 s6-overlay 는 V3 버전이며 많은 변경이 생겼으므로 s6 v3 기준으로 변경하여 기존 스크립트를 대체한다.

# SVNEdge

## Start Scripts

svnedge 에 설치된 s6 v1 버전의 경우 아래 폴더 내 파일에 대한 스크립트를 실행한다.

```bash
/run/s6/etc
lrwxrwxrwx 1 root root 18 Nov  7 01:39 cont-finish.d -> /etc/cont-finish.d
lrwxrwxrwx 1 root root 16 Nov  7 01:39 cont-init.d -> /etc/cont-init.d
lrwxrwxrwx 1 root root 16 Nov  7 01:39 fix-attrs.d -> /etc/fix-attrs.d
lrwxrwxrwx 1 root root 15 Nov  7 01:39 services.d -> /etc/services.d

```

### /etc/fix-attrs.d

```bash
# scripts
/etc/scripts true svnedge 0755 0755

# data
/home/svnedge/csvn/data false svnedge 0700 0700

```

### /etc/cont-init.d

|-- [01-set-perms.sh](http://01-set-perms.sh/)
|-- [05-init-console.sh](http://05-init-console.sh/)
|-- [10-start-console.sh](http://10-start-console.sh/)
|-- [20-wait.sh](http://20-wait.sh/)
ㄴ-- [30-start-httpd.sh](http://30-start-httpd.sh/)

```bash
# 01-set-perms.sh
#!/usr/bin/execlineb -P
/etc/scripts/set-permissions.sh

---
# 01-set-perms.sh contents
cat set-permissions.sh
#!/usr/bin/with-contenv bash
set -e

# Set permissions on data folder if envvar is set
if [ "$SET_PERMS" == "true" ]
then
    echo "SET_PERMS is true .. setting owner to svnedge on data folder"
    chown -R svnedge:svnedge /home/svnedge/csvn/data
fi

```

```bash
# 05-init-console.sh
#!/usr/bin/execlineb -P
s6-setuidgid svnedge
/etc/scripts/init-console.sh

---
# init-console.sh contents
#!/usr/bin/env bash
set -e

# Check if data folder has been initialized
if [[ ! -f "/home/svnedge/csvn/data/conf/mime.types" ]]; then
    echo "Initializing the data folder"
    cp -Rv /home/svnedge/csvn/data-template/* /home/svnedge/csvn/data
fi

echo "Copying dist files to data/conf"
cp -fv /home/svnedge/csvn/dist/* /home/svnedge/csvn/data/conf

```

```bash
# 10-start-console.sh
#!/usr/bin/execlineb -P
s6-setuidgid svnedge
cd /home/svnedge/csvn
bin/csvn start
```

```bash
# 20-wait.sh
#!/usr/bin/execlineb -P
s6-setuidgid svnedge
/etc/scripts/wait-httpd.sh

---
# wait-httpd.sh contents
#!/usr/bin/env bash
set -e

attempt_counter=0
max_attempts=30

until $(curl --output /dev/null --silent --head --fail <http://127.0.0.1:3343/csvn>); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    echo "Waiting for SVN Edge console"
    attempt_counter=$(($attempt_counter+1))
    sleep 2
done

```

```bash
# 30-start-httpd.sh
#!/usr/bin/execlineb -P
s6-setuidgid svnedge
cd /home/svnedge/csvn
bin/csvn-httpd start
```

### /etc/cont-finish.d

```bash
# 01-stop-console.sh
#!/usr/bin/execlineb -P
cd /home/svnedge/csvn
bin/csvn stop

# 02-stop-httpd.sh
#!/usr/bin/execlineb -P
cd /home/svnedge/csvn
bin/csvn-httpd stop

```

---

# s6 V3 버전 변경점 및 폴더 구조

v3 에서는 /etc/s6-overlay/s6-rc.d 경로를 사용한다 시작 경로는 user 폴더의 contents.d 에서 시작 폴더를 지정하며 실행 순서는 랜덤임,

기존 스크립트가 순서대로 실행을 유지하기위해 30 → 20 → 10 → 05 → 01 순으로 Dependency 를 지정함

 

```bash
s6-scripts/
├── 01-set-perms
│   ├── down
│   ├── set-permissions.sh
│   ├── test.sh
│   ├── type
│   └── up
├── 05-init-console
│   ├── base
│   ├── dependencies.d
│   │   └── 01-set-perms
│   ├── init-console.sh
│   ├── type
│   └── up
├── 10-start-console
│   ├── dependencies.d
│   │   ├── 05-init-console
│   │   └── base
│   ├── type
│   └── up
├── 20-wait
│   ├── dependencies.d
│   │   ├── 10-start-console
│   │   └── base
│   ├── timeout-down
│   ├── type
│   ├── up
│   └── wait-httpd.sh
├── 30-start-httpd
│   ├── dependencies.d
│   │   ├── 20-wait
│   │   └── base
│   ├── down
│   ├── type
│   └── up
├── csvn-bundle
│   ├── contents.d
│   │   └── 30-start-httpd
│   └── type
├── user
│   ├── contents.d
│   │   └── 30-start-httpd
│   └── type
└── user2
    ├── contents.d
    └── type

15 directories, 30 files
```

## Reference

- https://github.com/just-containers/s6-overlay/releases/tag/v3.1.5.0
- https://darkghosthunter.medium.com/how-to-understand-s6-overlay-v3-95c81c04f075