-- Global table to store connection statistics and port usage
connections = {}
port_usage = {
  src = {},
  dst = {}
}
-- Global table to store IP statistics
ip_stats = {
  src = {},
  dst = {}
}
-- File to store the statistics report
local report_file = "statistics_report.txt"

-- Create a unique key for the connection
local function create_key(data)
  return data.source ..":" .. data.src_port .. "->" .. data.destination .. ":" .. data.dst_port .. " Protocol:" .. data.prot
end

-- Update the connections table
local function update_connections(data, key)
  if not connections[key] then
    connections[key] = {
      count = 0,
      total_pkts = 0,
      total_bytes = 0
    }
  end

  connections[key].count = connections[key].count + 1
  connections[key].total_pkts = connections[key].total_pkts + data.d_pkts
  connections[key].total_bytes = connections[key].total_bytes + data.d_octets
end

-- Update port usage
local function update_port_usage(data)
  port_usage.src[data.prot] = port_usage.src[data.prot] or {}
  port_usage.src[data.prot][data.src_port] = true

  port_usage.dst[data.prot] = port_usage.dst[data.prot] or {}
  port_usage.dst[data.prot][data.dst_port] = true
end

-- Process data function
function process_data(data)
  local key = create_key(data)
  update_connections(data, key)
  update_port_usage(data)
  generate_report()
end

-- Write unique ports for each protocol
local function write_unique_ports(file, port_data, header)
  file:write(header)
  for prot, ports in pairs(port_data) do
    local port_list = {}
    for port, _ in pairs(ports) do
      table.insert(port_list, port)
    end
    file:write(string.format("%s: %s\n", prot, table.concat(port_list, ", ")))
  end
  file:write("\n")
end

-- Generate a statistics report
function generate_report()
  local sorted_keys = get_sorted_keys()
  local file = io.open(report_file, "w")

  -- Write the top 10 connections
  write_top_connections(file, sorted_keys)

  -- Write unique source and destination ports for each protocol
  write_unique_ports(file, port_usage.src, "\nUnique Source Ports by Protocol:\n")
  write_unique_ports(file, port_usage.dst, "\nUnique Destination Ports by Protocol:\n")

  -- Write the top 10 source and destination IPs by traffic volume
  write_top_ips(file, ip_stats.src, "Top 10 Source IPs by Traffic Volume:\n")
  write_top_ips(file, ip_stats.dst, "Top 10 Destination IPs by Traffic Volume:\n")

  file:close()
end

-- Sort the connections by packet count and return sorted keys
function get_sorted_keys()
  local sorted_keys = {}
  for k in pairs(connections) do
    table.insert(sorted_keys, k)
  end
  table.sort(sorted_keys, function(a, b) return connections[a].count > connections[b].count end)
  return sorted_keys
end

-- Write the top 10 connections to the file
function write_top_connections(file, sorted_keys)
  file:write("Top 10 Connections:\n")
  for i = 1, math.min(10, #sorted_keys) do
    local key = sorted_keys[i]
    file:write(string.format(
      "%s %d connections, %d packets, %d bytes\n",
      key,
      connections[key].count,
      connections[key].total_pkts,
      connections[key].total_bytes
    ))
  end
  file:write("\n")
end

-- Update IP statistics
local function update_ip_stats(data)
  ip_stats.src[data.source] = (ip_stats.src[data.source] or 0) + data.d_octets
  ip_stats.dst[data.destination] = (ip_stats.dst[data.destination] or 0) + data.d_octets
end

-- Process data function
function process_data(data)
  local key = create_key(data)
  update_connections(data, key)
  update_port_usage(data)
  update_ip_stats(data)  -- Update IP statistics
  generate_report()
end

-- Sort IPs by traffic volume and return sorted IPs
function get_sorted_ips(ip_data)
  local sorted_ips = {}
  for ip, volume in pairs(ip_data) do
    table.insert(sorted_ips, {ip = ip, volume = volume})
  end
  table.sort(sorted_ips, function(a, b) return a.volume > b.volume end)
  return sorted_ips
end

-- Write the top IPs by traffic volume to the file
function write_top_ips(file, ip_data, header)
  local sorted_ips = get_sorted_ips(ip_data)
  file:write(header)
  for i = 1, math.min(10, #sorted_ips) do
    file:write(string.format("%s: %d bytes\n", sorted_ips[i].ip, sorted_ips[i].volume))
  end
  file:write("\n")
end

