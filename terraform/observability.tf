################################################################################
# Prometheus + Grafana (kube-prometheus-stack)
################################################################################

resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_prometheus ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "~> 56.0"

  create_namespace = true
  timeout          = 600

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"  # Réduit de 50Gi à 20Gi
                  }
                }
                storageClassName = "gp3"
              }
            }
          }
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "1"
              memory = "4Gi"
            }
          }
        }
      }
      grafana = {
        enabled = true
        adminPassword = var.grafana_admin_password
        service = {
          type = "ClusterIP"  # Économie: pas de NLB (accès via port-forward)
        }
        persistence = {
          enabled = true
          size = "10Gi"
          storageClassName = "gp3"
        }
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [{
              name = "default"
              orgId = 1
              folder = ""
              type = "file"
              disableDeletion = false
              editable = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }]
          }
        }
        dashboards = {
          default = {
            kubernetes-cluster = {
              url = "https://grafana.com/api/dashboards/7249/revisions/1/download"
              datasourceName = "Prometheus"
            }
            kubernetes-pods = {
              url = "https://grafana.com/api/dashboards/6417/revisions/1/download"
              datasourceName = "Prometheus"
            }
          }
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]

  depends_on = [module.eks]
}

################################################################################
# Jaeger (Distributed Tracing)
################################################################################

resource "helm_release" "jaeger" {
  count = var.enable_jaeger ? 1 : 0

  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = "observability"
  version    = "~> 3.0"

  create_namespace = true
  timeout          = 300

  values = [
    yamlencode({
      provisionDataStore = {
        cassandra = false
        elasticsearch = true
      }
      storage = {
        type = "elasticsearch"
        elasticsearch = {
          host = "elasticsearch"
          port = 9200
        }
      }
      allInOne = {
        enabled = false
      }
      collector = {
        enabled = true
        service = {
          type = "ClusterIP"
          otlp = {
            grpc = {
              port = 4317
            }
            http = {
              port = 4318
            }
          }
        }
        resources = {
          limits = {
            cpu = "500m"
            memory = "1Gi"
          }
          requests = {
            cpu = "200m"
            memory = "512Mi"
          }
        }
      }
      query = {
        enabled = true
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        resources = {
          limits = {
            cpu = "500m"
            memory = "1Gi"
          }
          requests = {
            cpu = "100m"
            memory = "256Mi"
          }
        }
      }
      agent = {
        enabled = true
      }
    })
  ]

  depends_on = [
    module.eks,
    helm_release.elasticsearch[0]
  ]
}

################################################################################
# Elasticsearch pour Jaeger
################################################################################

resource "helm_release" "elasticsearch" {
  count = var.enable_jaeger ? 1 : 0

  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  namespace  = "observability"
  version    = "~> 8.5"

  create_namespace = true
  timeout          = 600

  values = [
    yamlencode({
      replicas = 1
      minimumMasterNodes = 1

      resources = {
        requests = {
          cpu    = "500m"
          memory = "2Gi"
        }
        limits = {
          cpu    = "1000m"
          memory = "4Gi"
        }
      }

      volumeClaimTemplate = {
        accessModes = ["ReadWriteOnce"]
        storageClassName = "gp3"
        resources = {
          requests = {
            storage = "30Gi"
          }
        }
      }

      esJavaOpts = "-Xmx2g -Xms2g"
    })
  ]

  depends_on = [module.eks]
}

################################################################################
# Container Insights pour CloudWatch
################################################################################

resource "kubernetes_namespace" "amazon_cloudwatch" {
  count = var.enable_container_insights ? 1 : 0

  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_service_account" "cloudwatch_agent" {
  count = var.enable_container_insights ? 1 : 0

  metadata {
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.cloudwatch_irsa_role[0].iam_role_arn
    }
  }

  depends_on = [kubernetes_namespace.amazon_cloudwatch]
}

# IAM Role for CloudWatch Container Insights
module "cloudwatch_irsa_role" {
  count = var.enable_container_insights ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name}-cloudwatch-agent"

  role_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["amazon-cloudwatch:cloudwatch-agent"]
    }
  }

  tags = local.tags
}
