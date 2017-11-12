local secret = "hunter2"
local sock, err = ngx.req.socket()
if err then
  ngx.exit(ngx.ERROR)
end

local data, err = sock:receive(secret:len())
if err then
  ngx.exit(ngx.ERROR)
end
if data == secret then
  -- Does normal error reporting once the shared secret is proven.
  -- Protection against replay probing is provided by TLS. (?)

  -- CRLF
  data, err = sock:receive(2)
  if err then
    ngx.exit(ngx.ERROR)
  end

  -- CMD, ATYP
  data, err = sock:receive(2)
  if err then
    ngx.exit(ngx.ERROR)
  end

  local command = data:byte(1)
  if command ~= 1 then
    -- CMD other than CONNECT is not implemented.
    ngx.exit(ngx.ERROR)
  end

  -- DST.ADDR
  local address_type = data:byte(2)
  local address
  if address_type == 1 then
    -- IPv4
    data, err = sock:receive(4)
    if err then
      ngx.exit(ngx.ERROR)
    end
    address = string.format("%d.%d.%d.%d", data:byte(1), data:byte(2), data:byte(3), data:byte(4))
  elseif address_type == 3 then
    -- Domain name
    data, err = sock:receive(1)
    if err then
      ngx.exit(ngx.ERROR)
    end
    local len = data:byte(1)
    data, err = sock:receive(len)
    address = data
  elseif address_type == 4 then
    -- IPv6
    data, err = sock:receive(16)
    if err then
      ngx.exit(ngx.ERROR)
    end
    address = string.format("[%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x]",
                            data:byte(1), data:byte(2), data:byte(3), data:byte(4),
                            data:byte(5), data:byte(6), data:byte(7), data:byte(8),
                            data:byte(9), data:byte(10), data:byte(11), data:byte(12),
                            data:byte(13), data:byte(14), data:byte(15), data:byte(16))
  end

  -- DST.PORT
  data, err = sock:receive(2)
  if err then
    ngx.exit(ngx.ERROR)
  end
  local port = data:byte(1) * 256 + data:byte(2)

  -- CRLF
  data, err = sock:receive(2)
  if err then
    ngx.exit(ngx.ERROR)
  end

  ngx.ctx.backend_addr = address
  ngx.ctx.backend_port = port
elseif data then
  ngx.req.add_preread_data(data)
end

data, err = sock:receive('*y')
if data then
  ngx.req.add_preread_data(data)
end
