# docker 安装 mongodb

[源文章地址](http://www.hikun.top/2020/03/27/docker%E4%B8%8Bmongodb%E5%BC%80%E5%90%AF%E6%9D%83%E9%99%90%E8%AE%A4%E8%AF%81%E5%90%8E%E6%97%A0%E6%B3%95%E5%88%9B%E5%BB%BA%E7%94%A8%E6%88%B7%E9%97%AE%E9%A2%98/)

## 错误操作

### 开启权限认证

docker 启动 mongo 容器时默认是未开启权限认证的，所以为了防止被脱裤，启动的时候需要在最后加上–auth 参数来使 mongo 开启权限认证

```shell
docker run -it -v mongodb:/data/db -p 27017:27017 --name=mongodb -d mongo --auth
```

### 创建用户

由于刚创建的 mongo 容器是没有任何用户的，所以需要手动创建一个 admin 用户

首先使用 mongo admin 进入容器里的 mongo 命令行

```shell
docker exec -it mongodb mongo admin
```

然后在 mongo 命令行创建一个用于创建用户的 admin 用户

```shell
db.createUser({user:"admin", pwd:"admin", roles:[{role:"userAdminAnyDatabase", db:"admin"}]});
```

这里的 role 权限主要有
role|作用
–|–
Read|允许用户读取指定数据库
readWrite|允许用户读写指定数据库
dbAdmin|允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问 system.profile
userAdmin|允许用户向 system.users 集合写入，可以找指定数据库里创建、删除和管理用户
clusterAdmin|只在 admin 数据库中可用，赋予用户所有分片和复制集相关函数的管理权限。
readAnyDatabase|只在 admin 数据库中可用，赋予用户所有数据库的读权限
readWriteAnyDatabase|只在 admin 数据库中可用，赋予用户所有数据库的读写权限
userAdminAnyDatabase|只在 admin 数据库中可用，赋予用户所有数据库的 userAdmin 权限
dbAdminAnyDatabase|只在 admin 数据库中可用，赋予用户所有数据库的 dbAdmin 权限。
root|只在 admin 数据库中可用。超级账号，超级权限

BUT 创建失败

```shell
2019-08-20T08:09:44.426+0000 E QUERY [js] uncaught exception: Error: couldn't add user: command createUser requires authentication :
\_getErrorWithCode@src/mongo/shell/utils.js:25:13
DB.prototype.createUser@src/mongo/shell/db.js:1370:11
@(shell):1:1
```

因为开启了权限认证，所以创建用户需要权限，所以我们需要先不开启权限认证，需要先创建好了 admin 账号后再开启。

## 正确操作

### 暂时不开启权限认证，先创建好用户

把之前的容器删掉

```shell
docker stop mongodb
docker rm mongodb
```

重新生成不带权限认证的 mongo 容器

```shell
docker run -it -v mongodb:/data/db -p 27017:27017 --name=mongodb -d mongo
```

重复创建用户步骤

```shell
docker exec -it mongodb mongo admin

db.createUser({user:"admin", pwd:"admin", roles:[{role:"userAdminAnyDatabase", db:"admin"}]});

Successfully added user: {
    "user" : "admin",
    "roles" : [
        {
            "role" : "userAdminAnyDatabase",
            "db" : "admin"
        }
    ]
}
```

成功创建后进行权限验证

```shell
db.auth("admin","admin")
```

结果为 1 就代表认证成功

但这只是用于创建用户的 admin 用户，在开启权限认证后并不能对集合进行操作，所以我们需要创建一个能读写其他库的用户

同样在 mongo 的命令行里输入

```shell
use test
```

这里切换到 test 数据库下，然后再创建一个对 test 数据库拥有读写权限的用户

```shell
db.createUser({user:"test", pwd:"test", roles:[{role:"readWrite", db:"test"}]});
```

Tips:切换到 test 数据库下创建用户是由于 mongo 的用户是存在不同库里的，在 admin 库下创建的用户只能在 admin 库下进行验证，在 test 库创建的用户只能在 test 库下进行验证

### 重新开启权限

我最初的想法是想修改容器的启动参数，但是因为容器初始化的参数固定，无法在重启容器的时候添加–auth 参数，所以需要修改 docker 对于容器的配置

进入对应容器的配置目录（Mac 下我没找到，在 Linux 下是这个目录）

```shell
cd /var/lib/docker/containers/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0/
```

这个时候需要修改 config.v2.json 文件，但在此之前我们先要停掉 docker 的容器以及 docker 服务

一键停止所有容器

```shell
docker stop $(docker ps -a | awk '{ print $1}' | tail -n +2)
```

停止 docker 服务

```shell
service docker stop
```

修改 config.v2.json 文件

```shell
vim config.v2.json

{"StreamConfig":{},"State":{"Running":false,"Paused":false,"Restarting":false,"OOMKilled":false,"RemovalInProgress":false,"Dead":false,"Pid":0,"ExitCode":0,"Error":"","StartedAt":"2019-08-20T08:34:25.416543086Z","FinishedAt":"2019-08-20T09:17:27.171798196Z","Health":null},"ID":"34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0","Created":"2019-08-20T08:34:25.009834225Z","Managed":false,"Path":"docker-entrypoint.sh","Args":["mongod"],"Config":{"Hostname":"34d5b5922f60","Domainname":"","User":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"ExposedPorts":{"27017/tcp":{}},"Tty":true,"OpenStdin":true,"StdinOnce":false,"Env":["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","GOSU_VERSION=1.11","JSYAML_VERSION=3.13.0","GPG_KEYS=E162F504A20CDF15827F718D4B7C549A058F8B6B","MONGO_PACKAGE=mongodb-org","MONGO_REPO=repo.mongodb.org","MONGO_MAJOR=4.2","MONGO_VERSION=4.2.0"],"Cmd":["mongod"],"Image":"mongo","Volumes":{"/data/configdb":{},"/data/db":{}},"WorkingDir":"","Entrypoint":["docker-entrypoint.sh"],"OnBuild":null,"Labels":{}},"Image":"sha256:cdc6740b66a71617b310e476e9b08d68a3be7af75beee27139dc8bc3d35ef4c5","NetworkSettings":{"Bridge":"","SandboxID":"2482ede74ca883de3171dc15fdb35349de5057cc726c1a2c3e64b191e92bbccd","HairpinMode":false,"LinkLocalIPv6Address":"","LinkLocalIPv6PrefixLen":0,"Networks":{"bridge":{"IPAMConfig":null,"Links":null,"Aliases":null,"NetworkID":"9937e1b9733f85002830ed1a11dfe29d7ae36ed9844393408ddc7cff199bfd6b","EndpointID":"","Gateway":"","IPAddress":"","IPPrefixLen":0,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"MacAddress":"","DriverOpts":null,"IPAMOperational":false}},"Service":null,"Ports":null,"SandboxKey":"/var/run/docker/netns/2482ede74ca8","SecondaryIPAddresses":null,"SecondaryIPv6Addresses":null,"IsAnonymousEndpoint":false,"HasSwarmEndpoint":false},"LogPath":"/var/lib/docker/containers/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0-json.log","Name":"/mongodb","Driver":"overlay2","OS":"linux","MountLabel":"","ProcessLabel":"","RestartCount":0,"HasBeenStartedBefore":true,"HasBeenManuallyStopped":true,"MountPoints":{"/data/configdb":{"Source":"","Destination":"/data/configdb","RW":true,"Name":"036f1ba2c8bcbdbe10c4581137ed41f0a071107389f499bd8b99f9ae5d723ca5","Driver":"local","Type":"volume","Spec":{},"SkipMountpointCreation":false},"/data/db":{"Source":"/var/lib/docker/volumes/mongodb/\_data","Destination":"/data/db","RW":true,"Name":"mongodb","Driver":"local","Type":"volume","Relabel":"z","Spec":{"Type":"volume","Source":"mongodb","Target":"/data/db"},"SkipMountpointCreation":false}},"SecretReferences":null,"ConfigReferences":null,"AppArmorProfile":"docker-default","HostnamePath":"/var/lib/docker/containers/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0/hostname","HostsPath":"/var/lib/docker/containers/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0/hosts","ShmPath":"","ResolvConfPath":"/var/lib/docker/containers/34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0/resolv.conf","SeccompProfile":"","NoNewPrivileges":false}
~
```

这里需要找到 Args 参数和 Cmd 参数，将对应到值从 **[“mongod”]** 都修改成 **[“–auth”]**

修改完成后重新启动 docker

```shell
service docker start
```

启动 mongodb 容器

```shell
docker start mongodb
```

查看容器详情

```shell
docker ps --no-trunc

CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
34d5b5922f60b7880262d315392a2dd230e96a01fb605fa63855ec5ecaf6b6b0 mongo "docker-entrypoint.sh --auth" About an hour ago Up 2 minutes 0.0.0.0:27017->27017/tcp mongodb
```

这个时候可以看到 command 已经变成了–auth 了，再来验证一下

进入容器

```shell
docker exec -it mongodb mongo admin
```

创建一个 test1 用户

```shell
db.createUser({user:"test1", pwd:"test", roles:[{role:"readWrite", db:"test"}]});

2019-08-20T09:45:32.254+0000 E QUERY [js] uncaught exception: Error: couldn't add user: command createUser requires authentication :
\_getErrorWithCode@src/mongo/shell/utils.js:25:13
DB.prototype.createUser@src/mongo/shell/db.js:1370:11
@(shell):1:1
```

报错，没有权限，说明这种方式完全成功

再试一下认证

```shell
db.auth("admin", "admin")
```

通过认证后再重新创建 test1 用户

```shell
db.createUser({user:"test1", pwd:"test", roles:[{role:"readWrite", db:"test"}]});

Successfully added user: {
    "user" : "test1",
    "roles" : [
        {
            "role" : "readWrite",
            "db" : "test"
        }
    ]
}
```

成功创建！
