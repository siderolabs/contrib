TAG ?= $(shell git describe --tag --always --dirty)

TF_PROJECTS := $(shell find examples/terraform/ -name '.terraform' -prune -o -name 'main.tf' -exec dirname {} \;)

# renovate: datasource=helm depName=aws-cloud-controller-manager
AWS_CCM_HELM_CHART_VERSION ?= 0.0.7
# renovate: datasource=github-releases depName=kubernetes/cloud-provider-aws
AWS_CCM_VERSION ?= v1.27.1

.PHONY: fmt
fmt:
	terraform fmt -recursive

.PHONY: generate
generate: aws-ccm tfdocs

tfdocs:
	$(foreach project,$(TF_PROJECTS),terraform-docs markdown --output-file README.md --output-mode inject $(project);)

upgrade-providers:
	$(foreach project,$(TF_PROJECTS),terraform -chdir=$(project) init -upgrade;)


.PHONY: check-dirty
check-dirty: fmt generate ## Verifies that source tree is not dirty
	@if test -n "`git status --porcelain`"; then echo "Source tree is dirty"; git status; exit 1 ; fi

aws-ccm:
	helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
	helm repo update
	helm template --version $(AWS_CCM_HELM_CHART_VERSION) aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager --set args="{--v=2,--cloud-provider=aws,--configure-cloud-routes=false}" --set image.tag=$(AWS_CCM_VERSION) > examples/terraform/aws/manifests/ccm.yaml
