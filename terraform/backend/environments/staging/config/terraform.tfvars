environment = "staging"
region = "us-east-1"

processing_bucket_name = "csv-processor-staging-9129jf"

# ALB Settings
certificate_arn = "arn:aws:acm:us-east-1:656509764755:certificate/d30fb6fc-4497-436b-a7ca-6dc9d75ac4f3"
lb_health_check_path = "/api/v1/health"

container_name = "backend"
image_tag      = "latest"
network_mode   = "awsvpc"

# Make sure these adhere to fargate requirements
container_memory = 512
container_cpu    = 256

essential                    = true
readonly_root_filesystem     = false

container_environment = [
  {
    name  = "ENVIRONMENT"
    value = "staging"
  }
]

port_mappings = [
  {
    containerPort = 80
    protocol      = "tcp"
  }
]
