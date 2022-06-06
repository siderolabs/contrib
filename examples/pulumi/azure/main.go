package main

import (
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/compute"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/core"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/lb"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/network"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
	"github.com/siderolabs/pulumi-provider-talos/sdk/go/talos"
)

const (
	ClusterName  = "talos"
	TalosVersion = "v1.0.4"

	ControlPlaneNodesCount = 3
	WorkerNodesCount       = 2

	LocalVHDName = "disk.vhd"
)

// ResourceInfo holds pointers to the various resources that
// need to be passed around to each other.
type ResourceInfo struct {
	Location string

	ResourceGroup *core.ResourceGroup

	StorageAcct      *storage.Account
	StorageContainer *storage.Container

	Image *compute.Image

	Subnet          *network.Subnet
	CPSecurityGroup *network.NetworkSecurityGroup
	CPNics          map[string]*network.NetworkInterface
	// CPPubIPs is more of a convenience here than anything.
	// Keeps us from having to go through each nic, find the IP resource,
	// look that up then get the IP address.
	CPPubIPs            pulumi.StringArray
	WorkerSecurityGroup *network.NetworkSecurityGroup
	WorkerNics          map[string]*network.NetworkInterface
	LBPubIP             *network.PublicIp
	LBBackendPool       *lb.BackendAddressPool

	TalosClusterConfig  *talos.ClusterConfig
	TalosClusterSecrets *talos.ClusterSecrets
}

func (ri *ResourceInfo) createRG(ctx *pulumi.Context) error {
	resourceGroup, err := core.NewResourceGroup(
		ctx,
		ClusterName+"-rg",
		&core.ResourceGroupArgs{
			Location: pulumi.String(ri.Location),
			Name:     pulumi.String(ClusterName + "-rg"),
		},
	)
	if err != nil {
		return err
	}

	ri.ResourceGroup = resourceGroup

	return nil
}

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		ri := ResourceInfo{
			CPNics:     map[string]*network.NetworkInterface{},
			WorkerNics: map[string]*network.NetworkInterface{},
		}

		c := config.New(ctx, "")

		location := c.Get("location")
		if location == "" {
			location = "centralus"
		}

		ri.Location = location

		// Create an Azure Resource Group
		err := ri.createRG(ctx)
		if err != nil {
			return err
		}

		// Create an Storage Bucket
		err = ri.createStorage(ctx)
		if err != nil {
			return err
		}

		// Upload blob and create image
		err = ri.createImage(ctx)
		if err != nil {
			return err
		}

		// Setup security groups
		err = ri.createSecurityGroups(ctx)
		if err != nil {
			return err
		}

		// Setup networks
		err = ri.CreateNetworks(ctx)
		if err != nil {
			return err
		}

		// Setup LB
		err = ri.createLB(ctx)
		if err != nil {
			return err
		}

		// Create nics for CP to use
		err = ri.createCPNics(ctx)
		if err != nil {
			return err
		}

		// Create nics for Worker to use
		err = ri.createWorkerNics(ctx)
		if err != nil {
			return err
		}

		// Create Talos configs
		err = ri.createConfigs(ctx)
		if err != nil {
			return err
		}

		// Create control plane nodes
		err = ri.createCPVMs(ctx)
		if err != nil {
			return err
		}

		// Create worker nodes
		err = ri.createWorkerVMs(ctx)
		if err != nil {
			return err
		}

		// Create Talos configs
		err = ri.bootstrapTalos(ctx)
		if err != nil {
			return err
		}

		ctx.Export("loadBalancerIP", ri.LBPubIP.IpAddress)
		ctx.Export("controlPlaneIPs", ri.CPPubIPs)
		ctx.Export("talosConfig", ri.TalosClusterSecrets.TalosConfig)

		return nil
	})
}
