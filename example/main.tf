module "lambda" {
  for_each = var.environments

  source = "git::https://github.com/OT-CLOUD-KIT/terraform-aws-lambda.git?ref=Feature"

  lambda_function = merge(
    var.lambda_function,
    {
      name     = "lambda-${each.key}"
      role_arn = aws_iam_role.lambda_test_role.arn

      # VPC Configuration
      vpc_config = {
        security_group_ids = [
          aws_security_group.lambda_test_sg.id
        ]

        subnet_ids = [
          "subnet-012f72c8f11dda65b",
          "subnet-06b1d36693e5e7e72"
        ]
      }

      # Environment Variables
      env_variables = merge(
        coalesce(var.lambda_function.env_variables, {}),
        {
          ENV = each.key
        }
      )

      # Function URL Authentication
      function_url = {
        authorization_type = (
          each.key == "stage" ? "NONE" : "AWS_IAM"
        )
      }

      # EventBridge Trigger Permission
      triggers = {
        eventbridge = {
          action     = "lambda:InvokeFunction"
          principal  = "events.amazonaws.com"
          source_arn = aws_cloudwatch_event_rule.lambda_trigger[each.key].arn
        }
      }
    }
  )

  # Layers disabled for this POC
  lambda_layers = {}

  depends_on = [
    aws_iam_role_policy_attachment.basic,
    aws_iam_role_policy_attachment.vpc
  ]
}

# EventBridge Schedule Rules

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  for_each = var.environments

  name                = "lambda-${each.key}-trigger"
  description         = "Scheduled trigger for ${each.key} Lambda"
  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"
}

# EventBridge Targets

resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = var.environments

  rule = aws_cloudwatch_event_rule.lambda_trigger[each.key].name

  arn = module.lambda[each.key].lambda_function_arn
}
