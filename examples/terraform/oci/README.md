# Oracle Cloud Terraform Example

Example of a highly available Kubernetes cluster with Talos on Oracle Cloud.

## Prequisites

**general**

- a top-level tenancy

**install things**

``` bash
brew install oci-cli hashicorp/tap/terraform siderolabs/tap/talosctl qemu
```

## Notes

- although not officially supported by Oracle Cloud, network LoadBalancers are provided through the Oracle Cloud Controller (only officially supported on OKE)
- this guide will target arm64, though you can replace with amd64 if it doesn't suit your needs
- instances will only launch with firmware set to UEFI_64 and lauch mode set to PARAVIRTUALIZED

## Uploading an image

Unfortunately due to upload constraints, this portion of the deployment is unable to be run using Terraform. This may change in the future.

Prepare and upload a Talos disk image for Oracle Cloud, with

1. create a storage bucket: https://cloud.oracle.com/object-storage/buckets
2. using Talos Linux Image Factory, create a plan and generate an image to use. See this example: https://factory.talos.dev/?arch=arm64&cmdline=console%3DttyAMA0&cmdline-set=true&extensions=-&platform=oracle&target=cloud&version=1.8.0
3. download the disk image (ending in raw.xz)
4. define the image metadata, with the steps under the section "**defining metadata**"
5. repack the image, with steps under the section "**repacking the image**"
6. upload the image to the storage bucket under objects
7. under object and view object details, copy the dedicated endpoint url. Example: https://axe608t7iscj.objectstorage.us-phoenix-1.oci.customer-oci.com/n/axe608t7iscj/b/talos/o/talos-v1.8.0-oracle-arm64.oci

### defining metadata

create a file called `image_metadata.json` with contents such as

``` json
{
    "version": 2,
    "externalLaunchOptions": {
        "firmware": "UEFI_64",
        "networkType": "PARAVIRTUALIZED",
        "bootVolumeType": "PARAVIRTUALIZED",
        "remoteDataVolumeType": "PARAVIRTUALIZED",
        "localDataVolumeType": "PARAVIRTUALIZED",
        "launchOptionsSource": "PARAVIRTUALIZED",
        "pvAttachmentVersion": 2,
        "pvEncryptionInTransitEnabled": true,
        "consistentVolumeNamingEnabled": true
    },
    "imageCapabilityData": null,
    "imageCapsFormatVersion": null,
    "operatingSystem": "Talos",
    "operatingSystemVersion": "1.8.0",
    "additionalMetadata": {
        "shapeCompatibilities": [
            {
                "internalShapeName": "VM.Standard.A1.Flex",
                "ocpuConstraints": null,
                "memoryConstraints": null
            }
        ]
    }
}
```

### repacking the image

decompress the downloaded disk image artifact from factory

``` bash
xz --decompress DISK_IMAGE.raw.xz
```

use `qemu-img` to convert the image to qcow2

``` bash
qemu-img convert -f raw -O qcow2 oracle-arm64.raw oracle-arm64.qcow2
```

repack the image as a tar file with the metadata

``` bash
tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json
```

## Create a .tfvars file

to configure authentication and namespacing, create a `.tfvars` file with values from the links placeholding in the example below

``` hcl
tenancy_ocid               = "TENANCY OCID                         : https://cloud.oracle.com/tenancy"
user_ocid                  = "YOUR USER OCID                       : https://cloud.oracle.com/identity/domains/my-profile"
private_key_path           = "YOUR PRIVATE KEY PATH                : https://cloud.oracle.com/identity/domains/my-profile/api-keys"
fingerprint                = "THE FINGERPRINT FOR YOUR PRIVATE KEY : ^^"
region                     = "YOUR PREFERRED REGION                : https://cloud.oracle.com/regions"
compartment_ocid           = "YOUR COMPARTMENT OCID                : https://cloud.oracle.com/identity/compartments"
talos_image_oci_bucket_url = "YOUR DEDICATED BUCKET OBJECT URL     : https://cloud.oracle.com/object-storage/buckets"
```

## Bringing it up

prepare the local direction for using Terraform

``` bash
terraform init
```

verify the changes to provision

``` bash
terraform plan -var-file=.tfvars
```

apply the changes

``` bash
terraform apply -var-file=.tfvars
```

get the talosconfig

``` bash
terraform output -raw talosconfig > ./talosconfig
```

get the kubeconfig

``` bash
terraform output -raw kubeconfig > ./kubeconfig
```

destroy the worker nodes

``` bash
terraform destroy -var-file=.tfvars -target=random_pet.worker
```

destroy

``` bash
terraform destroy -var-file=.tfvars
```
