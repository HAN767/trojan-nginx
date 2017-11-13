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
  -- Protection against replay probing is provided by TLS.

  data, err = sock:receive('*y')
  if err then
    ngx.exit(ngx.ERROR)
  end

  local datalen = data:len()

  -- CRLF, CMD, ATYP
  local field_CMD = data:byte(3)
  local field_ATYP = data:byte(4)
  if field_CMD ~= 1 then
    -- CMD other than CONNECT is not implemented.
    ngx.exit(ngx.ERROR)
  end

  -- DST.ADDR, DST.PORT, CRLF
  local off = 4
  local portlen = 4
  local address
  if field_ATYP == 1 then
    -- IPv4
    local len = 4
    if datalen < off + len + portlen then
      ngx.exit(ngx.ERROR)
    end
    address = string.format("%d.%d.%d.%d", data:byte(off + 1, off + len))
    off = off + len
  elseif field_ATYP == 3 then
    -- Domain name
    off = off + 1
    local len = data:byte(off)
    if not len or len == 0 or datalen < off + len + portlen then
      ngx.exit(ngx.ERROR)
    end
    address = data:sub(off + 1, off + len)
    off = off + len
  elseif field_ATYP == 4 then
    -- IPv6
    local len = 16
    if datalen < off + len + portlen then
      ngx.exit(ngx.ERROR)
    end
    address = string.format("[%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x]",
                            data:byte(off + 1, off + len))
    off = off + len
  else
    ngx.exit(ngx.ERROR)
  end

  local hi, lo = data:byte(off + 1, off + 2)
  local port = hi * 256 + lo
  off = off + portlen

  ngx.ctx.backend_addr = address
  ngx.ctx.backend_port = port
  ngx.req.add_preread_data(data:sub(off + 1))
else
  if data then
    ngx.req.add_preread_data(data)
  end
  data = sock:receive('*y')
  if data then
    ngx.req.add_preread_data(data)
  end
end
