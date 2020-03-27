resource "aws_ecr_repository" "backend" {
  name = "${var.environment}-covid-backend"
}

resource "aws_ecr_lifecycle_policy" "backendpolicy" {
  repository = aws_ecr_repository.backend.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire old images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}