""" This template creates a Compute Instance with Securely App."""


def create_disks(properties, zone, instance_name):
    """ Create a boot disk and optional additional disk configuration. """

    disk_name = instance_name
    boot_disk = {
        "deviceName": disk_name,
        "type": "PERSISTENT",
        "boot": True,
        "autoDelete": True,
        "initializeParams": {
            "sourceImage": properties["disk_image"]
        }
    }

    disk_params = boot_disk["initializeParams"]

    disk_size_gb = properties.get("disk_size_gb")
    if disk_size_gb:
        disk_params["diskSizeGb"] = disk_size_gb

    disk_type = properties.get("disk_type")
    if disk_type:
        disk_params["diskType"] = "zones/{}/diskTypes/{}".format(zone, disk_type)

    disks = [boot_disk]

    additional_disk_type = properties.get("additional_disk_type")
    if additional_disk_type:
        additional_disk = {
            "boot": False,
            "initializeParams": {
                "diskType": "zones/{}/diskTypes/{}".format(zone, additional_disk_type),
            }
        }

        additional_disk_size_gb = properties.get("additional_disk_size_gb")
        if additional_disk_size_gb:
            additional_disk["initializeParams"]["diskSizeGb"] = additional_disk_size_gb

        if additional_disk_type == "local-ssd":
            additional_disk["type"] = "SCRATCH"
            additional_disk["autoDelete"] = True
            additional_disk["interface"] = "NVME"

        disks.append(additional_disk)

    return disks


def create_network_interfaces(project_id):
    natIPref = "$(ref.{project_id}-securely-ip.address)".format(project_id=project_id)
    network_interfaces = [
        {
            "network": "$(ref.{project_id}-securely-vn.selfLink)".format(project_id=project_id),
            "accessConfigs": [
                {
                    "type": "ONE_TO_ONE_NAT",
                    "natIP": natIPref
                }
            ]
        }
    ]

    return network_interfaces


def create_metadata(properties, imports):
    metadata = {
        "items": [
            {
                "key": "securely-registry-password",
                "value": properties["securely_registry_password"]
            },
            {
                "key": "securely-elasticsearch-password",
                "value": properties["securely_elasticsearch_password"]
            },
            {
                "key": "user-data",
                "value": imports["google-cloud-init.yml"]
            }
        ]
    }

    if "securely-cert" in imports and "securely-cert-key" in imports:
        metadata["items"].append(
            {
                "key": "securely-cert",
                "value": imports["securely-cert"]
            })
        metadata["items"].append(
            {
                "key": "securely-cert-key",
                "value": imports["securely-cert-key"]
            })
        metadata["items"].append(
            {
                "key": "securely-ca",
                "value": imports["securely-ca"]
            })

    for k, v in imports.items():
        if k.endswith("-logstash-input"):
            metadata["items"].append({
                "key": k,
                "value": v
            })

    return metadata


def create_service_accounts(properties):
    service_accounts = [
        {
            "email": properties["service_account_email"],
            "scopes": ["https://www.googleapis.com/auth/cloud-platform"]
        }
    ]
    return service_accounts


def ZoneToRegion(zone):
    """Derives the region from a zone name."""
    parts = zone.split('-')
    if len(parts) != 3:
        raise ValueError('Cannot derive region from zone "%s"' % zone)
    return '-'.join(parts[:2])


def generate_config(context):
    """ Entry point for the deployment resources. """
    properties = context.properties
    zone = properties['zone']
    machine_type = properties['machine_type']
    project_id = properties.get('project', context.env['project'])

    network = {
        "name": "{project_id}-securely-vn".format(project_id=project_id),
        "type": "gcp-types/compute-v1:networks",
        "properties": {
            "autoCreateSubnetworks": True
        }
    }

    ip_address = {
        "name": "{project_id}-securely-ip".format(project_id=project_id),
        "type": "gcp-types/compute-v1:addresses",
        "properties": {
            "description": "IP address for Securely App server",
            "region": ZoneToRegion(zone)
        }
    }

    ports_to_open = ["5044", "50052"]
    ports_to_open.extend(properties.get('additional_open_ports', []))
    firewall_securely = {
        "name": "{project_id}-securely-fw".format(project_id=project_id),
        "type": "gcp-types/compute-v1:firewalls",
        "properties": {
            "network": "$(ref.{project_id}-securely-vn.selfLink)".format(project_id=project_id),
            "targetTags": ["securely"],
            "allowed": [
                {
                    "IPProtocol": "tcp",
                    "ports": ports_to_open
                }
            ]
        },
        "metadata": {
            "dependsOn": [
                "{project_id}-securely-vn".format(project_id=project_id)
            ]
        }
    }

    firewall_iap_tunnel = {
        "name": "{project_id}-securely-iap-fw".format(project_id=project_id),
        "type": "gcp-types/compute-v1:firewalls",
        "properties": {
            "network": "$(ref.{project_id}-securely-vn.selfLink)".format(project_id=project_id),
            "targetTags": ["securely"],
            "sourceRanges": ["35.235.240.0/20"],
            "allowed": [
                {
                    "IPProtocol": "tcp",
                    "ports": ["22"]
                }
            ]
        },
        "metadata": {
            "dependsOn": [
                "{project_id}-securely-vn".format(project_id=project_id)
            ]
        }
    }

    instance_name = "{project_id}-securely-vm".format(project_id=project_id)
    securely_vm = {
        "name": instance_name,
        "type": "gcp-types/compute-v1:instances",
        "properties": {
            "zone": zone,
            "project": project_id,
            "tags": {
                "items": ["securely"],
            },
            "machineType": "zones/{zone}/machineTypes/{machine_type}".format(zone=zone, machine_type=machine_type),
            "disks": create_disks(properties, zone, instance_name),
            "networkInterfaces": create_network_interfaces(project_id),
            "metadata": create_metadata(properties, context.imports),
            "serviceAccounts": create_service_accounts(properties)
        },
        "metadata": {
            "dependsOn": [
                "{project_id}-securely-vn".format(project_id=project_id),
                "{project_id}-securely-ip".format(project_id=project_id)
            ]
        }
    }

    return {
        "resources": [network, ip_address, firewall_securely, firewall_iap_tunnel, securely_vm]
    }
