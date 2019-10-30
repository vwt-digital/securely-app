# securely.ai
Securely WAF analytics helps to give inisght in attacks, false positives and configuration over all Web Application Firewalls. 
This repository contains documentation on how to set up securely for your Web Application Firewall.

## WAF integrations

### ModSecurity
1. Install the ModSecurity plugin for Nginx or Apache in your webserver
2. Update the OWASP Core Rule Set to the latest version

## Log Shipper configuration

### Rsyslog 8.10.0
If your Rsyslog version is 8.38.0 or higher, we recommend using the 8.38.0 configuration template, as it significantly decreases latency.

```
# Load module
module(load="imfile" PollingInterval="1")

# Read audit log
input(
      type="imfile" File="/var/log/modsec_audit.log"
      Tag="modsec"
      Severity="info"
      Facility="local7"
      readTimeout="5"
      startmsg.regex="^--[a-fA-F0-9]{8}-A--$"
)

# Certificates for TLS
$DefaultNetstreamDriverCAFile /etc/rsyslog-keys/ca.pem
$DefaultNetstreamDriverCertFile /etc/rsyslog-keys/node-cert.pem
$DefaultNetstreamDriverKeyFile /etc/rsyslog-keys/node-key.pem
$DefaultNetStreamDriver gtls
$ActionSendStreamDriverMode 1
$ActionSendStreamDriverAuthMode anon
$MaxMessageSize 64k
$template RFC3164fmtnl,"<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg%\n"

# Forward everything to remote server
local7.* @@(o)dev.securely.ai:514;RFC3164fmtnl
```

### Filebeat
```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/apache2/modsec_audit.log
    fields:
      organization.name: YOUR_ORGANIZATION_NAME
      event.module: modsecurity
      event.dataset: modsecurity.audit
    multiline:
      pattern: "^-{2,3}[a-zA-Z0-9]{8}-{1,3}Z--$"
      negate: true
      match: before
output.logstash:
  hosts: ["dev.securely.ai:5044"]
```