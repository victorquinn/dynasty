#!/bin/bash

mkdir -p ~/dynamo-local
cd ~/dynamo-local
curl -O https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz
tar xzvf dynamodb_local_latest.tar.gz
java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb
