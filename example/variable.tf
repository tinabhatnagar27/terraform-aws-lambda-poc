variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region to deploy Lambda"
}

variable "lambda_function" {
  type = object({
    name        = string
    runtime     = string
    memory_size = number
    timeout     = number
    handler     = string
    layers_name = optional(list(string))
    layers_arn  = optional(list(string))
    role_arn    = string
    filename    = string

    env_variables = optional(map(string))

    vpc_config = optional(object({
      ipv6_allowed_for_dual_stack = optional(bool, false)
      security_group_ids          = list(string)
      subnet_ids                  = list(string)
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
    })))

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
  })
}

variable "lambda_layers" {
  type = map(object({
    filename                 = optional(string)
    compatible_runtimes      = list(string)
    compatible_architectures = optional(list(string), ["x86_64"])
    description              = optional(string)
    license_info             = optional(string)
    s3_bucket                = optional(string)
    s3_key                   = optional(string)
    s3_object_version        = optional(string)
    skip_destroy             = optional(bool)
    source_code_hash         = optional(string)
  }))
}

variable "environments" {
  description = "Environments for Lambda deployment"
  type        = set(string)

  default = ["stage", "prod"]

  validation {
    condition = alltrue([
      for env in var.environments :
      contains(["stage", "prod"], env)
    ])

    error_message = "Only stage and prod are allowed."
  }
}
