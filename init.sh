#!/bin/bash
if [ ! -f ".env" ]; then
    echo "ELASTIC_PASSWORD=ELASTIC_PASSWORD_PLACEHOLDER
KIBANA_ENCRYPTIONKEY=KIBANA_ENCRYPTIONKEY_PLACEHOLDER" >> .env
fi
# Auto elastic default password
(grep -qF "ELASTIC_PASSWORD_PLACEHOLDER" .env) && {
  PASSWORD=`openssl rand -base64 32 | tr -d /=+ | head -c 16`
  sed -i ''  "s/ELASTIC_PASSWORD_PLACEHOLDER/$PASSWORD/" .env
  echo "Elastic password is saved in .env"
}

# Auto kibana encryption key
(grep -qF "KIBANA_ENCRYPTIONKEY_PLACEHOLDER" .env) && {
  PASSWORD=`openssl rand -base64 32 | tr -d /=+ | head -c 16`
  sed -i '' "s/KIBANA_ENCRYPTIONKEY_PLACEHOLDER/$PASSWORD/" .env
  echo "Kibana encryption key is saved in .env"
}
