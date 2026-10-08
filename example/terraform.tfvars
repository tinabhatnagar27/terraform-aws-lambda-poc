environments = ["stage", "prod"]

lambda_function = {
  name        = "demo1"
  runtime     = "python3.13"
  memory_size = 700
  timeout     = 50
  handler     = "lambda.lambda_handler"
  layers_name = []
  filename    = "lambda_function_payload.zip"
  role_arn    = "arn:aws:iam::557186391124:role/lamda_role"

  env_variables = {
    name = "demo"
    env  = "test"
  }

  vpc_config = {
    security_group_ids = ["sg-04fb2f273d8865af3"]

    subnet_ids = [
      "subnet-0a49bf4221b5f0107",
      "subnet-08a2aa30dbc179a2b"
    ]
  }

  triggers = {}

  function_url = {
    authorization_type = "NONE"
  }
}

lambda_layers = {}
