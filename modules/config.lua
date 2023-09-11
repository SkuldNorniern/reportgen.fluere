local config = {
  connections = {},
  port_usage = {
    src = {},
    dst = {}
  },
  ip_stats = {
    src = {},
    dst = {}
  },
  report_file = "statistics_report.txt",
  config_div = 1000 -- Default value, will be updated during initialization
}

return config

