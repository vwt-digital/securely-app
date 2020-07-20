#!/bin/bash

metadata_url="http://metadata.google.internal/computeMetadata/v1/instance"
metadata_attr_url="${metadata_url}/attributes"

echo "ELASTIC_PASSWORD=$(curl "${metadata_attr_url}/securely-elasticsearch-password" -H "Metadata-Flavor: Google")" >> .env

# Docker login securely-registry, retrieving password from metadata
curl "${metadata_attr_url}/securely-registry-password" -H "Metadata-Flavor: Google" |
    docker login registry.securely.ai -u customer-onprem --password-stdin

# Retrieve logstash inputs from metadata
mkdir -p config/logstash
for attrib in $(curl "${metadata_attr_url}/" -H "Metadata-Flavor: Google" | grep "\-logstash-input")
do
    curl "${metadata_attr_url}/${attrib}" -H "Metadata-Flavor: Google" > config/logstash/"${attrib}".conf
    sed -i "s/- logstash-backup:\/usr\/share\/logstash\/backup/- logstash-backup:\/usr\/share\/logstash\/backup\n      - .\/config\/logstash\/${attrib}.conf:\/usr\/share\/logstash\/pipeline\/normalize\/input\/${attrib}.conf/" docker-compose.yml
done

if curl "${metadata_attr_url}/" -H "Metadata-Flavor: Google" | grep -q "^securely-cert"
then
    curl "${metadata_attr_url}/securely-cert" -H "Metadata-Flavor: Google" > /etc/ssl/certs/securely.crt
    curl "${metadata_attr_url}/securely-cert-key" -H "Metadata-Flavor: Google" > /etc/ssl/certs/securely.key.pem
fi
