#!/bin/sh

MSG=$1
TOPIC=$2

echo $MSG | /usr/bin/kafka-console-producer --broker-list kafka:9092 --topic $TOPIC
