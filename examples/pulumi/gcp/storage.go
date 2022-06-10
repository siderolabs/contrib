// compute.go holds functions specific to GCP storage resources
package main

import (
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func (ri *ResourceInfo) createStorage(ctx *pulumi.Context) error {
	bucketLoc := ri.PulumiConfig.Get("bucket-location")
	if bucketLoc == "" {
		bucketLoc = "US"
	}

	ri.BucketLocation = bucketLoc

	bucket, err := storage.NewBucket(
		ctx,
		ClusterName+"-bucket",
		&storage.BucketArgs{
			Location: pulumi.String(ri.BucketLocation),
		})
	if err != nil {
		return err
	}

	ri.Bucket = bucket

	return nil
}
