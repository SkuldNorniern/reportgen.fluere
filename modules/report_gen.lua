local config = require "modules.config"

local report_gen = {}

function report_gen.get_sorted_keys()
  local sorted_keys = {}
  for k in pairs(config.connections) do
    table.insert(sorted_keys, k)
  end
  table.sort(sorted_keys, function(a, b) return config.connections[a].count > config.connections[b].count end)
  return sorted_keys
end

function report_gen.write_top_connections(file, sorted_keys)
  file:write("Top 10 Connections:\n")
  for i = 1, math.min(10, #sorted_keys) do
    local key = sorted_keys[i]
    file:write(string.format(
      "%s %d connections, %d packets, %d bytes\n",
      key,
      config.connections[key].count,
      config.connections[key].total_pkts,
      config.connections[key].total_bytes
    ))
  end
  file:write("\n")
end

function report_gen.write_unique_ports(file, port_data, header)
  file:write(header)
  for prot, ports in pairs(port_data) do
    local port_list = {}
    for port, _ in pairs(ports) do
      table.insert(port_list, port)
    end

    -- Convert the port list to a list of numbers and sort it
    local numbers = {}
    for _, port in ipairs(port_list) do
      if tonumber(port) then
        table.insert(numbers, tonumber(port))
      end
    end
    table.sort(numbers)

    -- Find continuous ranges
    local ranges = {}
    local current_start = math.floor(numbers[1] / config.config_div) * config.config_div
    local current_end = current_start

    for _, num in ipairs(numbers) do
      if math.floor(num / config.config_div) * config.config_div > current_end + config.config_div then
        table.insert(ranges, {current_start, current_end + (config.config_div - 1)})
        current_start = math.floor(num / config.config_div) * config.config_div
      end
      current_end = math.floor(num / config.config_div) * config.config_div
    end
    table.insert(ranges, {current_start, current_end + (config.config_div - 1)})

    -- Merge consecutive ranges
    local merged_ranges = {}
    local start, _end = table.unpack(ranges[1])
    for i = 2, #ranges do
      local r = ranges[i]
      if r[1] - _end == config.config_div then
        _end = r[2]
      else
        table.insert(merged_ranges, start .. " ~ " .. _end)
        start, _end = table.unpack(r)
      end
    end
    table.insert(merged_ranges, start .. " ~ " .. _end)

    -- Write the merged ranges to the file
    file:write(string.format("%s: [ %s ]\n", prot, table.concat(merged_ranges, ", ")))
  end
  file:write("\n")
end

function report_gen.get_sorted_ips(ip_data)
  local sorted_ips = {}
  for ip, volume in pairs(ip_data) do
    table.insert(sorted_ips, {ip = ip, volume = volume})
  end
  table.sort(sorted_ips, function(a, b) return a.volume > b.volume end)
  return sorted_ips
end

function report_gen.write_top_ips(file, ip_data, header)
  local sorted_ips = report_gen.get_sorted_ips(ip_data)
  file:write(header)
  for i = 1, math.min(10, #sorted_ips) do
    file:write(string.format("%s: %d bytes\n", sorted_ips[i].ip, sorted_ips[i].volume))
  end
  file:write("\n")end

function report_gen.generate_report()
  local sorted_keys = report_gen.get_sorted_keys()
  local file = io.open(config.report_file, "w")

  report_gen.write_top_connections(file, sorted_keys)
  report_gen.write_unique_ports(file, config.port_usage.src, "\nUnique Source Ports by Protocol:\n")
  report_gen.write_unique_ports(file, config.port_usage.dst, "\nUnique Destination Ports by Protocol:\n")
  report_gen.write_top_ips(file, config.ip_stats.src, "Top 10 Source IPs by Traffic Volume:\n")
  report_gen.write_top_ips(file, config.ip_stats.dst, "Top 10 Destination IPs by Traffic Volume:\n")

  file:close()
end

return report_gen

