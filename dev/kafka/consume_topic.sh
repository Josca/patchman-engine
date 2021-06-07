#!/bin/sh

/usr/bin/kafka-console-consumer --bootstrap-server=kafka:9092 --from-beginning --topic $1
