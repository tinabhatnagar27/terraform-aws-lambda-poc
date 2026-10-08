variable "lambda_function" {
  type = object({
    name          = string
    description   = optional(string)
    handler       = optional(string, null)
    runtime       = optional(string, "python3.10")
    memory_size   = optional(number, 128)
    layers_arn    = optional(list(string))
    layers_name   = optional(list(string))
    role_arn      = optional(string)
    filename      = optional(string)
    timeout       = optional(number, 3)
    env_variables = optional(map(string))

    function_url = optional(object({
      authorization_type = string
      invoke_mode        = optional(string, "BUFFERED")
      qualifier          = optional(string)

      cors = optional(list(object({
        allow_credentials = optional(bool)
        allow_headers     = optional(set(string))
        allow_methods     = optional(set(string))
        allow_origins     = optional(set(string))
        expose_headers    = optional(set(string))
        max_age           = optional(number)

      })), [])
    }))

    vpc_config = optional(object({
      ipv6_allowed_for_dual_stack = optional(bool, false)
      subnet_ids                  = list(string)
      security_group_ids          = list(string)
    }))

    triggers = optional(map(object({
      action                 = optional(string, "lambda:InvokeFunction")
      principal              = string
      source_arn             = optional(string)
      event_source_token     = optional(string)
      function_url_auth_type = optional(string)
      qualifier              = optional(string)
      source_account         = optional(string)
      principal_org_id       = optional(string)
    })), {})
  })
}

variable "lambda_layers" {
  type = map(object({
    filename                 = optional(string)
    layer_name               = optional(string)
    compatible_architectures = optional(list(string), ["x86_64"])
    description              = optional(string)
    license_info             = optional(string)
    s3_bucket                = optional(string)
    s3_key                   = optional(string)
    s3_object_version        = optional(string)
    skip_destroy             = optional(bool)
    source_code_hash         = optional(string)
    compatible_runtimes      = list(string)
  }))
  default = {}
}
