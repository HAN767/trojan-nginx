local secret = "hunter2"
local sock, err = ngx.req.socket()
if err then
  ngx.exit(ngx.ERROR)
end

local data, err = sock:receive(2)
if err then
  ngx.exit(ngx.ERROR)
end

local field_VER = data:byte(1)
if field_VER ~= 5 then
  -- SOCKS5 only
  ngx.exit(ngx.ERROR)
end

local field_NMETHODS = data:byte(2)
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

local field_CMD = data:byte(2)
if field_CMD ~= 1 then
  sock:send("\5\7\0\1\0\0\0\0\0\0")
  ngx.exit(ngx.ERROR)
end

local field_ATYP = data:byte(4)
local field_DSTADDRPORT
if field_ATYP == 1 then
  field_DSTADDRPORT, err = sock:receive(6)
  if err then
    ngx.exit(ngx.ERROR)
  end
elseif field_ATYP == 3 then
  local len, err = sock:receive(1)
  if err then
    ngx.exit(ngx.ERROR)
  end
  data, err = sock:receive(len:byte(1) + 2)
  field_DSTADDRPORT = len .. data
  if err then
    ngx.exit(ngx.ERROR)
  end
elseif field_ATYP == 4 then
  field_DSTADDRPORT, err = sock:receive(18)
  if err then
    ngx.exit(ngx.ERROR)
  end
else
  sock:send("\5\8\0\1\0\0\0\0\0\0")
  ngx.exit(ngx.ERROR)
end

bytes, err = sock:send("\5\0\0\1\0\0\0\0\0\0")
if err then
  ngx.exit(ngx.ERROR)
end

local header = secret .. "\r\n" .. string.char(field_CMD, field_ATYP) .. field_DSTADDRPORT .. "\r\n"
ngx.req.add_preread_data(header)
