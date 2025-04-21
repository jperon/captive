local DEBUG = false
local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*)/") or "."
package.path = package.path .. ";" .. tostring(script_path) .. "/lib/?.lua;" .. tostring(script_path) .. "/lib/?/init.lua"
local uhttpd = assert(uhttpd)
local send
send = uhttpd.send
local html = require("html")
local decode, encode
do
  local _obj_0 = require("base64")
  decode, encode = _obj_0.decode, _obj_0.encode
end
local execute, date, time
do
  local _obj_0 = os
  execute, date, time = _obj_0.execute, _obj_0.date, _obj_0.time
end
local open, popen, stderr
do
  local _obj_0 = io
  open, popen, stderr = _obj_0.open, _obj_0.popen, _obj_0.stderr
end
local concat
concat = table.concat
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
local uci_get
uci_get = function(self, config)
  if config == nil then
    config = "captive"
  end
  return read(popen("uci get " .. tostring(config) .. "." .. tostring(self))):sub(1, -2)
end
local USERS
do
  local _tbl_0 = { }
  for u, h in uci_get("users.users"):gmatch("(%S+):(%S+)") do
    _tbl_0[u] = h
  end
  USERS = _tbl_0
end
local CSS = uci_get("common.css")
local DAY_BEGIN = uci_get("common.day_begin")
local DAY_END = uci_get("common.day_end")
local MODE = uci_get("common.mode")
local AUTHENTICATED = "/tmp/.captive_portal_authenticated"
local validate
validate = require("htpasswd")(USERS).validate
local log
log = function(...)
  if DEBUG then
    return stderr:write(concat((function(...)
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
    end)(...), " ") .. "\n")
  end
end
local wrap
wrap = function(self, msg)
  if DEBUG then
    return function(...)
      log(msg, ...)
      return self(...)
    end
  else
    return self
  end
end
execute = wrap(execute, "EXECUTE")
send = wrap(send, "SEND")
local open_access = ({
  lunatik = function(self)
    do
      local _with_0 = open("/dev/captive", "w")
      _with_0:write("+ " .. tostring(self))
      _with_0:close()
      return _with_0
    end
  end,
  nft = function(self)
    return execute("nft -f - <<EOF\n      add element inet captive captive_auth { " .. tostring(self) .. " }\n      delete element inet captive captive_auth { " .. tostring(self) .. " }\n      add element inet captive captive_auth { " .. tostring(self) .. " }\n      EOF\n    ")
  end
})[MODE]
local close_access = ({
  lunatik = function(self)
    do
      local _with_0 = open("/dev/captive", "w")
      _with_0:write("- " .. tostring(self))
      _with_0:close()
      return _with_0
    end
  end,
  nft = function(self)
    return execute("nft -f - <<EOF\n      add element inet captive captive_auth { " .. tostring(self) .. " }\n      delete element inet captive captive_auth { " .. tostring(self) .. " }\n      EOF\n    ")
  end
})[MODE]
return function(self, params, data)
  local authenticated
  do
    local txt = read(open(AUTHENTICATED))
    if txt then
      do
        local _tbl_0 = { }
        for cookie, t in txt:gmatch("([^%s:]+):(%S+)") do
          _tbl_0[cookie] = t
        end
        authenticated = _tbl_0
      end
    else
      authenticated = { }
    end
  end
  local ip = self.REMOTE_HOST
  log("IP", ip)
  local mac = read(popen("ip neigh")):match(tostring(ip) .. "%sdev%s.-lladdr%s([^\n%s]+)")
  log("MAC", mac)
  local cookie
  do
    local cookies = self.headers.cookie
    if cookies then
      do
        local auth = cookies:match("auth=([^;]+)")
        if auth then
          do
            local t = authenticated[auth]
            if t then
              if not params.logout and time() < tonumber(t) and mac == decode(auth):match("[^|]+|([^|]+)|[^|]+") then
                cookie = auth
              else
                authenticated[auth] = nil
              end
            end
          end
        end
      end
    end
  end
  cookie = cookie or (function()
    if data.usr then
      do
        local usr = validate(data.usr, data.pwd)
        if usr then
          local t = time() + 3600
          local c = encode(tostring(usr) .. "|" .. tostring(mac) .. "|" .. tostring(t))
          authenticated[c] = t
          return c
        end
      end
    end
  end)()
  local hour = date("%H:%M")
  local night
  if DAY_END <= hour or hour < DAY_BEGIN then
    night = "Internet est bloqué de " .. tostring(DAY_BEGIN) .. " à " .. tostring(DAY_END) .. "."
  end
  do
    send("Status: 200 OK\nContent-Type: text/html\n" .. tostring(cookie and "Set-Cookie: auth=" .. tostring(cookie) .. "; Max-Age: 3600" or '') .. "\n\n<!DOCTYPE html>" .. html.html({
      lang = "fr"
    }, html.head, html.meta({
      charset = "utf-8"
    }), html.meta({
      name = "viewport",
      content = "width=device-width,initial-scale=1"
    }), cookie and html.meta({
      ["http-equiv"] = "refresh",
      content = "30"
    }), html.style(read(open(CSS)) or ""), cookie and html.body(html.p("Connecté"), html.p("Fermer cet onglet vous déconnectera ; il faudra alors fermer et rouvrir votre navigateur pour vous reconnecter."), night and html.p(night or ""), html.p(html.a({
      href = "?logout=true"
    }, "Déconnexion")), html.p({
      style = "text-align:right"
    }, html.small(html.a({
      href = (tostring(self.REQUEST_URI) .. "/users"):gsub("//", "/")
    }, "Gestion des utilisateurs")))) or html.body(html.main(html.form({
      method = "POST"
    }, {
      action = self.REQUEST_URI:gsub("logout=[^&]+", "")
    }, html.fieldset(html.legend("Authentification"), html.input({
      name = "usr",
      type = "text"
    }), html.input({
      name = "pwd",
      type = "password"
    }), html.button("OK"))))), cookie and night and html.script("window.alert('" .. tostring(night) .. "')")))
  end
  if cookie then
    open_access(mac)
  else
    close_access(mac)
  end
  do
    local f = open(AUTHENTICATED, "w")
    if f then
      f:write(concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for u, c in pairs(authenticated) do
          if u then
            _accum_0[_len_0] = tostring(u) .. ":" .. tostring(c) .. "\n"
            _len_0 = _len_0 + 1
          end
        end
        return _accum_0
      end)()))
      return f:close()
    end
  end
end
