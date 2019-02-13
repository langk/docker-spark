
TODO:


DONE:

[1] worker(s) are not started when docker images is run:

added section in bootstrap.sh to start a single worker within the container

HOWTO - Command line:

```
docker exec -ti spark /bins/bash
cd /opt/spark/sbin
./start-slave.sh spark://`hostname -f`:7077
```

HOWTO - Section in bootstrap.sh
```
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

. "${SPARK_HOME}/sbin/spark-config.sh"
. "${SPARK_HOME}/bin/load-spark-env.sh"

# Find the port number for the master
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi

if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
          SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
          ;;
      (*)
          SPARK_MASTER_HOST="`hostname -f`"
          ;;
  esac
fi

# Launch the slave locally
"${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
```
[2] bootstrap.sh 

1. replaced $HADOOP-PREFIX/sbin/start-all with start-dfs.sh and start-yarn.sh:
```
start-dfs.sh
start-yarn.sh
```
