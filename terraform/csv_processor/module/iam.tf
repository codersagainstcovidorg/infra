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
        "s3:HeadObject"
      ],
      "Resource": "${aws_s3_bucket.processing.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}
