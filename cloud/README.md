# Deploying Securely App using GCP Deployment manager

Deployment of Securely App to a VM instance with a [container-optimized OS](https://cloud.google.com/container-optimized-os/docs) using [Deployment manager](https://cloud.google.com/deployment-manager/docs).

## Usage

To deploy Securely App, access to the Securely container registry is required. The access key to this registry should be specified in the configuration yaml.
[google-cloud-instance.example.yaml](google-cloud-instance.example.yaml) is a template for this file. Copy it and change it to match your configuration:
```
cp google-cloud-instance.example.yaml google-cloud-instance.yaml
```
Change the securely_registry_password to the access key you've received from Securely.
Change the securely_elasticsearch_password to a password you define. Remember this password, as you will need it to access the Securely App.
Next, deploy the configuration to a GCP project:
```
gcloud deployment-manager deployments create my-securely-deployment --config=google-cloud-instance.yaml
```
This will create the VM with a container-optimized OS and deploy Securely App to it. Once the deployment is finished, Securely App will be running on the VM.
