local secret = "hunter2"
local sock, err = ngx.req.socket()
if err then
  ngx.exit(ngx.ERROR)
end

local data, err = sock:receive(2)
if err then
  ngx.exit(ngx.ERROR)
end

local field_VER, field_NMETHODS = data:byte(1, 2)
if field_VER ~= 5 then
  -- SOCKS5 only
  ngx.exit(ngx.ERROR)
end

data, err = sock:receive(field_NMETHODS)
if err then
  ngx.exit(ngx.ERROR)
end

local bytes, err = sock:send("\5\0")
if err then
  ngx.exit(ngx.ERROR)
end

data, err = sock:receive(4)
if err then
  ngx.exit(ngx.ERROR)
end

local field_VER, field_CMD, field_RSV, field_ATYP = data:byte(1, 4)
if field_CMD ~= 1 then
  -- CMD other than CONNECT is not implemented.
  ngx.exit(ngx.ERROR)
end

local field_DSTADDRPORT, err = sock:receive('*y')
if err then
  ngx.exit(ngx.ERROR)
end

bytes, err = sock:send("\5\0\0\1\0\0\0\0\0\0")
if err then
  ngx.exit(ngx.ERROR)
end

local header = secret .. "\r\n" .. string.char(field_CMD, field_ATYP) .. field_DSTADDRPORT .. "\r\n"
ngx.req.add_preread_data(header)
