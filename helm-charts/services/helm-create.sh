#!/usr/bin/env bash

services=("paper" "scissor" "aggregator" "rock")

for service in "${services[@]}"; do
    helm create $service --starter microservice-0.1.0.tgz
done