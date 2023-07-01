terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

  #Terraform cloud set-up
  cloud {
    organization = "cloud-translator-unipv"
    workspaces {
      name = "cloud-translator-local-workspace"
    }
  }
}

# Configure the AWS Provider
variable "AWS_ACCESS_KEY_ID" {
  type = string
  description = "access key id"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
  description = "secret access key"
}
provider "aws" {
  region     = "us-west-1"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

output "region" {
  value       = "us-west-1"
  description = "Description of region"
}


resource "aws_iam_role" "lambda_role" {
  name   = "lambda_function_Role"
  assume_role_policy = templatefile("./templates/lambda_role.json", {})
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "insert-bad-translation-archive" {
  type        = "zip"
  source_file  = "${path.module}/src/insert-bad-translation.py"
  output_path = "./zip/insert-bad-translation.zip"
}

# insert-bad-translation
resource "aws_lambda_function" "insert-bad-translation" {
  filename                       = "zip/insert-bad-translation.zip"
  function_name                  = "insert-bad-translation"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "insert-bad-translation.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  layers                         = [aws_lambda_layer_version.my_layer.arn]
}

# insert-possible-better-translation
data "archive_file" "insert-possible-better-translation-archive" {
  type        = "zip"
  source_file  = "${path.module}/src/insert-possible-better-translation.py"
  output_path = "./zip/insert-possible-better-translation.zip"
}

resource "aws_lambda_function" "insert-possible-better-translation" {
  filename                       = "zip/insert-possible-better-translation.zip"
  function_name                  = "insert-possible-better-translation"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "insert-possible-better-translation.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  layers                         = [aws_lambda_layer_version.my_layer.arn]
}

# read-bad-translations
data "archive_file" "read-bad-translations-archive" {
  type        = "zip"
  source_file  = "${path.module}/src/read-bad-translations.py"
  output_path = "./zip/read-bad-translations.zip"
}

resource "aws_lambda_function" "read-bad-translations" {
  filename                       = "zip/read-bad-translations.zip"
  function_name                  = "read-bad-translations"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "read-bad-translations.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  layers                         = [aws_lambda_layer_version.my_layer.arn]
}

# read-possible-better-translation-by-id
data "archive_file" "read-possible-better-translation-by-id-archive" {
  type        = "zip"
  source_file  = "${path.module}/src/read-possible-better-translation-by-id.py"
  output_path = "./zip/read-possible-better-translation-by-id.zip"
}

resource "aws_lambda_function" "read-possible-better-translation-by-id" {
  filename                       = "zip/read-possible-better-translation-by-id.zip"
  function_name                  = "read-possible-better-translation-by-id"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "read-possible-better-translation-by-id.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  layers                         = [aws_lambda_layer_version.my_layer.arn]
}

# vote-possible-better-translation
data "archive_file" "vote-possible-better-translation-archive" {
  type        = "zip"
  source_file  = "${path.module}/src/vote-possible-better-translation.py"
  output_path = "./zip/vote-possible-better-translation.zip"
}

resource "aws_lambda_function" "vote-possible-better-translation" {
  filename                       = "zip/vote-possible-better-translation.zip"
  function_name                  = "vote-possible-better-translation"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "vote-possible-better-translation.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  layers                         = [aws_lambda_layer_version.my_layer.arn]
}



resource "aws_lambda_layer_version" "my_layer" {
  filename   = "neo4j.zip"
  layer_name = "my_layer"
  source_code_hash = filebase64sha256("neo4j.zip")
  compatible_runtimes = ["python3.10"]
}



#---------------------------------------------------------------


