output "lambda_function_names" {
  description = "Names of Stage and Prod Lambda functions"

  value = {
    for env, mod in module.lambda :
    env => mod.lambda_function_name
  }
}

output "lambda_function_arns" {
  description = "ARNs of Stage and Prod Lambda functions"

  value = {
    for env, mod in module.lambda :
    env => mod.lambda_function_arn
  }
}

output "lambda_function_urls" {
  description = "Function URLs of Stage and Prod Lambda functions"

  value = {
    for env, mod in module.lambda :
    env => try(mod.lambda_function_url, null)
  }
}
