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

# Configure certificates
mkdir -p config/securely-certs
# Mount certificate directory
sed -i "s/- logstash-backup:\/usr\/share\/logstash\/backup/- logstash-backup:\/usr\/share\/logstash\/backup\n      - .\/config\/securely-certs:\/securely-certs" docker-compose.yml
# Add beats input conf configured for ssl server and client authentication
sed -i "s/- logstash-backup:\/usr\/share\/logstash\/backup/- logstash-backup:\/usr\/share\/logstash\/backup\n      - .\/config\/logstash\/101_beats.conf:\/usr\/share\/logstash\/pipeline\/normalize\/input\/101_beats.conf/" docker-compose.yml

# Retrieve certificates and keys from meta data
if curl "${metadata_attr_url}/" -H "Metadata-Flavor: Google" | grep -q "^securely-cert"
then
    curl "${metadata_attr_url}/securely-cert" -H "Metadata-Flavor: Google" > config/securely-certs/securely.crt
    curl "${metadata_attr_url}/securely-cert-key" -H "Metadata-Flavor: Google" > config/securely-certs/securely.key.pem
    curl "${metadata_attr_url}/securely-ca" -H "Metadata-Flavor: Google" > config/securely-certs/ca.pem
fi

# Translate key to pkcs8 format, as required by logstash
openssl pkcs8 -topk8 -in config/securely-certs/securely.key.pem -out config/securely-certs/securely.key.p8c -nocrypt
