locals {
  bin_dir = module.setup_clis.bin_dir
  tmp_dir = "${path.cwd}/.tmp"
  ingress_subdomain = var.cluster_ingress_hostname
  mas_namespace = var.mas_namespace
  instanceid=var.mas_instanceid

}


module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["helm"]
}

##
# Setup Preq's before MAS core
##

# Service Binding Operator

resource "null_resource" "patchSBO" {
  
  triggers = {
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/patchSBO.sh"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/patchSBO.sh destroy"
   
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

# Create/Recreate the ibm-entitlement secret

resource "null_resource" "entitlesecret" {
  depends_on = [
    null_resource.patchSBO
  ]

  triggers = {
    mas_namespace=var.mas_namespace
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "kubectl create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username='cp' --docker-password=${var.mas_key} -n ${self.triggers.mas_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete secret ibm-entitlement -n ${self.triggers.mas_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

# Update CRDs needed

resource "null_resource" "updateCRD" {

  triggers = {
    ingress=local.ingress_subdomain
    instanceid=local.instanceid

    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/updateCRD.sh ${self.triggers.instanceid} ${self.triggers.ingress}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

# deploy truststore manager
resource "null_resource" "deployTM" {
  depends_on = [
    null_resource.updateCRD
  ]

  triggers = {
    mas_namespace=local.mas_namespace
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployTM.sh ${self.triggers.mas_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

    provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/deployTM.sh ${self.triggers.mas_namespace} destroy"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

# deploy needed catalogs for operators
resource "null_resource" "deployCatalogs" {
  depends_on = [
    null_resource.deployTM
  ]

  triggers = {
    mas_namespace=local.mas_namespace
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/charts/ibm-catalogs.yaml"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

    provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -f ${path.module}/charts/ibm-catalogs.yaml"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

# Install IBM Maximo Application Suite operator

resource "null_resource" "deployMASop" {
  depends_on = [
    null_resource.deployCatalogs
  ]

  triggers = {
    instanceid=local.instanceid
    masversion=var.mas_version
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployMASop.sh ${self.triggers.instanceid} ${self.triggers.masversion}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

    provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/deployMASop.sh ${self.triggers.instanceid} ${self.triggers.masversion} destroy"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}

/*
# Install IBM Maximo Application Suite core systems

resource "null_resource" "deployMAScore" {
  depends_on = [
    null_resource.deployMASop
  ]

  triggers = {
    mas_namespace=local.mas_namespace
    instanceid=local.instanceid
    ingress=local.ingress_subdomain

    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deployMAScore.sh ${self.triggers.mas_namespace} ${self.triggers.instanceid} ${self.triggers.ingress}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

    provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/deployMAScore.sh ${self.triggers.mas_namespace} ${self.triggers.instanceid} ${self.triggers.ingress} destroy"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

}
*/

