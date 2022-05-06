// compute.go holds functions specific to Azure storage resources
package main

import (
	"github.com/pulumi/pulumi-azure/sdk/v5/go/azure/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createStorage(ctx *pulumi.Context) error {
	account, err := storage.NewAccount(
		ctx,
		ClusterName+"storage",
		&storage.AccountArgs{
			ResourceGroupName:      ri.ResourceGroup.Name,
			Location:               pulumi.String(ri.Location),
			AccountTier:            pulumi.String("Standard"),
			AccountReplicationType: pulumi.String("LRS"),
		},
	)
	if err != nil {
		return err
	}

	ri.StorageAcct = account

	container, err := storage.NewContainer(
		ctx,
		ClusterName+"-blobcontainer",
		&storage.ContainerArgs{
			StorageAccountName: ri.StorageAcct.Name,
		},
	)
	if err != nil {
		return err
	}

	ri.StorageContainer = container

	return nil
}
