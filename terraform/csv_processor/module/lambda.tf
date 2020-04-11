# Trigger lambda for csv files in unprocessed/
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.processing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "unprocessed/"
    filter_suffix       = ".csv"
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

# repackage if sha changes 
resource "null_resource" "lambda" {
  triggers = {
    zip_sha = data.archive_file.lambda.output_base64sha256
  }

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    command = "pip3 install -r ${path.module}/lambda/requirements.txt -t ${path.module}/lambda/"
  }
}

resource "aws_lambda_function" "func" {
  depends_on = [null_resource.lambda]
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.environment}-csv-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "csv_processor.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime       = "python3.8"
  timeout       = 60
}