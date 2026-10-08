# Terraform AWS Lambda Module – Stage & Production POC

## Overview

This project demonstrates the deployment and validation of AWS Lambda functions using a reusable Terraform module.

The Proof of Concept (POC) was implemented using the `Feature` branch of the [OT-CLOUD-KIT Terraform AWS Lambda Module](https://github.com/OT-CLOUD-KIT/terraform-aws-lambda/tree/Feature).

The objective was to validate environment-based Lambda deployment, VPC integration, IAM execution roles, Function URL authentication, and EventBridge scheduled triggers.

## Objectives

- Deploy two AWS Lambda functions for Stage and Production environments.
- Use Terraform `for_each` to manage multiple environments.
- Configure Lambda runtime, memory, timeout, handler, and environment variables.
- Attach both Lambda functions to an existing VPC.
- Create and assign an IAM execution role with the required permissions.
- Configure Lambda Function URLs with different authentication types.
- Configure EventBridge scheduled triggers using the Lambda module's trigger input.
- Verify deployment and execution through AWS CLI and CloudWatch.

## Architecture

```text
Terraform Example Configuration
             |
             v
Reusable AWS Lambda Module
             |
      +------+------+
      |             |
      v             v
 Stage Lambda    Prod Lambda
      |             |
      +------+------+
             |
       VPC Configuration
       IAM Execution Role
             |
      +------+------+
      |             |
      v             v
 Function URL    Function URL
   (NONE)         (AWS_IAM)
      |             |
      +------+------+
             |
      EventBridge Rules
       rate(5 minutes)
             |
       CloudWatch Logs
```

## Technology Stack

| Component | Technology |
|---|---|
| Infrastructure as Code | Terraform |
| Cloud Provider | AWS |
| Compute | AWS Lambda |
| Runtime | Python 3.13 |
| Networking | Amazon VPC |
| Security | AWS IAM, Security Groups |
| Scheduling | Amazon EventBridge |
| Logging and Monitoring | Amazon CloudWatch |
| Authentication | NONE and AWS_IAM |
| Deployment Region | us-east-1 |

## Project Structure

```text
terraform-aws-lambda/
├── main.tf
├── variables.tf
├── output.tf
├── README.md
└── example/
    ├── main.tf
    ├── variable.tf
    ├── provider.tf
    ├── terraform.tfvars
    ├── output.tf
    ├── iam.tf
    ├── vpc.tf
    └── lambda_function_payload.zip
```

The root directory contains the reusable Terraform Lambda module. The `example/` directory contains the configuration used for the POC deployment and testing.

## Implementation Details

### 1. Environment-Based Lambda Deployment

Terraform `for_each` was used to deploy separate Lambda functions for Stage and Production.

```hcl
module "lambda" {
  for_each = var.environments

  source = "git::https://github.com/OT-CLOUD-KIT/terraform-aws-lambda.git?ref=Feature"

  # Lambda configurations
}
```

The environment variable was defined as:

```hcl
variable "environments" {
  description = "Environments for Lambda deployment"
  type        = set(string)
  default     = ["stage", "prod"]
}
```

Both environments were deployed from the same Terraform configuration.

### 2. Lambda Function Configuration

| Configuration | Stage | Production |
|---|---|---|
| Function Name | lambda-stage | lambda-prod |
| Runtime | Python 3.13 | Python 3.13 |
| Memory | 700 MB | 700 MB |
| Timeout | 50 seconds | 50 seconds |
| Handler | lambda.lambda_handler | lambda.lambda_handler |
| Environment Variable | ENV=stage | ENV=prod |
| Deployment Package | ZIP | ZIP |

A simple Python Lambda handler was used to validate successful execution.

```python
import json

def lambda_handler(event, context):
    print("Hello, World!")
    return {
        "statusCode": 200,
        "body": json.dumps("Hello, World!")
    }
```

### 3. VPC Configuration

Both Lambda functions were deployed with VPC configuration using two subnets and a dedicated Security Group.

```hcl
vpc_config = {
  security_group_ids = [
    aws_security_group.lambda_test_sg.id
  ]

  subnet_ids = [
    "subnet-012f72c8f11dda65b",
    "subnet-06b1d36693e5e7e72"
  ]
}
```

VPC ID: `vpc-041e9a4ba7145df2f`

Security Group: `lambda-module-test-sg`

The subnet IDs belong to the same VPC and are located in different Availability Zones.

### 4. IAM Execution Role

A dedicated IAM execution role was created for the Lambda module testing.

Role Name: `lambda-module-test-role`

The following AWS-managed policies were attached:

- `AWSLambdaBasicExecutionRole`
- `AWSLambdaVPCAccessExecutionRole`

These provide the permissions needed for CloudWatch logging and Lambda VPC networking operations.

The role was passed to the Lambda module using its ARN.

### 5. Lambda Function URL Authentication

Different authentication types were configured to validate Function URL support.

```hcl
function_url = {
  authorization_type = each.key == "stage" ? "NONE" : "AWS_IAM"
}
```

| Environment | Auth Type | HTTP Test Result |
|---|---|---|
| Stage | NONE | HTTP 200 OK |
| Production | AWS_IAM | HTTP 403 for unsigned request |
| Production | AWS_IAM | HTTP 200 for SigV4-signed request |

The Stage Function URL successfully returned `Hello, World!` through an unauthenticated HTTP request.

The Production Function URL rejected an unsigned HTTP request and successfully processed an authenticated AWS Signature Version 4 request.

### 6. EventBridge Trigger Configuration

Separate EventBridge scheduled rules were configured for each environment.

```hcl
resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  for_each = var.environments

  name                = "lambda-${each.key}-trigger"
  description         = "Scheduled trigger for ${each.key} Lambda"
  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"
}
```

The EventBridge targets were connected to their corresponding Lambda functions.

```hcl
resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = var.environments

  rule = aws_cloudwatch_event_rule.lambda_trigger[each.key].name
  arn  = module.lambda[each.key].lambda_function_arn
}
```

The module's `triggers` input was used to create the Lambda invocation permissions.

```hcl
triggers = {
  eventbridge = {
    action     = "lambda:InvokeFunction"
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.lambda_trigger[each.key].arn
  }
}
```

This validated the module's integration with EventBridge trigger permissions.

## Deployment Procedure

All Terraform deployment commands were executed from the `example/` directory.

```bash
cd example

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

The deployment successfully provisioned:

- Two Lambda functions
- Two Lambda Function URLs
- One dedicated Lambda execution IAM role
- Required IAM policy attachments
- One Lambda Security Group
- Two EventBridge scheduled rules
- Two EventBridge targets
- Two Lambda invocation permissions

## Testing and Validation

### Lambda Invocation

The Stage Lambda was invoked using AWS CLI:

```bash
aws lambda invoke \
  --function-name lambda-stage \
  --region us-east-1 \
  --payload '{}' \
  stage-response.json
```

The Lambda execution logs confirmed the expected output:

```text
Hello, World!
```

CloudWatch Logs were also verified for the Production Lambda.

### Function URL Testing

The Stage Function URL was tested using an unauthenticated HTTP request.

Result:

```text
HTTP/1.1 200 OK

"Hello, World!"
```

The Production Function URL was tested using both unsigned and SigV4-signed HTTP requests.

Unsigned request:

```text
HTTP/1.1 403 Forbidden
```

Signed request:

```text
HTTP Status: 200
Response: "Hello, World!"
```

### EventBridge Trigger Verification

Both EventBridge rules were verified as enabled.

```text
lambda-stage-trigger
State: ENABLED
Schedule: rate(5 minutes)

lambda-prod-trigger
State: ENABLED
Schedule: rate(5 minutes)
```

EventBridge target ARNs were verified using AWS CLI.

CloudWatch EventBridge invocation metrics were also checked.

| Environment | Reported Invocations | Result |
|---|---:|---|
| Stage | 2 | Invocation metric verified |
| Production | 2 | Invocation metric verified |

CloudWatch Logs confirmed successful Lambda execution. EventBridge invocation metrics confirmed invocation attempts from both scheduled rules.

A separate failure-metric check was not documented.

## POC Validation Results

| Test Case | Result |
|---|---|
| Terraform initialization | PASS |
| Terraform configuration validation | PASS |
| Stage Lambda deployment | PASS |
| Production Lambda deployment | PASS |
| Environment-based configuration | PASS |
| VPC attachment | PASS |
| IAM execution role attachment | PASS |
| Stage Function URL authentication | PASS |
| Production Function URL authentication | PASS |
| Production unauthorized-access rejection | PASS |
| EventBridge rule creation | PASS |
| EventBridge target association | PASS |
| Module-level trigger permission creation | PASS |
| CloudWatch Lambda execution logs | PASS |
| EventBridge invocation metrics | PASS |

## Issues Encountered and Resolutions

**1. GitHub SSH Authentication Error**

The initial GitHub SSH module source failed with a public-key authentication error.

Resolution: The Terraform module source was changed to HTTPS.

**2. Cross-Account IAM Execution Role**

Lambda creation initially failed because the configured execution role belonged to another AWS account.

Resolution: A dedicated Lambda execution role was created in the deployment account.

**3. Invalid VPC Security Group**

Lambda creation failed because the configured Security Group ID did not exist in the selected AWS account and region.

Resolution: A dedicated Security Group was created in the target VPC and assigned to both Lambda functions.

**4. Incorrect Lambda Handler**

The configured handler initially did not match the Python filename inside the ZIP archive.

Resolution: The handler was updated to `lambda.lambda_handler`.

**5. AWS CLI Compatibility**

The installed AWS CLI v1 did not support the Function URL configuration command.

Resolution: Terraform state was used to verify Function URL settings, while `curl` and Python with botocore SigV4 signing were used for HTTP testing.

## Security Considerations

- Production Function URL uses `AWS_IAM` authentication.
- The Stage Function URL uses `NONE` authentication for temporary POC testing and is publicly accessible.
- A dedicated execution IAM role and Security Group were used.
- The `terraform.tfvars` values should be reviewed before reuse in another AWS account.
- Public Function URLs and scheduled resources should be restricted or removed when no longer required.

## Cleanup

To remove the test infrastructure, review the Terraform destroy plan:

```bash
terraform plan -destroy
```

If the planned resource removal is correct:

```bash
terraform destroy
```

Run cleanup only after saving the required testing evidence and confirming that the resources are no longer needed.

## Conclusion

The Terraform AWS Lambda module was successfully deployed and validated for Stage and Production environments.

The POC confirmed support for environment-based Lambda creation, VPC integration, IAM execution roles, Function URL authentication, EventBridge trigger permissions, and CloudWatch monitoring.

The tested core functionality worked as expected. Further verification may include scheduled-invocation failure metrics, additional Lambda configuration scenarios, and production security hardening.
