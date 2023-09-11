local config = require "modules.config"

local data_process = {}

function data_process.create_key(data)
  return data.source ..":" .. data.src_port .. "->" .. data.destination .. ":" .. data.dst_port .. " Protocol:" .. data.prot
end

function data_process.update_connections(data, key)
  if not config.connections[key] then
    config.connections[key] = {
      count = 0,
      total_pkts = 0,
      total_bytes = 0
    }
  end
  config.connections[key].count = config.connections[key].count + 1
  config.connections[key].total_pkts = config.connections[key].total_pkts + data.d_pkts
  config.connections[key].total_bytes = config.connections[key].total_bytes + data.d_octets
end

function data_process.update_port_usage(data)
  config.port_usage.src[data.prot] = config.port_usage.src[data.prot] or {}
  config.port_usage.src[data.prot][data.src_port] = true

  config.port_usage.dst[data.prot] = config.port_usage.dst[data.prot] or {}
  config.port_usage.dst[data.prot][data.dst_port] = true
end

function data_process.update_ip_stats(data)
  config.ip_stats.src[data.source] = (config.ip_stats.src[data.source] or 0) + data.d_octets
  config.ip_stats.dst[data.destination] = (config.ip_stats.dst[data.destination] or 0) + data.d_octets
end

return data_process

