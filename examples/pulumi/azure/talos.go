package main

import (
	"github.com/frezbo/pulumi-provider-talos/sdk/go/talos"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createTalosConfigs(ctx *pulumi.Context) error {
	clusterSecrets, err := talos.NewClusterSecrets(
		ctx,
		ClusterName+"-cluster-secrets",
		&talos.ClusterSecretsArgs{})
	if err != nil {
		return err
	}

	cc, err := talos.NewClusterConfig(
		ctx,
		ClusterName+"-cluster-config",
		&talos.ClusterConfigArgs{
			AdditionalSans:  ri.CPPubIPs,
			ClusterEndpoint: pulumi.Sprintf("https://%s:6443", ri.LBPubIP.IpAddress),
			ClusterName:     pulumi.String(ClusterName),
			Secrets:         clusterSecrets.Secrets,
		},
	)
	if err != nil {
		return err
	}

	ri.TalosClusterConfig = cc

	return nil
}

func (ri *ResourceInfo) bootstrapTalos(ctx *pulumi.Context) error {
	_, err := talos.NewNodeBootstrap(
		ctx,
		ClusterName+"-bootstrap",
		&talos.NodeBootstrapArgs{
			Endpoint:    ri.CPPubIPs[0],
			Node:        ri.CPPubIPs[0],
			TalosConfig: ri.TalosClusterConfig.TalosConfig,
		})
	if err != nil {
		return err
	}

	return nil
}
