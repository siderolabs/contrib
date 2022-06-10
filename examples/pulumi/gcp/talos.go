package main

import (
	"fmt"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/siderolabs/pulumi-provider-talos/sdk/go/talos"
)

func (ri *ResourceInfo) createConfigs(ctx *pulumi.Context) error {
	clusterSecrets, err := talos.NewClusterSecrets(
		ctx,
		ClusterName+"-cluster-secrets",
		&talos.ClusterSecretsArgs{
			ClusterName: pulumi.String(ClusterName),
		},
	)
	if err != nil {
		return err
	}

	cc, err := talos.NewClusterConfig(
		ctx,
		ClusterName+"-cluster-config",
		&talos.ClusterConfigArgs{
			ClusterEndpoint: pulumi.Sprintf("https://%s:6443", ri.LBAddress.Address),
			ClusterName:     pulumi.String(ClusterName),
			Secrets:         clusterSecrets.Secrets,
		},
	)
	if err != nil {
		return err
	}

	ri.TalosClusterSecrets = clusterSecrets
	ri.TalosClusterConfig = cc

	return nil
}

func (ri *ResourceInfo) bootstrapTalos(ctx *pulumi.Context) error {
	_, err := talos.NewNodeBootstrap(
		ctx,
		ClusterName+"-bootstrap",
		&talos.NodeBootstrapArgs{
			Endpoint:    ri.CPAddresses[fmt.Sprintf("%s-cp-%d", ClusterName, 0)].Address,
			Node:        ri.CPAddresses[fmt.Sprintf("%s-cp-%d", ClusterName, 0)].Address,
			TalosConfig: ri.TalosClusterSecrets.TalosConfig,
		},
	)
	if err != nil {
		return err
	}

	return nil
}
