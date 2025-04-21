local execute, time
do
  local _obj_0 = os
  execute, time = _obj_0.execute, _obj_0.time
end
local open, popen
do
  local _obj_0 = io
  open, popen = _obj_0.open, _obj_0.popen
end
local concat, sort
do
  local _obj_0 = table
  concat, sort = _obj_0.concat, _obj_0.sort
end
local decode
decode = require("base64").decode
local read
read = function(self, what)
  if what == nil then
    what = "*a"
  end
  if self then
    local ret = self:read(what)
    return self:close() and ret
  end
end
local opairs
opairs = function(self, f)
  local i, keys = 0, (function()
    local _accum_0 = { }
    local _len_0 = 1
    for k in pairs(self) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
  sort(keys, f)
  return function()
    i = i + 1
    local k = keys[i]
    return k, self[k]
  end
end
return function(self)
  local users
  if type(self) == "table" then
    users = self
  end
  local htpasswd
  if type(self) == "string" then
    htpasswd = self
  end
  if htpasswd then
    do
      local txt = read(assert(open(htpasswd)))
      if txt then
        do
          local _tbl_0 = { }
          for u, h in txt:gmatch("(%S+):(%S+)") do
            _tbl_0[u] = h
          end
          users = _tbl_0
        end
      end
    end
  end
  local adduser
  adduser = function(self, pwd)
    if not self then
      return nil, "No username given"
    end
    local tmp = "/tmp/.htpwd_" .. tostring(time()) .. ".tmp"
    do
      local _with_0 = popen("openssl passwd -apr1 -stdin > " .. tostring(tmp), "w")
      _with_0:write(pwd)
      _with_0:close()
    end
    users[self] = read(open(tmp)):sub(1, -2)
    execute("rm " .. tostring(tmp))
    if htpasswd then
      do
        local out = assert(open(htpasswd, "w"))
        if out then
          out:write(concat((function()
            local _accum_0 = { }
            local _len_0 = 1
            for u, h in opairs(users) do
              _accum_0[_len_0] = tostring(u) .. ":" .. tostring(h) .. "\n"
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)()))
          out:close()
          return self
        end
      end
      return nil, "Couldn’t write into " .. tostring(htpasswd)
    end
    return self
  end
  local validate
  validate = function(self, pwd)
    if not self then
      return nil, "No username given"
    end
    local h = users[self]
    if not h then
      return nil, "Invalid user"
    end
    local a, s = h:match("$(%S+)$(%S+)$%S+")
    local tmp = "/tmp/.htpwd_" .. tostring(time()) .. ".tmp"
    do
      local _with_0 = popen("openssl passwd -" .. tostring(a) .. " -salt " .. tostring(s) .. " -stdin > " .. tostring(tmp), "w")
      _with_0:write(pwd)
      _with_0:close()
    end
    local _h = read(open(tmp)):sub(1, #h)
    execute("rm " .. tostring(tmp))
    if h ~= _h then
      return nil, "Bad password"
    end
    return self
  end
  local validate_b64
  validate_b64 = function(self)
    local usr, pwd = decode(self):match("([^%s:]+):(%S+)")
    return validate(usr, pwd)
  end
  return {
    validate = validate,
    validate_b64 = validate_b64,
    adduser = adduser,
    users = users
  }
end
