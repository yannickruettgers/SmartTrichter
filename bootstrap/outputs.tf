output "github_actions_role_arn" {
  description = "The ARN of the IAM role GitHub Actions should assume"
  value       = aws_iam_role.github_actions_role.arn
}
