output "selenium_grid_console_url" {
  description = "url for selenium grid console"
  value       = "http://${aws_lb.selenium_hub.dns_name}/grid/console"
}

output "selenium_grid_test_url" {
  description = "url for selenium grid tests"
  value       = "http://${aws_lb.selenium_hub.dns_name}/wd/hub"
}
