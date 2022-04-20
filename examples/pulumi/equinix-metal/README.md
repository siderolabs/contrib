# talos-em

This project brings up an example Talos HA cluster on Equinix Metal

## Setup

Set the equinix metal project id and equinix metal api token

```bash
pulumi config set projectID <equinix metal project id>
pulumi config set equinix-metal:authToken --secret
```


## getting talosconfig

> NB: This is the admin talosconfig, generate different talosconfig for other users

`pulumi stack output talosConfig --show-secrets`

## getting admin kubeconfig

`pulumi stack output kubeconfig --show-secrets`
