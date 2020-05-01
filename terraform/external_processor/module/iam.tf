resource "aws_iam_role" "lambda" {
  name = "${var.environment}-lambda-processor"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.environment}-lambda-processor"
  description = "Lambda priv"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": [
          "${aws_cloudwatch_log_group.processing.arn}:log-stream:*",
          "${aws_cloudwatch_log_group.processing.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:HeadObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.processing.arn}",
        "${aws_s3_bucket.processing.arn}/*"
        ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/*",
        "${data.aws_kms_key.environment.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}
