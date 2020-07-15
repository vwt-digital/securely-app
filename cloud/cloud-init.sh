#!/bin/bash

metadata_url="http://metadata.google.internal/computeMetadata/v1/instance"
metadata_attr_url="${metadata_url}/attributes"

# Set environment variables retrieving value from metadata
echo "EXTERNAL_HOSTNAME=securely-$(curl -H "Metadata-Flavor: Google" "${metadata_url}/network-interfaces/0/access-configs/0/external-ip" | sed s/\\\\./-/g).nip.io" >> .env
echo "ELASTIC_PASSWORD=$(curl "${metadata_attr_url}/securely-elasticsearch-password" -H "Metadata-Flavor: Google")" >> .env

# Docker login securely-registry, retrieving password from metadata
curl "${metadata_attr_url}/securely-registry-password" -H "Metadata-Flavor: Google" |
    docker login registry.securely.ai -u customer-onprem --password-stdin

# Retrieve logstash inputs from metadata
mkdir -p config/logstash
for attrib in $(curl "${metadata_attr_url}/" -H "Metadata-Flavor: Google" | grep "\-logstash-input")
do
    curl "${metadata_attr_url}/${attrib}" -H "Metadata-Flavor: Google" > config/logstash/"${attrib}".conf
done

