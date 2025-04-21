local DEBUG
local dir = debug.getinfo(1, "S").source:sub(2):match("(.*)/") or "."
package.path = package.path .. ";" .. tostring(dir) .. "/?.lua;" .. tostring(dir) .. "/?/init.lua;" .. tostring(dir) .. "/lib/?.lua;" .. tostring(dir) .. "/lib/?/init.lua"
local uhttpd = assert(uhttpd, "Only suitable with uhttpd")
local recv, send
recv, send = uhttpd.recv, uhttpd.send
local html = require("html")
local concat
concat = table.concat
local open, popen
do
  local _obj_0 = io
  open, popen = _obj_0.open, _obj_0.popen
end
local log
log = function(...)
  if DEBUG then
    do
      local _with_0 = open(DEBUG, "a")
      _with_0:write(concat((function(...)
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local i = _list_0[_index_0]
          _accum_0[_len_0] = tostring(i)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(...), " ") .. "\n\n")
      _with_0:close()
      return _with_0
    end
  end
end
if DEBUG then
  do
    local _with_0 = open(DEBUG, "w")
    _with_0:write("")
    _with_0:close()
  end
  local _send = send
  send = function(...)
    log(...)
    return _send(...)
  end
end
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
handle_request = function(self)
  local params, data
  do
    local _tbl_0 = { }
    for k, v in self.QUERY_STRING:gmatch("([^&=]+)=?([^&]*)") do
      _tbl_0[k] = v
    end
    params = _tbl_0
  end
  do
    data = select(2, recv())
    if data then
      do
        local _tbl_0 = { }
        for k, v in data:gmatch("([^&=]+)=?([^&]*)") do
          _tbl_0[k] = v
        end
        data = _tbl_0
      end
    else
      data = { }
    end
  end
  if self.PATH_INFO and self.PATH_INFO ~= "/" then
    require(self.PATH_INFO:gsub("/$", ""))(self, params, data)
  else
    do
      send("Status: 200 OK\nContent-Type: text/html\n\n\n<!DOCTYPE html>\n" .. html.html(html.head(html.title("uhttpd lua"), html.meta({
        charset = "utf-8"
      }), html.meta({
        name = "viewport",
        content = "width=device-width, initial-scale=1"
      }), html.meta({
        name = "color-scheme",
        content = "dark"
      })), html.body((function()
        local _accum_0 = { }
        local _len_0 = 1
        for u in read(popen("find " .. tostring(dir) .. " -type d -maxdepth 1")):gmatch(tostring(dir) .. "/(%w+)") do
          if u ~= "lib" and u:sub(1, 1) ~= "." then
            _accum_0[_len_0] = html.a({
              href = "./" .. tostring(u)
            }, u)
            _len_0 = _len_0 + 1
          end
        end
        return _accum_0
      end)())))
    end
  end
  if DEBUG then
    do
      send(html.footer(html.script("console.log('\\n\\n\\nENV')", concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in pairs(self) do
          _accum_0[_len_0] = "console.log('" .. tostring(k) .. "', '" .. tostring(v) .. "')"
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), "\n"), "console.log('\\n\\n\\nHEADERS')", concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in pairs(self.headers) do
          _accum_0[_len_0] = "console.log('" .. tostring(k) .. "', '" .. tostring(v) .. "')"
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), "\n")) or ""))
      return html
    end
  end
end
