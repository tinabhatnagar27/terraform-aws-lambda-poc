resource "aws_security_group" "lambda_test_sg" {
  name        = "lambda-module-test-sg"
  description = "Security group for Lambda module testing"
  vpc_id      = "vpc-041e9a4ba7145df2f"

  tags = {
    Name = "lambda-module-test-sg"
  }
}
