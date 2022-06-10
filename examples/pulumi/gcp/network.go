package main

import (
	"fmt"

	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/compute"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createNetworks(ctx *pulumi.Context) error {
	net, err := compute.NewNetwork(
		ctx,
		ClusterName+"-net",
		&compute.NetworkArgs{
			Name: pulumi.String(ClusterName + "-net"),
		},
	)
	if err != nil {
		return err
	}

	ri.Network = net

	return nil

}

func (ri *ResourceInfo) createCPAddresses(ctx *pulumi.Context) error {
	for i := 0; i < ControlPlaneNodesCount; i++ {
		addr, err := compute.NewAddress(
			ctx,
			fmt.Sprintf("%s-cp-%d", ClusterName, i),
			&compute.AddressArgs{
				Name:   pulumi.String(fmt.Sprintf("%s-cp-%d", ClusterName, i)),
				Region: pulumi.String(ri.Region),
			},
		)
		if err != nil {
			return err
		}

		ri.CPAddresses[fmt.Sprintf("%s-cp-%d", ClusterName, i)] = addr
	}

	return nil
}

func (ri *ResourceInfo) createWorkerAddresses(ctx *pulumi.Context) error {
	for i := 0; i < WorkerNodesCount; i++ {
		addr, err := compute.NewAddress(
			ctx,
			fmt.Sprintf("%s-worker-%d", ClusterName, i),
			&compute.AddressArgs{
				Name:   pulumi.String(fmt.Sprintf("%s-worker-%d", ClusterName, i)),
				Region: pulumi.String(ri.Region),
			},
		)
		if err != nil {
			return err
		}

		ri.WorkerAddresses[fmt.Sprintf("%s-worker-%d", ClusterName, i)] = addr
	}

	return nil
}

func (ri *ResourceInfo) createLBAddress(ctx *pulumi.Context) error {
	addr, err := compute.NewGlobalAddress(
		ctx,
		ClusterName+"-lb",
		&compute.GlobalAddressArgs{
			Name: pulumi.String(ClusterName + "-lb"),
		},
	)
	if err != nil {
		return err
	}

	ri.LBAddress = addr

	return nil
}

func (ri *ResourceInfo) createFirewalls(ctx *pulumi.Context) error {
	_, err := compute.NewFirewall(
		ctx,
		ClusterName+"-cp-health",
		&compute.FirewallArgs{
			Network: ri.Network.SelfLink,
			Allows: &compute.FirewallAllowArray{
				&compute.FirewallAllowArgs{
					Protocol: pulumi.String("tcp"),
					Ports: pulumi.StringArray{
						pulumi.String("6443"),
					},
				},
			},
			SourceRanges: pulumi.ToStringArray([]string{"35.191.0.0/16", "130.211.0.0/22"}),
			TargetTags: pulumi.StringArray{
				pulumi.String(ClusterName + "-cp"),
			},
		},
	)
	if err != nil {
		return err
	}

	_, err = compute.NewFirewall(
		ctx,
		ClusterName+"-cp-talosapi",
		&compute.FirewallArgs{
			Network: ri.Network.SelfLink,
			Allows: &compute.FirewallAllowArray{
				&compute.FirewallAllowArgs{
					Protocol: pulumi.String("tcp"),
					Ports: pulumi.StringArray{
						pulumi.String("50000"),
					},
				},
			},
			SourceRanges: pulumi.ToStringArray([]string{"0.0.0.0/0"}),
			TargetTags: pulumi.StringArray{
				pulumi.String(ClusterName + "-cp"),
			},
		},
	)
	if err != nil {
		return err
	}

	_, err = compute.NewFirewall(
		ctx,
		ClusterName+"-all-intracluster",
		&compute.FirewallArgs{
			Network: ri.Network.SelfLink,
			Allows: &compute.FirewallAllowArray{
				&compute.FirewallAllowArgs{
					Protocol: pulumi.String("all"),
				},
			},
			SourceTags: pulumi.StringArray{
				pulumi.String(ClusterName + "-cp"),
				pulumi.String(ClusterName + "-worker"),
			},
			TargetTags: pulumi.StringArray{
				pulumi.String(ClusterName + "-cp"),
				pulumi.String(ClusterName + "-worker"),
			},
		},
	)
	if err != nil {
		return err
	}

	return nil
}

func (ri *ResourceInfo) createLB(ctx *pulumi.Context) error {
	// Create instance group
	instanceList := pulumi.StringArray{}

	for _, instance := range ri.CPInstances {
		instanceList = append(instanceList, instance.ID())
	}

	ig, err := compute.NewInstanceGroup(
		ctx,
		ClusterName+"-cp-ig",
		&compute.InstanceGroupArgs{
			Instances: instanceList,
			Name:      pulumi.String(ClusterName + "-cp-ig"),
			NamedPorts: compute.InstanceGroupNamedPortTypeArray{
				&compute.InstanceGroupNamedPortTypeArgs{
					Name: pulumi.String(ClusterName + "-k8s-api"),
					Port: pulumi.Int(6443),
				},
			},
			Zone: pulumi.String(ri.Zone),
		},
	)
	if err != nil {
		return err
	}

	hc, err := compute.NewHealthCheck(
		ctx,
		ClusterName+"-k8s-hc",
		&compute.HealthCheckArgs{
			Name: pulumi.String(ClusterName + "-k8s-hc"),
			SslHealthCheck: &compute.HealthCheckSslHealthCheckArgs{
				Port:              pulumi.Int(6443),
				PortSpecification: pulumi.String("USE_FIXED_PORT"),
			},
		},
	)
	if err != nil {
		return err
	}

	backend, err := compute.NewBackendService(
		ctx,
		ClusterName+"-k8s-lb",
		&compute.BackendServiceArgs{
			Backends: compute.BackendServiceBackendArray{
				&compute.BackendServiceBackendArgs{
					Group: ig.SelfLink,
				},
			},
			HealthChecks:        hc.ID(),
			LoadBalancingScheme: pulumi.String("EXTERNAL"),
			Name:                pulumi.String(ClusterName + "-k8s-lb"),
			Protocol:            pulumi.String("TCP"),
			PortName:            pulumi.String(ClusterName + "-k8s-api"),
		},
	)
	if err != nil {
		return err
	}

	tcpProxy, err := compute.NewTargetTCPProxy(
		ctx,
		ClusterName+"-k8s-tcpproxy",
		&compute.TargetTCPProxyArgs{
			BackendService: backend.ID(),
		},
	)
	if err != nil {
		return err
	}

	_, err = compute.NewGlobalForwardingRule(
		ctx,
		ClusterName+"-k8s-forwarding",
		&compute.GlobalForwardingRuleArgs{
			IpAddress:  ri.LBAddress.Address,
			IpProtocol: pulumi.String("TCP"),
			Name:       pulumi.String(ClusterName + "-k8s-forwarding"),
			PortRange:  pulumi.String("6443"),
			Target:     tcpProxy.ID(),
		},
	)
	if err != nil {
		return err
	}

	return nil
}
