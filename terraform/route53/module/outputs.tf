output "findcovidtestingcom_ns" {
  description = "findcovidtestingcom NS"
  value       = aws_route53_zone.findcovidtestingcom.name_servers
}
output "findcovid19testingorg_ns" {
  description = "findcovid19testingorg NS"
  value       = aws_route53_zone.findcovid19testingorg.name_servers
}