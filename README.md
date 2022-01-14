#  Maximo Application Suite terraform module

Deploys Maximo Application Suite (MAS) Core.  Instructions here assume a VPC cluster, but this should also work for non-VPC.

## Supported platforms

- OCP 4.6+

## Module dependencies

The module uses the following elements

- CP4D 3.5x db2Warehouse (Current MAS Requirement) is installed on the cluster.  You can currently use the terraform to install this separately.  A module for this is underdevelopment which will replace this separate terraform.

https://github.com/IBM/cp4d-deployment/tree/CPD3.5/managed-openshift/ibmcloud


- Cert-Manager : https://github.com/cloud-native-toolkit/terraform-ocp-certmanager
- MongoDB-CE (required) : https://github.com/cloud-native-toolkit/terraform-ocp-mongodb
- Behavior Analytics Service (BAS) (required) : https://github.com/cloud-native-toolkit/terraform-ibm-ocp-bas
- Suite Analytics Service (SLS) (required) : https://github.com/cloud-native-toolkit/terraform-ibm-ocp-sls

### Terraform providers

- helm - used to configure the scc for OpenShift
- null - used to run the shell scripts

### Environment

- kubectl - used to apply yaml 

## Suggested companion modules

The module itself requires some information from the cluster and needs a
namespace to be created. The following companion
modules can help provide the required information:

- Cluster - https://github.com/ibm-garage-cloud/terraform-cluster-ibmcloud
- Namespace - https://github.com/ibm-garage-cloud/terraform-cluster-namespace

## Suggested instructions to use

Copy the files from the sample directory in this repo to your local file system and edit as appropriate.  Rename the terraform.tfvars.template to terraform.tfvars.

- stages.tf : this will include all the modules that are needed and will be built.  At a minimum you will need information about the cluster (from a cluster module), and any of the above module dependencies that are not already installed on the cluster.  Include all those in the stages.tf

- terraform.tfvars : variables specific to your installation required by the modules you are installing

- terraform.tf : variable definitions for variables declared and used in tfvars.

- for export a variable of your API_KEY

`export APIKEY="<yourapikey>"`

To execute you can use one of the IBM Garage terraform images (v14+ recommended):

`docker run -it -e TF_VAR_ibmcloud_api_key=$APIKEY -e IBMCLOUD_API_KEY=$APIKEY -v ${PWD}:/terraform -w /terraform quay.io/ibmgaragecloud/cli-tools:v14`

Initialize and apply the terraform

`terraform init`

`terraform apply -auto-approve`

When the installation completes (~90mins with existing cluster and CP4D) you will need to setup and configure MAS Core for other MAS application deployments.  

https://admin.${YourDomainURL}/initialsetup

NOTE: Depending on the browser you may have to import the self-signed certificate into your keystore (if on a mac)

Login as super user with credential found in the secret named: yourmasInstanceID-credentials-superuser


## Example module usage

```hcl-terraform
module "mas" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-ocp-mas"

  cluster_config_file      = module.cluster.config_file_path
  cluster_type             = module.cluster.platform.type_code
  cluster_ingress_hostname = module.cluster.platform.ingress
  tls_secret_name          = module.cluster.platform.tls_secret
  
  mas_key       = var.mymas_key
  mas_namespace = module.mas_namespace.name
  
  certmgr_namespace = module.certmgr.cert_namespace
  mongo_namespace   = module.mongo.mongo_namespace
  bas_namespace     = module.masbas.bas_namespace
  sls_namespace     = module.certmgr.cert_namespace
}
```

