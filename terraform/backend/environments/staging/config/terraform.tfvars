environment = "staging"
region = "us-east-1"

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
  # {
  #   name  = "ENVIRONMENT"
  #   value = "I am a string"
  # },
  # {
  #   name  = "true_boolean_var"
  #   value = true
  # },
  # {
  #   name  = "false_boolean_var"
  #   value = false
  # },
  # {
  #   name  = "integer_var"
  #   value = 42
  # }
]

port_mappings = [
  {
    containerPort = 80
    #hostPort      = 0 # leave unset for awsvpc
    protocol      = "tcp"
  }
]
