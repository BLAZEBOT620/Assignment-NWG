# Provider configuration for AWS
provider "aws" {
  region = var.region
}

# EC2 instance creation
resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "TerraformExampleInstance"
  }
}

# S3 bucket for static website
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "TerraformExampleS3Bucket"
  }
}

# S3 static website configuration
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}

# Upload hospital HTML file as index.html
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "index.html"
  source       = "${path.module}/hospital-html.html"
  content_type = "text/html"
}

# IAM role for Lambda function to allow it to read from S3 and write to CloudWatch
resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Declare aws_caller_identity to get the current account id
data "aws_caller_identity" "current" {}

# IAM policy to allow Lambda function to access S3 and CloudWatch logs
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda function to access S3 and CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.website_bucket.bucket}/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Attach the IAM policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function that is triggered by S3 event
resource "aws_lambda_function" "s3_event_lambda" {
  filename         = "C:/Users/adity/Downloads/lambda_function.zip"  # Path to your Lambda ZIP file
  function_name    = "S3EventTriggerLambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function2.lambda_handler"  # Lambda function name is lambda_function2.py
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("C:/Users/adity/Downloads/lambda_function.zip")  # Base64 hash of your ZIP file
}

# S3 event notification that triggers the Lambda function on object creation
resource "aws_s3_bucket_notification" "s3_lambda_event_trigger" {
  bucket = aws_s3_bucket.website_bucket.bucket

  lambda_function {
    events = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.s3_event_lambda.arn
  }

  depends_on = [aws_lambda_function.s3_event_lambda]  # Ensure Lambda is created before notification
}

# Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = aws_lambda_function.s3_event_lambda.function_name
  statement_id  = "AllowS3Invoke"
  source_arn    = aws_s3_bucket.website_bucket.arn
}

# Outputs to show the resources created
output "s3_bucket_name" {
  value = aws_s3_bucket.website_bucket.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_event_lambda.function_name
}

output "ec2_instance_id" {
  value = aws_instance.example.id
}
