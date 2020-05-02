# Trigger lambda for csv files in unprocessed/
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.processing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.processing.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "${path.module}/lambda/"
  output_path = "${path.module}/lambda.zip"
}

# reinstall if sha changes 
resource "null_resource" "lambda" {
  triggers = {
    zip_sha = filebase64sha256("${path.module}/lambda/external_processor.py")
  }

  provisioner "local-exec" {
    # install deps into directory to get zipped
    command = "pip3 install -r ${path.module}/lambda/requirements.txt -t ${path.module}/lambda/"
  }
}

resource "aws_lambda_function" "func" {
  depends_on = [null_resource.lambda]
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.environment}-external-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "external_processor.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/external_processor.py")
  runtime       = "python3.7"
  timeout       = 120

  vpc_config {
    subnet_ids = data.aws_subnet_ids.private_subnets.ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}