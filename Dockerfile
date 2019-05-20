FROM ubuntu:16.04

# Java Version
ENV  JAVA_VERSION=9.0.4 \
     JAVA_BUILD=11  \
     JAVA_HOME=/usr/lib/jvm/current-java

# ElasticSearch variables
ENV ESBIN=elasticsearch-6.2.4/bin \
    PLUGINPATH="file:elastik-nearest-neighbors/elasticsearch-aknn/build/distributions/elasticsearch-aknn-0.0.1-SNAPSHOT.zip"

# Install necessary stuff
RUN  apt-get update -y && apt-get upgrade -y

RUN apt-get install \
    wget \
    tar \
    bash \
    curl \
    unzip \
    git \
    -y

# Java install
RUN cd /tmp && \
    wget "http://download.java.net/java/GA/jdk9/${JAVA_VERSION}/binaries/openjdk-${JAVA_VERSION}_linux-x64_bin.tar.gz" && \
    tar xzf "openjdk-${JAVA_VERSION}_linux-x64_bin.tar.gz" && \
    mkdir -p /usr/lib/jvm && \
    mv "/tmp/jdk-${JAVA_VERSION}" "/usr/lib/jvm/openjdk-${JAVA_VERSION}"  && \
    ln -s "openjdk-${JAVA_VERSION}" $JAVA_HOME && \
    ln -s $JAVA_HOME/bin/java /usr/bin/java && \
    ln -s $JAVA_HOME/bin/javac /usr/bin/javac && \
    ln -s $JAVA_HOME/bin/jshell /usr/bin/jshell

RUN rm -rf $JAVA_HOME/*.txt && \
    rm -rf $JAVA_HOME/*.html && \
    rm -rf $JAVA_HOME/man && \
    rm -rf $JAVA_HOME/lib/src.zip && \
    rm /tmp/*

# Add user (can not run elasticsearch as root)
RUN useradd -ms /bin/bash dummy

# Download ES
RUN curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.4.tar.gz
RUN tar -xvf elasticsearch-6.2.4.tar.gz
RUN chown -R dummy elasticsearch-6.2.4

# Install gradle
RUN wget https://services.gradle.org/distributions/gradle-4.9-bin.zip -P /tmp
RUN unzip -d /opt/gradle /tmp/gradle-4.9-bin.zip
ENV GRADLE_HOME /opt/gradle/gradle-4.9

# Install plugin
RUN git clone https://github.com/alexklibisz/elastik-nearest-neighbors
RUN cd elastik-nearest-neighbors/elasticsearch-aknn/ && \
    $GRADLE_HOME/bin/gradle clean build -x integTestRunner -x test
RUN chown -R dummy elastik-nearest-neighbors

# Remove useless stuff
RUN apt-get remove --purge wget git unzip curl -y && apt-get clean

# Run ES
RUN $ESBIN/elasticsearch-plugin remove elasticsearch-aknn | true
RUN $ESBIN/elasticsearch-plugin install -b $PLUGINPATH
RUN sysctl -w vm.max_map_count=262144
ENV ES_HEAP_SIZE=512g 
#USER dummy
EXPOSE 9200 9300
#RUN cd elasticsearch-6.2.4/bin && ./elasticsearch
USER root

