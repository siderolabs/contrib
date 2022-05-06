// compute.go holds functions specific to Azure compute resources
package main

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/compute"
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createImage(ctx *pulumi.Context) error {
	// TODO: be intelligent about whether we actually dl this
	err := downloadVHD()
	if err != nil {
		return err
	}

	blob, err := storage.NewBlob(
		ctx,
		"talos-"+TalosVersion+".vhd",
		&storage.BlobArgs{
			StorageAccountName:   ri.StorageAcct.Name,
			StorageContainerName: ri.StorageContainer.Name,
			Type:                 pulumi.String("Page"),
			Source:               pulumi.NewFileAsset(LocalVHDName),
			Name:                 pulumi.String("talos-" + TalosVersion + ".vhd"),
		},
	)
	if err != nil {
		return err
	}

	img, err := compute.NewImage(
		ctx,
		"talos-"+TalosVersion,
		&compute.ImageArgs{
			ResourceGroupName: ri.ResourceGroup.Name,
			OsDisk: &compute.ImageOsDiskArgs{
				OsType:  pulumi.String("Linux"),
				OsState: pulumi.String("Generalized"),
				BlobUri: blob.Url,
				SizeGb:  pulumi.Int(10),
			},
			Name: pulumi.String("talos-" + TalosVersion),
		})
	if err != nil {
		return err
	}

	ri.Image = img

	return nil
}

func (ri *ResourceInfo) createCPVMs(ctx *pulumi.Context) error {
	for i := 0; i < ControlPlaneNodesCount; i++ {
		_, err := compute.NewVirtualMachine(
			ctx,
			fmt.Sprintf("%s-cp-%d", ClusterName, i),
			&compute.VirtualMachineArgs{
				NetworkInterfaceIds: pulumi.StringArray{
					ri.CPNics[fmt.Sprintf("%s-cp-nic-%d", ClusterName, i)].ID(),
				},
				ResourceGroupName: ri.ResourceGroup.Name,
				VmSize:            pulumi.String("Standard_DS1_v2"),
				StorageImageReference: &compute.VirtualMachineStorageImageReferenceArgs{
					Id: ri.Image.ID(),
				},
				StorageOsDisk: &compute.VirtualMachineStorageOsDiskArgs{
					Name:            pulumi.String(fmt.Sprintf("%s-cp-disk-%d", ClusterName, i)),
					Caching:         pulumi.String("ReadWrite"),
					CreateOption:    pulumi.String("FromImage"),
					ManagedDiskType: pulumi.String("Standard_LRS"),
				},
				OsProfile: &compute.VirtualMachineOsProfileArgs{
					ComputerName:  pulumi.String(fmt.Sprintf("%s-cp-%d", ClusterName, i)),
					AdminUsername: pulumi.String("testadmin"),
					AdminPassword: pulumi.String("Password1234!"),
					CustomData:    ri.TalosClusterConfig.ControlplaneConfig,
				},
				OsProfileLinuxConfig: &compute.VirtualMachineOsProfileLinuxConfigArgs{
					DisablePasswordAuthentication: pulumi.Bool(false),
				},
			},
		)
		if err != nil {
			return err
		}
	}

	return nil
}

func (ri *ResourceInfo) createWorkerVMs(ctx *pulumi.Context) error {
	for i := 0; i < WorkerNodesCount; i++ {
		_, err := compute.NewVirtualMachine(
			ctx,
			fmt.Sprintf("%s-worker-%d", ClusterName, i),
			&compute.VirtualMachineArgs{
				NetworkInterfaceIds: pulumi.StringArray{
					ri.WorkerNics[fmt.Sprintf("%s-worker-nic-%d", ClusterName, i)].ID(),
				},
				ResourceGroupName: ri.ResourceGroup.Name,
				VmSize:            pulumi.String("Standard_DS1_v2"),
				StorageImageReference: &compute.VirtualMachineStorageImageReferenceArgs{
					Id: ri.Image.ID(),
				},
				StorageOsDisk: &compute.VirtualMachineStorageOsDiskArgs{
					Name:            pulumi.String(fmt.Sprintf("%s-worker-disk-%d", ClusterName, i)),
					Caching:         pulumi.String("ReadWrite"),
					CreateOption:    pulumi.String("FromImage"),
					ManagedDiskType: pulumi.String("Standard_LRS"),
				},
				OsProfile: &compute.VirtualMachineOsProfileArgs{
					ComputerName:  pulumi.String(fmt.Sprintf("%s-worker-%d", ClusterName, i)),
					AdminUsername: pulumi.String("testadmin"),
					AdminPassword: pulumi.String("Password1234!"),
					CustomData:    ri.TalosClusterConfig.WorkerConfig,
				},
				OsProfileLinuxConfig: &compute.VirtualMachineOsProfileLinuxConfigArgs{
					DisablePasswordAuthentication: pulumi.Bool(false),
				},
			},
		)
		if err != nil {
			return err
		}
	}

	return nil
}

func downloadVHD() error {
	// Download VHD tar.gz from our releases
	out, err := os.Create("azure-amd64.tar.gz")
	if err != nil {
		return err
	}

	//TODO: strings.Join() this or something better
	resp, err := http.Get("https://github.com/siderolabs/talos/releases/download/" + TalosVersion + "/azure-amd64.tar.gz")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Write the body to file
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}

	out.Close()

	// Extract file
	file, err := os.Open("azure-amd64.tar.gz")
	if err != nil {
		return err
	}

	defer file.Close()

	var fileReader io.ReadCloser = file

	fileReader, err = gzip.NewReader(file)
	if err != nil {
		return err
	}

	defer fileReader.Close()

	tarBallReader := tar.NewReader(fileReader)

	header, err := tarBallReader.Next()
	if err != nil {
		return err
	}

	writer, err := os.Create(LocalVHDName)
	if err != nil {
		return err
	}

	defer writer.Close()

	io.Copy(writer, tarBallReader)

	err = os.Chmod(LocalVHDName, os.FileMode(header.Mode))
	if err != nil {
		return err
	}

	return nil
}
