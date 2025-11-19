package main

import (
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/compute"
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
	"github.com/siderolabs/pulumi-provider-talos/sdk/go/talos"
)

const (
	ClusterName  = "talos"
	TalosVersion = "v1.11.5"

	ControlPlaneNodesCount = 3
	WorkerNodesCount       = 2
)

// ResourceInfo holds pointers to the various resources that
// need to be passed around to each other.
type ResourceInfo struct {
	PulumiConfig *config.Config

	BucketLocation string
	Region         string
	Zone           string

	Bucket *storage.Bucket
	Image  *compute.Image

	Network *compute.Network

	CPInstances     []*compute.Instance
	CPAddresses     map[string]*compute.Address
	WorkerAddresses map[string]*compute.Address
	LBAddress       *compute.GlobalAddress

	TalosClusterConfig  *talos.ClusterConfig
	TalosClusterSecrets *talos.ClusterSecrets
}

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		ri := ResourceInfo{
			CPInstances:     []*compute.Instance{},
			CPAddresses:     map[string]*compute.Address{},
			WorkerAddresses: map[string]*compute.Address{},
		}

		// TODO: understand how to either set these programatically or let
		// GCP choose for zone during instance creation.
		ri.PulumiConfig = config.New(ctx, "")

		region := ri.PulumiConfig.Get("region")
		if region == "" {
			region = "us-central1"
		}

		ri.Region = region

		zone := ri.PulumiConfig.Get("zone")
		if zone == "" {
			zone = "us-central1-a"
		}

		ri.Zone = zone

		// Create an Storage Bucket
		err := ri.createStorage(ctx)
		if err != nil {
			return err
		}

		// Upload blob and create image
		err = ri.createImage(ctx)
		if err != nil {
			return err
		}

		// Create a virtual networkf or us to use
		err = ri.createNetworks(ctx)
		if err != nil {
			return err
		}

		// Carve out IP Addresses
		err = ri.createCPAddresses(ctx)
		if err != nil {
			return err
		}

		err = ri.createWorkerAddresses(ctx)
		if err != nil {
			return err
		}

		err = ri.createLBAddress(ctx)
		if err != nil {
			return err
		}

		// Setup all firewall rules
		err = ri.createFirewalls(ctx)
		if err != nil {
			return err
		}

		// Create Talos configs
		err = ri.createConfigs(ctx)
		if err != nil {
			return err
		}

		// Create VMs
		err = ri.createCPVMs(ctx)
		if err != nil {
			return err
		}

		err = ri.createWorkerVMs(ctx)
		if err != nil {
			return err
		}

		// Create K8s loadbalancer
		err = ri.createLB(ctx)
		if err != nil {
			return err
		}

		// Bootstrap it
		err = ri.bootstrapTalos(ctx)
		if err != nil {
			return err
		}

		for _, ip := range ri.CPAddresses {
			ctx.Export("controlPlaneIP", ip.Address)
		}

		ctx.Export("loadBalancerIP", ri.LBAddress.Address)
		ctx.Export("talosConfig", ri.TalosClusterSecrets.TalosConfig)

		return nil
	})
}
