local cfg = require("captive.cfg")
local lunatik = require("lunatik")
local data = require("data")
local rcu = require("rcu")
local linux = require("linux")
local device = require("device")
local eth = require("ipparse.l2.ethernet")
local concat, sort
do
  local _obj_0 = table
  concat, sort = _obj_0.concat, _obj_0.sort
end
return function()
  local _true, nop
  _true, nop = data.new(1), function() end
  local env = lunatik._ENV
  env.captive_allowed = rcu.table(2048)
  local driver = {
    name = cfg.device,
    mode = linux.stat.IRUSR | linux.stat.IWUSR,
    open = nop,
    release = nop,
    read = function(self)
      local allowed = { }
      rcu.map(env.captive_allowed, function(self)
        allowed[#allowed + 1] = eth.mac2s(self)
      end)
      sort(allowed)
      return concat(allowed, ",") .. "\n"
    end,
    write = function(self, s)
      local op, mac = s:match("([+-])%s*([^\n]+)")
      local _exp_0 = op
      if "+" == _exp_0 then
        print("CAPTIVE: adding " .. tostring(mac) .. " to allowed")
        env.captive_allowed[eth.s2mac(mac)] = _true
      elseif "-" == _exp_0 then
        print("CAPTIVE: removing " .. tostring(mac) .. " from allowed")
        env.captive_allowed[eth.s2mac(mac)] = nil
      else
        return print("CAPTIVE ERROR: malformed entry " .. tostring(s))
      end
    end
  }
  return device.new(driver)
end
