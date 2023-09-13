local config = require "modules.config"

local data_process = require "modules.data_process"
local report_gen = require "modules.report_gen"

local plugin = {}

function plugin.init(config_data)
  print("Report Plugin Initialized")
  config.config_div = config_data.div_range
end

function plugin.cleanup()
  -- Cleanup resources before the plugin is unloaded
  -- For now, it's empty, but you can add any necessary cleanup here.
end

function plugin.process_data(data)
  local key = data_process.create_key(data)
  data_process.update_connections(data, key)
  data_process.update_port_usage(data)
  data_process.update_ip_stats(data)
  report_gen.generate_report()
end

return plugin

