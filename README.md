# Getting Started with Apache Spark

This is going to quickly enable you to use Apache Spark as a single Docker container with one master and one worker.

The original Dockerfile was forked from [lresende/docker-spark](https://github.com/lresende/docker-spark) and updated to reflect changes in Java RPM downloads and the number of workers to be started.

## Running
First, let's start by bringing up a small Spark one node cluster with one master and one worker packaged as a docker image.

```
docker run -d --name spark -p 7077:7077 -p 8080:8080 -p 8081:8081  -p 8085:8085 -p 8086:8086 -p 8087:8087 -p 8088:8088 -p 50070:50070 -p 6500:6500 -p 6501:6501 -p 6502:6502 -p 18080:18080 kcklang/docker-spark:1.0.0
```

*Note:* If you are using docker via docker-machine, you need to identify the docker machine ip address, otherwise, in a native linux environment you could use localhost.

```
VM_IP="$(docker-machine ip default)"
```

And then access the different exposed UIs via

* Spark Console http://$VM_IP:8080
* Yarn  Console http://$VM_IP:8088
* HDFS  Console http://$VM_IP:50070