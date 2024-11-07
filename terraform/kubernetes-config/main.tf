
# kubernetes components
data "terraform_remote_state" "eks-cluster" {
  backend = "s3"

  config = {
    bucket = "tf-state-bucket-technical-challenge-interview"
    key    = "terraform/k8s-terraform.tfstate"
    region = "us-east-2"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks-cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks-cluster.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks-cluster.outputs.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks-cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks-cluster.outputs.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks-cluster.outputs.cluster_name]
    command     = "aws"
  }
}

# Deploy external DNS


resource "kubernetes_manifest" "cloudflare-secret" {

  manifest = yamldecode(<<-EOF
    apiVersion: v1
    data:
      CF_API_EMAIL: "${var.CF_API_EMAIL}"
      CF_API_TOKEN: "${var.CF_API_TOKEN}"
    kind: Secret
    metadata:
      name: external-cloudflare
      namespace: kube-system
    type: Opaque
    EOF
  )
}

resource "helm_release" "external-dns" {
  depends_on = [
    kubernetes_manifest.cloudflare-secret
  ]

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  values = [
    file("${path.module}/helm-values/external-dns-values.yaml")
  ]
}

resource "helm_release" "ingress-nginx" {

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"

  values = [
    file("${path.module}/helm-values/ingress-nginx-values.yaml")
  ]
}

# Deploy Cert-manager with tls

resource "helm_release" "cert-manager" {


  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "kube-system"
  timeout    = 600
  wait       = true

  values = [
    file("${path.module}/helm-values/cert-manager-values.yaml")
  ]
}


# workaround for terraform dependency bug

# │ Error: API did not recognize GroupVersionKind from manifest (CRD may not be installed)
# │ 
# │   with kubernetes_manifest.cluster-issuer,
# │   on main.tf line 99, in resource "kubernetes_manifest" "cluster-issuer":
# │   99: resource "kubernetes_manifest" "cluster-issuer" {
# │ 
# │ no matches for kind "ClusterIssuer" in group "cert-manager.io"


resource "helm_release" "cluster-issuer" {
  depends_on = [
    helm_release.cert-manager
  ]
  name       = "cluster-issuer"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  values = [
    <<-EOF
      resources:
        - apiVersion: cert-manager.io/v1
          kind: ClusterIssuer
          metadata:
            name: letsencrypt-prod
          spec:
            acme:
              email: "${base64decode(var.CF_API_EMAIL)}"
              privateKeySecretRef:
                name: letsencrypt-prod
              server: https://acme-v02.api.letsencrypt.org/directory
              solvers:
              - dns01:
                  cloudflare:
                    apiTokenSecretRef:
                      key: CF_API_TOKEN
                      name: external-cloudflare
                    email: "${base64decode(var.CF_API_EMAIL)}"
      EOF
  ]
}

# deploy zot
# TODO ADD AUTHENTICATION to zot
resource "helm_release" "zot" {

  name       = "zot"
  repository = "http://zotregistry.dev/helm-charts"
  chart      = "zot"
  namespace  = "kube-system"


  values = [
    file("${path.module}/helm-values/zot-values.yaml")
  ]
}

# deploy postgres operator

resource "helm_release" "postgres-operator" {

  name             = "postgres-operator"
  repository       = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart            = "postgres-operator"
  namespace        = "postgres-operator"
  create_namespace = true


  values = [
    file("${path.module}/helm-values/postgres-operator-values.yaml")
  ]
}

#Optional not required but helpful for generating Postgres CRs
# https://github.com/zalando/postgres-operator/blob/master/docs/operator-ui.md

resource "helm_release" "postgres-operator-ui" {

  name             = "postgres-operator-ui"
  repository       = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
  chart            = "postgres-operator-ui"
  namespace        = "postgres-operator"
  create_namespace = true


  values = [
    file("${path.module}/helm-values/postgres-operator-ui-values.yaml")
  ]
}
