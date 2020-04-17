#!/bin/bash

gcloud compute instances create securely-test \
     --tags securely \
     --image-family cos-stable \
     --image-project cos-cloud \
     --local-ssd interface=nvme \
     --metadata-from-file user-data=google-cloud-init.yml \
     --metadata securely-registry-password="API_TOKEN",securely-elasticsearch-password="changeme" \
     --machine-type n1-standard-4 \
     --preemptible

gcloud compute firewall-rules create securely-kibana \
     --rules tcp:80 \
     --target-tags securely \
     --action allow

gcloud compute firewall-rules create securely-filebeat \
     --rules tcp:5044 \
     --target-tags securely \
     --action allow
