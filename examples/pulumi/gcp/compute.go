package main

import (
	"fmt"
	"strings"

	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/compute"
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createImage(ctx *pulumi.Context) error {
	imgName := strings.Replace("talos-"+TalosVersion, ".", "-", -1)

	obj, err := storage.NewBucketObject(
		ctx,
		imgName+".tar.gz",
		&storage.BucketObjectArgs{
			Bucket: ri.Bucket.Name,
			Name:   pulumi.String(imgName + ".tar.gz"),
			Source: pulumi.NewRemoteAsset("https://github.com/siderolabs/talos/releases/download/" + TalosVersion + "/gcp-amd64.tar.gz"),
		},
	)
	if err != nil {
		return err
	}

	img, err := compute.NewImage(
		ctx,
		imgName,
		&compute.ImageArgs{
			Name: pulumi.String(imgName),
			RawDisk: &compute.ImageRawDiskArgs{
				Source: obj.MediaLink.ToStringOutput(),
			},
		},
	)
	if err != nil {
		return err
	}

	ri.Image = img

	return nil
}

func (ri *ResourceInfo) createCPVMs(ctx *pulumi.Context) error {
	for i := 0; i < ControlPlaneNodesCount; i++ {
		instance, err := compute.NewInstance(
			ctx,
			fmt.Sprintf("%s-cp-%d", ClusterName, i),
			&compute.InstanceArgs{
				MachineType: pulumi.String("e2-medium"),
				BootDisk: &compute.InstanceBootDiskArgs{
					InitializeParams: &compute.InstanceBootDiskInitializeParamsArgs{
						Image: ri.Image.SelfLink.ToStringOutput(),
						Size:  pulumi.IntPtr(10),
					},
				},
				Metadata: pulumi.StringMap{"user-data": ri.TalosClusterConfig.ControlplaneConfig},
				NetworkInterfaces: compute.InstanceNetworkInterfaceArray{
					&compute.InstanceNetworkInterfaceArgs{
						Network: ri.Network.Name,
						AccessConfigs: compute.InstanceNetworkInterfaceAccessConfigArray{
							&compute.InstanceNetworkInterfaceAccessConfigArgs{
								NatIp: ri.CPAddresses[fmt.Sprintf("%s-cp-%d", ClusterName, i)].Address,
							},
						},
					},
				},
				Tags: pulumi.StringArray{
					pulumi.String(ClusterName + "-cp"),
				},
				Zone: pulumi.String(ri.Zone),
			},
		)
		if err != nil {
			return err
		}

		ri.CPInstances = append(ri.CPInstances, instance)
	}

	return nil
}

func (ri *ResourceInfo) createWorkerVMs(ctx *pulumi.Context) error {
	for i := 0; i < WorkerNodesCount; i++ {
		_, err := compute.NewInstance(
			ctx,
			fmt.Sprintf("%s-worker-%d", ClusterName, i),
			&compute.InstanceArgs{
				MachineType: pulumi.String("e2-medium"),
				BootDisk: &compute.InstanceBootDiskArgs{
					InitializeParams: &compute.InstanceBootDiskInitializeParamsArgs{
						Image: ri.Image.SelfLink.ToStringOutput(),
						Size:  pulumi.IntPtr(10),
					},
				},
				Metadata: pulumi.StringMap{"user-data": ri.TalosClusterConfig.WorkerConfig},
				NetworkInterfaces: compute.InstanceNetworkInterfaceArray{
					&compute.InstanceNetworkInterfaceArgs{
						Network: ri.Network.Name,
						AccessConfigs: compute.InstanceNetworkInterfaceAccessConfigArray{
							&compute.InstanceNetworkInterfaceAccessConfigArgs{
								NatIp: ri.WorkerAddresses[fmt.Sprintf("%s-worker-%d", ClusterName, i)].Address,
							},
						},
					},
				},
				Tags: pulumi.StringArray{
					pulumi.String(ClusterName + "-worker"),
				},
				Zone: pulumi.String(ri.Zone),
			},
		)
		if err != nil {
			return err
		}
	}

	return nil
}
