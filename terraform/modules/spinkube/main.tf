provider "kubernetes" {
  config_path = var.config_path
}

provider "helm" {
  kubernetes {
    config_path = var.config_path
  }
}

resource "kubernetes_manifest" "crd1" {
  manifest = yamldecode(file("manifests/spin-operator.crds.1.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "crd2" {
  manifest = yamldecode(file("manifests/spin-operator.crds.2.yaml"))
}

resource "kubernetes_manifest" "runtimeclass" {
  manifest = yamldecode(file("manifests/spin-operator.runtime-class.yaml"))
}

resource "kubernetes_manifest" "executor" {
  manifest = yamldecode(file("manifests/spin-operator.shim-executor.yaml"))
  depends_on = [
    kubernetes_manifest.crd1
  ]
}

resource "kubernetes_manifest" "certmanager1" {
  manifest = yamldecode(file("manifests/cert-manager.1.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "certmanager2" {
  manifest = yamldecode(file("manifests/cert-manager.2.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "certmanager3" {
  manifest = yamldecode(file("manifests/cert-manager.3.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "certmanager4" {
  manifest = yamldecode(file("manifests/cert-manager.4.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "certmanager5" {
  manifest = yamldecode(file("manifests/cert-manager.5.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "kubernetes_manifest" "certmanager6" {
  manifest = yamldecode(file("manifests/cert-manager.6.crds.yaml"))

  wait {
    rollout = true
  }
}

resource "helm_release" "certmanager" {
  name       = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  version    = "v1.14.3"
  namespace  = "cert-manager"
  create_namespace = true

  depends_on = [
    kubernetes_manifest.certmanager1,
    kubernetes_manifest.certmanager2,
    kubernetes_manifest.certmanager3,
    kubernetes_manifest.certmanager4,
    kubernetes_manifest.certmanager5,
    kubernetes_manifest.certmanager6,
  ]
}

resource "helm_release" "kwasm" {
  name       = "kwasm-operator"

  repository = "http://kwasm.sh/kwasm-operator/"
  chart      = "kwasm-operator"

  namespace  = "kwasm"
  create_namespace = true

  set {
    name  = "kwasmOperator.installerImage"
    value = "ghcr.io/spinkube/containerd-shim-spin/node-installer:v0.13.1"
  }

  depends_on = [
    kubernetes_manifest.runtimeclass,
    kubernetes_manifest.executor
  ]
}

resource "kubernetes_annotations" "wasm" {
  api_version = "v1"
  kind        = "node"

  metadata {
    name = "*"
  }
  
  annotations = {
    "kwasm.sh/kwasm-node" = "true"
  }

  depends_on = [
    helm_release.kwasm
  ]
}

resource "helm_release" "spinoperator" {
  name       = "spin-operator"

  chart      = "oci://ghcr.io/spinkube/charts/spin-operator"

  version = "0.1.0"
  namespace  = "spin-operator"
  create_namespace = true

  depends_on = [
    helm_release.certmanager,
    helm_release.kwasm,
    kubernetes_manifest.crd1,
    kubernetes_manifest.crd2,
  ]
}