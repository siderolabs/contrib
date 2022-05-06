// network.go holds functions specific to Azure network resources
package main

import (
	"fmt"

	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/lb"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/network"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createSecurityGroups(ctx *pulumi.Context) error {
	cpSecGroup, err := network.NewNetworkSecurityGroup(
		ctx,
		ClusterName+"-cpsg",
		&network.NetworkSecurityGroupArgs{
			ResourceGroupName: ri.ResourceGroup.Name,
			SecurityRules: network.NetworkSecurityGroupSecurityRuleArray{
				&network.NetworkSecurityGroupSecurityRuleArgs{
					Name:                     pulumi.String("Talos API"),
					Priority:                 pulumi.Int(100),
					Direction:                pulumi.String("Inbound"),
					Access:                   pulumi.String("Allow"),
					Protocol:                 pulumi.String("Tcp"),
					SourcePortRange:          pulumi.String("*"),
					DestinationPortRange:     pulumi.String("50000"),
					SourceAddressPrefix:      pulumi.String("*"),
					DestinationAddressPrefix: pulumi.String("*"),
				},
				&network.NetworkSecurityGroupSecurityRuleArgs{
					Name:                     pulumi.String("Kube API"),
					Priority:                 pulumi.Int(101),
					Direction:                pulumi.String("Inbound"),
					Access:                   pulumi.String("Allow"),
					Protocol:                 pulumi.String("Tcp"),
					SourcePortRange:          pulumi.String("*"),
					DestinationPortRange:     pulumi.String("6443"),
					SourceAddressPrefix:      pulumi.String("*"),
					DestinationAddressPrefix: pulumi.String("*"),
				},
			},
		})
	if err != nil {
		return err
	}

	ri.CPSecurityGroup = cpSecGroup

	workerSecGroup, err := network.NewNetworkSecurityGroup(
		ctx,
		ClusterName+"-workersg",
		&network.NetworkSecurityGroupArgs{
			ResourceGroupName: ri.ResourceGroup.Name,
			SecurityRules:     network.NetworkSecurityGroupSecurityRuleArray{},
		})
	if err != nil {
		return err
	}

	ri.WorkerSecurityGroup = workerSecGroup

	return nil
}

func (ri *ResourceInfo) CreateNetworks(ctx *pulumi.Context) error {
	vnet, err := network.NewVirtualNetwork(
		ctx,
		ClusterName+"-vnet",
		&network.VirtualNetworkArgs{
			AddressSpaces: pulumi.StringArray{
				pulumi.String("10.0.0.0/16"),
			},
			ResourceGroupName: ri.ResourceGroup.Name,
		})
	if err != nil {
		return err
	}

	sub, err := network.NewSubnet(
		ctx,
		ClusterName+"-subnet",
		&network.SubnetArgs{
			ResourceGroupName:  ri.ResourceGroup.Name,
			VirtualNetworkName: vnet.Name,
			AddressPrefixes: pulumi.StringArray{
				pulumi.String("10.0.1.0/24"),
			},
		})
	if err != nil {
		return err
	}

	ri.Subnet = sub

	return nil
}

func (ri *ResourceInfo) createLB(ctx *pulumi.Context) error {
	lbPub, err := network.NewPublicIp(
		ctx,
		fmt.Sprintf("%s-lb-pub", ClusterName),
		&network.PublicIpArgs{
			ResourceGroupName: ri.ResourceGroup.Name,
			AllocationMethod:  pulumi.String("Static"),
			Sku:               pulumi.StringPtr("Standard"),
		},
	)
	if err != nil {
		return err
	}

	ri.LBPubIP = lbPub

	loadBal, err := lb.NewLoadBalancer(
		ctx,
		ClusterName+"-lb",
		&lb.LoadBalancerArgs{
			ResourceGroupName: ri.ResourceGroup.Name,
			Sku:               pulumi.StringPtr("Standard"),
			FrontendIpConfigurations: lb.LoadBalancerFrontendIpConfigurationArray{
				&lb.LoadBalancerFrontendIpConfigurationArgs{
					Name:              pulumi.String(ClusterName + "-frontend"),
					PublicIpAddressId: lbPub.ID(),
				},
			},
		},
	)
	if err != nil {
		return err
	}

	backendPool, err := lb.NewBackendAddressPool(
		ctx,
		ClusterName+"-backend",
		&lb.BackendAddressPoolArgs{
			LoadbalancerId: loadBal.ID(),
		},
	)
	if err != nil {
		return err
	}

	ri.LBBackendPool = backendPool

	_, err = lb.NewRule(
		ctx,
		ClusterName+"-lb-rule",
		&lb.RuleArgs{
			BackendAddressPoolIds:       pulumi.StringArray{backendPool.ID()},
			LoadbalancerId:              loadBal.ID(),
			Protocol:                    pulumi.String("Tcp"),
			FrontendPort:                pulumi.Int(6443),
			BackendPort:                 pulumi.Int(6443),
			FrontendIpConfigurationName: pulumi.String(ClusterName + "-frontend"),
		},
	)
	if err != nil {
		return err
	}

	return nil
}

func (ri *ResourceInfo) createCPNics(ctx *pulumi.Context) error {
	for i := 0; i < ControlPlaneNodesCount; i++ {
		pub, err := network.NewPublicIp(
			ctx,
			fmt.Sprintf("%s-cp-pub-%d", ClusterName, i),
			&network.PublicIpArgs{
				ResourceGroupName: ri.ResourceGroup.Name,
				AllocationMethod:  pulumi.String("Static"),
				Sku:               pulumi.StringPtr("Standard"),
			},
		)
		if err != nil {
			return err
		}

		ri.CPPubIPs = append(ri.CPPubIPs, pub.IpAddress)

		nic, err := network.NewNetworkInterface(
			ctx,
			fmt.Sprintf("%s-cp-nic-%d", ClusterName, i),
			&network.NetworkInterfaceArgs{
				ResourceGroupName: ri.ResourceGroup.Name,
				IpConfigurations: network.NetworkInterfaceIpConfigurationArray{
					&network.NetworkInterfaceIpConfigurationArgs{
						Name:                       pulumi.String(ClusterName + "-ipconfig"),
						SubnetId:                   ri.Subnet.ID(),
						PrivateIpAddressAllocation: pulumi.String("Dynamic"),
						PublicIpAddressId:          pub.ID(),
					},
				},
			})
		if err != nil {
			return err
		}

		_, err = network.NewNetworkInterfaceSecurityGroupAssociation(
			ctx,
			fmt.Sprintf("%s-cp-sg-assoc-%d", ClusterName, i),
			&network.NetworkInterfaceSecurityGroupAssociationArgs{
				NetworkInterfaceId:     nic.ID(),
				NetworkSecurityGroupId: ri.CPSecurityGroup.ID(),
			},
		)
		if err != nil {
			return err
		}

		_, err = network.NewNetworkInterfaceBackendAddressPoolAssociation(
			ctx,
			fmt.Sprintf("%s-cp-backend-assoc-%d", ClusterName, i),
			&network.NetworkInterfaceBackendAddressPoolAssociationArgs{
				BackendAddressPoolId: ri.LBBackendPool.ID(),
				IpConfigurationName:  pulumi.String(ClusterName + "-ipconfig"),
				NetworkInterfaceId:   nic.ID(),
			},
		)
		if err != nil {
			return err
		}

		ri.CPNics[fmt.Sprintf("%s-cp-nic-%d", ClusterName, i)] = nic
	}

	return nil
}

func (ri *ResourceInfo) createWorkerNics(ctx *pulumi.Context) error {
	for i := 0; i < WorkerNodesCount; i++ {
		nic, err := network.NewNetworkInterface(
			ctx,
			fmt.Sprintf("%s-worker-nic-%d", ClusterName, i),
			&network.NetworkInterfaceArgs{
				ResourceGroupName: ri.ResourceGroup.Name,
				IpConfigurations: network.NetworkInterfaceIpConfigurationArray{
					&network.NetworkInterfaceIpConfigurationArgs{
						Name:                       pulumi.String(ClusterName + "-ipconfig"),
						SubnetId:                   ri.Subnet.ID(),
						PrivateIpAddressAllocation: pulumi.String("Dynamic"),
					},
				},
			})
		if err != nil {
			return err
		}

		_, err = network.NewNetworkInterfaceSecurityGroupAssociation(
			ctx,
			fmt.Sprintf("%s-worker-sg-assoc-%d", ClusterName, i),
			&network.NetworkInterfaceSecurityGroupAssociationArgs{
				NetworkInterfaceId:     nic.ID(),
				NetworkSecurityGroupId: ri.WorkerSecurityGroup.ID(),
			},
		)
		if err != nil {
			return err
		}

		ri.WorkerNics[fmt.Sprintf("%s-worker-nic-%d", ClusterName, i)] = nic

	}

	return nil
}
