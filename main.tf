resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_function.name
  description      = var.lambda_function.description
  handler          = var.lambda_function.handler
  runtime          = var.lambda_function.runtime
  memory_size      = var.lambda_function.memory_size
  layers           = var.lambda_function.layers_name != null ? [for layer_name in var.lambda_function.layers_name : aws_lambda_layer_version.for[layer_name].arn] : (var.lambda_function.layers_arn != null ? var.lambda_function.layers_arn : null)
  timeout          = var.lambda_function.timeout
  role             = var.lambda_function.role_arn
  filename         = var.lambda_function.filename
  source_code_hash = var.lambda_function.filename != null ? filebase64sha256(var.lambda_function.filename) : null


  dynamic "environment" {
    for_each = var.lambda_function.env_variables != null ? [""] : []
    content {
      variables = var.lambda_function.env_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda_function.vpc_config != null ? [""] : []
    content {
      ipv6_allowed_for_dual_stack = var.lambda_function.vpc_config.ipv6_allowed_for_dual_stack
      security_group_ids          = var.lambda_function.vpc_config.security_group_ids
      subnet_ids                  = var.lambda_function.vpc_config.subnet_ids
    }
  }
}

resource "aws_lambda_layer_version" "for" {
  for_each                 = var.lambda_layers
  filename                 = each.value.s3_bucket == null && each.value.s3_key == null && each.value.s3_object_version == null ? each.value.filename : null
  layer_name               = each.key
  compatible_architectures = toset(each.value.compatible_architectures)
  description              = each.value.description
  license_info             = each.value.license_info
  s3_bucket                = each.value.filename == null ? each.value.s3_bucket : null
  s3_key                   = each.value.filename == null ? each.value.s3_key : null
  s3_object_version        = each.value.filename == null ? each.value.s3_object_version : null
  skip_destroy             = each.value.skip_destroy
  source_code_hash         = each.value.source_code_hash
  compatible_runtimes      = each.value.compatible_runtimes
}

resource "aws_lambda_permission" "trigger" {

  for_each               = var.lambda_function.triggers
  action                 = each.value.action
  function_name          = aws_lambda_function.lambda.function_name
  principal              = each.value.principal
  source_arn             = each.value.source_arn
  event_source_token     = each.value.event_source_token
  function_url_auth_type = each.value.function_url_auth_type
  qualifier              = each.value.qualifier
  source_account         = each.value.source_account
  principal_org_id       = each.value.principal_org_id

}

resource "aws_lambda_function_url" "url" {
  
  count              = var.lambda_function.function_url != null ? 1 : 0
  authorization_type = var.lambda_function.function_url.authorization_type

  dynamic "cors" {
    for_each = var.lambda_function.function_url.cors
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }

  function_name = aws_lambda_function.lambda.function_name
  invoke_mode   = var.lambda_function.function_url.invoke_mode
  qualifier     = var.lambda_function.function_url.qualifier
}
