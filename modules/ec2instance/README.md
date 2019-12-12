# Glovo IaC Project Terraform Lambda Module

This module allows small/simple AWS Lambda function provisioning. This kind of function is usually part of operational
automation processes. It is not meant to substitute frameworks like the [Serverless Framework](https://serverless.com/)
or the [Serverless Application Model](https://docs.aws.amazon.com/serverless-application-model/), which are used to
develop completely serverless applications.

It is meant to be used with GitHub Actions if you want dependencies to be packaged and uploaded to AWS S3 automatically.
The usage of the GitHub workflow is explained below but you can also check the workflow file in the Terraform template
repository.

This module manages the following resources:

* Lambda function
* Initial code upload to S3 (without dependencies)
* IAM role with default/custom policies
* Lambda specific security group if running inside VPC

## Compatibility

This module is meant to be used with Terraform 0.12

## General usage

This Terraform Lambda module provides all the required resources to get up and running with a simple AWS Lambda
function.

Apart from creating the Lambda source code you will have to provide an AWS S3 bucket where the code will be uploaded
and fetched by the Lambda service. You can also provide custom IAM policies in addition to AWS Managed policies. To do
so use the *custom_policies* argument and supply a set of files with *JSON* IAM policies.

### Source code

Function source code should be placed inside a **source** directory. If you don't want to trigger a Terraform plan each
time you update yourfunction source code, place this directory outside of Terraform trigger path. This directory should
only contain your function code and requirements.txt (if using Python third-party dependencies).

```
terraform-stack/
├── README.md
└── stack-function
    ├── prod
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── provider.tf
    │   └── variables.tf
    ├── source
    │   ├── function-one
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   └── function-two
    │       ├── main.py
    │       └── requirements.txt
    └── stage
        ├── main.tf
        ├── outputs.tf
        ├── provider.tf
        └── variables.tf
```

### GitHub Actions

Functions that require external dependencies must have their dependencies downloaded and packaged with the source
files. This can be done with a GitHub Actions workflow. You can check the inner workings by reviewing the
*.github/workflows/lambda-deploy.yml* file in the Terraform template repository.

This workflow is triggered whenever a file changes inside the *source* directory. It will then download the external
dependencies, package them with source files and upload them to the AWS Lambda service.

When using GitHub Actions it is important to include a **github.vars** file with information required to package the
function. The following is an example of the content of this file.

```
export AWS_DEFAULT_REGION=eu-west-1
export AWS_BUCKET_NAME=my-lambda-deploy
export AWS_LAMBDA_FUNCTION=my-function-name
```

This file should be placed inside the *source* directory.

```
└── stack-function
    ├── prod
    │   └── ....
    ├── source
    │   ├── function-one
    │   │   ├── github.vars
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   └── function-two
    │       ├── github.vars
    │       ├── main.py
    │       └── requirements.txt
```

### Examples

**When using Lambda without VPC**

```hcl
  module "myfunction" {
    source               = "app.terraform.io/glovo/lambda/aws"
    version              = "0.0.9"
    s3_bucket            = "my-lambda-deploy"
    function_name        = "my-function-name"
    function_source      = "../source/function-one"
    aws_managed_policies = [ "AWSLambdaBasicExecutionRole" ]

    handler_config = {
      module   = "main",
      function = "lambda_handler"
    }

    custom_tags = {
      "env"              = "dev",
      "project"          = "myproject",
      "built-using"      = "terraform"
      "terraform-module" = "lambda"
    }
  }
```

A default set of tags will be applied to each resource created by the module, but we would appreciate
if you include *custom_tags* with the appropriate values.

**When using Lambda with VPC**

```hcl
  module "myfunction" {
    source               = "app.terraform.io/glovo/lambda/aws"
    version              = "0.0.9"
    s3_bucket            = "my-lambda-deploy"
    function_name        = "my-function-name"
    function_source      = "../source/function-one"
    aws_managed_policies = [ "AWSLambdaVPCAccessExecutionRole" ]

    handler_config = {
      module   = "main",
      function = "lambda_handler"
    }

    vpc_config = {
      vpc_id  = "vpc-xxx",
      subnets = [ "subnet-xxx", "subnet-yyy" ]
    }

    custom_tags = {
      "env"              = "dev",
      "project"          = "myproject",
      "built-using"      = "terraform"
      "terraform-module" = "lambda"
    }
  }
```

A default set of tags will be applied to each resource created by the module, but we would appreciate
if you include *custom_tags* with the appropriate values.

## Automated Tests
Not yet

## Inputs and Outputs
Auto Generated info could be found at: https://app.terraform.io/app/glovo/modules/view/lambda/aws/

## Releasing New Versions
New versions are released by pushing tags to this repository's origin on GitHub.
Directly push to to master is prohibited. All changes MUST be done via a PR that has Actions enabled.
For comments strategy we MUST align on https://www.conventionalcommits.org

## Future Improvements
1. Support other programming languages for the GitHub actions
2. Include automated tests
