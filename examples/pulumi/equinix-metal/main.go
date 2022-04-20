package main

import (
	"fmt"
	"net"

	"github.com/frezbo/pulumi-provider-talos/sdk/go/talos"

	metal "github.com/pulumi/pulumi-equinix-metal/sdk/v3/go/equinix"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
)

const (
	ControlPlaneNodesCount = 3
	IngressNodesCount      = 2
	WorkerNodesAMD64Count  = 4
	WorkerNodesARM64Count  = 2

	ClusterName = "talos"

	MetalMetro          = "DC"
	MetalUserDataPrefix = "#!talos\n"

	// replace below with an iPXE server url for amd64 and arm64
	IpxeURLAMD64   = ""
	IpxeURLARM64   = ""
	InstallerImage = "ghcr.io/talos-systems/installer:v1.0.3"

	ControlPlaneNodePlan = metal.PlanC3SmallX86
	IngressNodePlan      = metal.PlanC3SmallX86
	WorkerNodeAMD64Plan  = metal.PlanC3MediumX86
	WorkerNodeARM64Plan  = pulumi.String("c3.large.arm")
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		stackName := ctx.Stack()
		project := ctx.Project()
		commonTags := pulumi.StringArray{
			pulumi.String(stackName),
			pulumi.String(project),
		}

		conf := config.New(ctx, "")
		projectID := conf.Require("projectID")
		secretConf := config.New(ctx, "equinix-metal")
		apiToken := secretConf.RequireSecret("authToken")

		// sets up a VIP for the control plane nodes
		controlPlaneVIP, err := metal.NewReservedIpBlock(ctx, "controlPlaneVIP", &metal.ReservedIpBlockArgs{
			Description: pulumi.Sprintf("%s Control Plane VIP", stackName),
			Metro:       pulumi.String(MetalMetro),
			ProjectId:   pulumi.String(projectID),
			Quantity:    pulumi.Int(1),
			Type:        metal.IpBlockTypePublicIPv4,
			Tags:        commonTags,
		})
		if err != nil {
			return err
		}

		// sets up a reserved IP block for ingress nodes
		ingressReserveredIPs, err := metal.NewReservedIpBlock(ctx, "ingressIPs", &metal.ReservedIpBlockArgs{
			Description: pulumi.Sprintf("%s Ingress IPs", stackName),
			Metro:       pulumi.String(MetalMetro),
			ProjectId:   pulumi.String(projectID),
			Quantity:    pulumi.Int(IngressNodesCount),
			Type:        metal.IpBlockTypePublicIPv4,
			Tags:        commonTags,
		})
		if err != nil {
			return err
		}

		// generate Talos cluster secrets
		clusterSecrets, err := talos.NewClusterSecrets(ctx, "clusterSecret", &talos.ClusterSecretsArgs{})
		if err != nil {
			return err
		}

		// generate cluster config, applying the patch for VIP's and loading extra
		// patches from a files
		cc, err := talos.NewClusterConfig(ctx, "clusterConfig", &talos.ClusterConfigArgs{
			ClusterEndpoint: pulumi.Sprintf("https://%s:6443", controlPlaneVIP.Address),
			ClusterName:     pulumi.String(ClusterName),
			Secrets:         clusterSecrets.Secrets,
			// common patches applied across the cluster
			ConfigPatches: talos.ConfigPatchesArgs{
				PatchFiles: pulumi.AssetOrArchiveArray{
					pulumi.NewFileAsset("patches/common.yaml"),
				},
			},
			// patches specific to control plane nodes
			ConfigPatchesControlPlane: talos.ConfigPatchesArgs{
				Patches: pulumi.Array{
					pulumi.Map{
						"op":   pulumi.String("add"),
						"path": pulumi.String("/machine/network/interfaces"),
						"value": pulumi.MapArray{
							pulumi.Map{
								"interface": pulumi.String("bond0"),
								"vip": pulumi.Map{
									"ip": controlPlaneVIP.Address,
									"equinixMetal": pulumi.Map{
										"apiToken": apiToken,
									},
								},
							},
						},
					},
				},
			},
			// patches specific to worker nodes
			ConfigPatchesWorker: talos.ConfigPatchesArgs{
				PatchFiles: pulumi.AssetOrArchiveArray{
					pulumi.NewFileAsset("patches/worker.yaml"),
				},
			},
			InstallImage: pulumi.String(InstallerImage),
		})
		if err != nil {
			return err
		}

		var controlPlaneNodeIPs pulumi.StringArray
		for i := 1; i <= ControlPlaneNodesCount; i++ {
			device, err := metal.NewDevice(ctx, fmt.Sprintf("cp-%d", i), &metal.DeviceArgs{
				Hostname:      pulumi.Sprintf("%s-cp-%d", stackName, i),
				IpxeScriptUrl: pulumi.String(IpxeURLAMD64),
				UserData: cc.ControlplaneConfig.ApplyT(func(mc string) string {
					return MetalUserDataPrefix + mc
				}).(pulumi.StringOutput),
				Metro:           pulumi.String(MetalMetro),
				Plan:            ControlPlaneNodePlan,
				OperatingSystem: metal.OperatingSystemCustomIPXE,
				ProjectId:       pulumi.String(projectID),
				Tags:            commonTags,
			})
			if err != nil {
				return err
			}
			controlPlaneNodeIPs = append(controlPlaneNodeIPs, device.AccessPublicIpv4)
		}

		// generate custom config for arm64 worker nodes
		configARM64, err := talos.NewClusterConfig(ctx, "talosClusterConfigARM64", &talos.ClusterConfigArgs{
			ClusterEndpoint: pulumi.Sprintf("https://%s:6443", controlPlaneVIP.Address),
			ClusterName:     pulumi.String(ClusterName),
			Secrets:         clusterSecrets.Secrets,
			ConfigPatches: talos.ConfigPatchesArgs{
				PatchFiles: pulumi.AssetOrArchiveArray{
					pulumi.NewFileAsset("patches/common.yaml"),
				},
				Patches: pulumi.Array{
					pulumi.Map{
						"op":    pulumi.String("add"),
						"path":  pulumi.String("/machine/install/disk"),
						"value": pulumi.String("/dev/nvme0n1"),
					},
				},
			},
			ConfigPatchesWorker: talos.ConfigPatchesArgs{
				PatchFiles: pulumi.AssetOrArchiveArray{
					pulumi.NewFileAsset("patches/worker.yaml"),
				},
			},
			InstallImage: pulumi.String(InstallerImage),
		})
		if err != nil {
			return err
		}

		var workerNodeIPs pulumi.StringArray
		for i := 1; i <= WorkerNodesAMD64Count; i++ {
			device, err := metal.NewDevice(ctx, fmt.Sprintf("worker-amd64-%d", i), &metal.DeviceArgs{
				Hostname:      pulumi.Sprintf("%s-worker-amd64-%d", stackName, i),
				IpxeScriptUrl: pulumi.String(IpxeURLAMD64),
				UserData: cc.WorkerConfig.ApplyT(func(mc string) string {
					return MetalUserDataPrefix + mc
				}).(pulumi.StringOutput),
				Metro:           pulumi.String(MetalMetro),
				Plan:            WorkerNodeAMD64Plan,
				OperatingSystem: metal.OperatingSystemCustomIPXE,
				ProjectId:       pulumi.String(projectID),
				Tags:            commonTags,
			})
			if err != nil {
				return err
			}
			workerNodeIPs = append(workerNodeIPs, device.AccessPublicIpv4)
		}

		for i := 1; i <= WorkerNodesARM64Count; i++ {
			device, err := metal.NewDevice(ctx, fmt.Sprintf("worker-arm64-%d", i), &metal.DeviceArgs{
				Hostname:      pulumi.Sprintf("%s-worker-arm64-%d", stackName, i),
				IpxeScriptUrl: pulumi.String(IpxeURLARM64),
				UserData: configARM64.WorkerConfig.ApplyT(func(mc string) string {
					return MetalUserDataPrefix + mc
				}).(pulumi.StringOutput),
				Metro:           pulumi.String(MetalMetro),
				Plan:            WorkerNodeARM64Plan,
				OperatingSystem: metal.OperatingSystemCustomIPXE,
				ProjectId:       pulumi.String(projectID),
				Tags:            commonTags,
			})
			if err != nil {
				return err
			}
			workerNodeIPs = append(workerNodeIPs, device.AccessPublicIpv4)
		}

		var ingressNodeIPs pulumi.StringArray
		var ingressEIPs pulumi.StringArray
		// create ingress nodes using the dedicated ingress IP pool
		for i := 0; i < IngressNodesCount; i++ {
			ingressIPs := ingressReserveredIPs.CidrNotation.ApplyT(func(cidr string) ([]string, error) {
				var ips []string

				// from https://groups.google.com/g/golang-nuts/c/zlcYA4qk-94/m/TWRFHeXJCcYJ
				ip, ipnet, err := net.ParseCIDR(cidr)
				if err != nil {
					return ips, err
				}

				inc := func(ip net.IP) {
					for j := len(ip) - 1; j >= 0; j-- {
						ip[j]++
						if ip[j] > 0 {
							break
						}
					}
				}

				for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); inc(ip) {
					ips = append(ips, ip.String())
				}

				return ips, nil
			}).(pulumi.StringArrayOutput)

			// generate talos cluster config for ingress nodes
			ingressConfig, err := talos.NewClusterConfig(ctx, fmt.Sprintf("ingressConfig-%d", i), &talos.ClusterConfigArgs{
				ClusterEndpoint: pulumi.Sprintf("https://%s:6443", controlPlaneVIP.Address),
				ClusterName:     pulumi.String(ClusterName),
				Secrets:         clusterSecrets.Secrets,

				ConfigPatches: talos.ConfigPatchesArgs{
					PatchFiles: pulumi.AssetOrArchiveArray{
						pulumi.NewFileAsset("patches/common.yaml"),
					},
				},
				ConfigPatchesWorker: talos.ConfigPatchesArgs{
					PatchFiles: pulumi.AssetOrArchiveArray{
						pulumi.NewFileAsset("patches/ingress.yaml"),
					},
					// set the machine address from the ingress pool ip
					Patches: pulumi.Array{
						pulumi.Map{
							"op":   pulumi.String("add"),
							"path": pulumi.String("/machine/network/interfaces"),
							"value": pulumi.MapArray{
								pulumi.Map{
									"interface": pulumi.String("bond0"),
									"addresses": pulumi.StringArray{
										ingressIPs.Index(pulumi.Int(i)),
									},
								},
							},
						},
					},
				},
				InstallImage: pulumi.String(InstallerImage),
			})
			if err != nil {
				return err
			}

			device, err := metal.NewDevice(ctx, fmt.Sprintf("ingress-%d", i), &metal.DeviceArgs{
				Hostname:      pulumi.Sprintf("%s-ingress-%d", stackName, i),
				IpxeScriptUrl: pulumi.String(IpxeURLAMD64),
				UserData: ingressConfig.WorkerConfig.ApplyT(func(mc string) string {
					return MetalUserDataPrefix + mc
				}).(pulumi.StringOutput),
				Metro:           pulumi.String(MetalMetro),
				Plan:            IngressNodePlan,
				OperatingSystem: metal.OperatingSystemCustomIPXE,
				ProjectId:       pulumi.String(projectID),
				Tags:            commonTags,
			})
			if err != nil {
				return err
			}
			ingressNodeIPs = append(ingressNodeIPs, device.AccessPublicIpv4)

			// attach the ingress node to the ingress EIP
			_, err = metal.NewIpAttachment(ctx, fmt.Sprintf("ingress-%d-ip-attachment", i), &metal.IpAttachmentArgs{
				DeviceId:     device.ID(),
				CidrNotation: pulumi.Sprintf("%s/32", ingressIPs.Index(pulumi.Int(i))),
			})
			if err != nil {
				return err
			}
			ingressEIPs = append(ingressEIPs, ingressIPs.Index(pulumi.Int(i)))
		}

		// bootstrap the first control plane node
		_, err = talos.NewNodeBootstrap(ctx, "bootstrap-cp-0", &talos.NodeBootstrapArgs{
			Endpoint:    controlPlaneNodeIPs[0],
			Node:        controlPlaneNodeIPs[0],
			TalosConfig: cc.TalosConfig,
		})
		if err != nil {
			return err
		}

		// retrieve the cluster kubeconfig
		kubeconfig := pulumi.All(controlPlaneNodeIPs[0].ToStringOutput(), cc.TalosConfig).ApplyT(func(args []interface{}) (string, error) {
			ip := args[0].(string)
			talosConfig := args[1].(string)

			k, err := talos.GetKubeConfig(ctx, &talos.GetKubeConfigArgs{
				Endpoint:    ip,
				Node:        ip,
				TalosConfig: talosConfig,
			})
			if err != nil {
				return "", err
			}
			return k.Kubeconfig, nil
		}).(pulumi.StringOutput)

		ctx.Export("vip", controlPlaneVIP.Address)
		ctx.Export("controlPlaneNodeIPs", controlPlaneNodeIPs)
		ctx.Export("workerNodeIPs", workerNodeIPs)
		ctx.Export("ingressNodeIPs", ingressNodeIPs)
		ctx.Export("ingressEIPs", ingressEIPs)
		ctx.Export("talosConfig", cc.TalosConfig)
		ctx.Export("controlPlaneConfig", cc.ControlplaneConfig)
		ctx.Export("workerConfigAMD64", cc.WorkerConfig)
		ctx.Export("workerConfigARM64", configARM64.WorkerConfig)
		ctx.Export("kubeconfig", kubeconfig)
		return nil
	})
}
