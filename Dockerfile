# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations

#####################################
# Basic CentoOS Image
#

FROM centos:7
LABEL author "Konrad Lang"
LABEL maintainer "Konrad Lang klang@know-center.at"

USER root

# Clean metadata to avoid 404 erros from yum
RUN yum clean all

#####################
# security

# install dev tools
RUN yum install -y curl which tar sudo openssh-server openssh-clients rsync | true && \
    yum update -y libselinux | true && \
    # update root password
    echo 'root:passw0rd' | chpasswd && \
    # passwordless ssh
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config && \
    # fix the 254 error code
    sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "Port 2122" >> /etc/ssh/sshd_config
    
#####################
# java
# problem with license accept, using v131 
# see Stackoverflow: https://stackoverflow.com/questions/10268583/downloading-java-jdk-on-linux-via-wget-is-shown-license-page-instead#10959815
RUN curl -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm" > "jdk-8u131-linux-x64.rpm"
RUN rpm -i jdk-8u131-linux-x64.rpm
RUN rm jdk-8u131-linux-x64.rpm

#RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie' && \
#    rpm -i jdk-8u144-linux-x64.rpm && \
#    rm jdk-8u144-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin


#####################
# Hadoop

RUN curl -s https://archive.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz | tar -xz -C /opt/ && \
    rm -rf hadoop-2.7.3.tar.gz && \
    cd /opt && ln -s ./hadoop-2.7.3 hadoop

ENV HADOOP_PREFIX /opt/hadoop
ENV HADOOP_COMMON_HOME /opt/hadoop
ENV HADOOP_HDFS_HOME /opt/hadoop
ENV HADOOP_MAPRED_HOME /opt/hadoop
ENV HADOOP_YARN_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/opt/hadoop\nexport HADOOP_HOME=/opt/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD hadoop/conf/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
#RUN sed s/HOSTNAME/localhost/ /opt/hadoop/etc/hadoop/core-site.xml.template > /opt/hadoop/etc/hadoop/core-site.xml
ADD hadoop/conf/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD hadoop/conf/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD hadoop/conf/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

# fixing the libhadoop.so like a boss
#RUN rm  /opt/hadoop/lib/native/*
#RUN curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64-2.7.0.tar | tar -x -C /opt/hadoop/lib/native/

# workaround docker.io build error
RUN ls -la /opt/hadoop/etc/hadoop/*-env.sh && \
    chmod +x /opt/hadoop/etc/hadoop/*-env.sh && \
    ls -la /opt/hadoop/etc/hadoop/*-env.sh

#####################
# Spark

RUN curl -s 'https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz' | tar -xz -C /opt/ && \
    rm -rf spark-2.2.0-bin-hadoop2.7.tgz && \
    cd /opt && ln -s ./spark-2.2.0-bin-hadoop2.7 spark

#ADD source/spark-1.6.0-bin-hadoop2.6.tgz /opt/
ADD spark/conf/spark-env.sh /opt/spark-2.2.0-bin-hadoop2.7/conf/spark-env.sh
ADD spark/conf/slaves /opt/spark-2.2.0-bin-hadoop2.7/conf/slaves

ENV SPARK_HOME /opt/spark
ENV SPARK_MASTER_IP=127.0.0.1

#####################
# clean yum cache

RUN yum clean all

#####################

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122   
# Spark submit, admin console, executor, history server
EXPOSE 7077 8080 65000 65001 65002 8085 8086 8087 18080