local cfg = require("captive.cfg")
local lunatik = require("lunatik")
local nf = require("netfilter")
local eth = require("ipparse.l2.ethernet")
local ip = require("ipparse.l3.ip")
local tcp = require("ipparse.l4.tcp")
local udp = require("ipparse.l4.udp")
local mail = require("mailbox")
local any, map
do
  local _obj_0 = require("ipparse.fun")
  any, map = _obj_0.any, _obj_0.map
end
local localnets = cfg.localnets and map(cfg.localnets, ip.s2net):toarray() or { }
return function()
  local env = lunatik._ENV
  local to_redirect = mail.outbox("captive_http", false)
  local hook
  hook = function(self)
    local pkt = self:getstring(0)
    local l2 = eth.parse(pkt)
    local l3 = ip.parse(pkt, l2.data_off)
    local l4
    local _exp_0 = l3.protocol
    if ip.proto.UDP == _exp_0 then
      l4 = udp.parse(pkt, l3.data_off)
    elseif ip.proto.TCP == _exp_0 then
      l4 = tcp.parse(pkt, l3.data_off)
    end
    if not l4 then
      return nf.action.CONTINUE
    end
    do
      local allowed = env.captive_allowed
      if allowed then
        if allowed[l2.src] then
          return nf.action.CONTINUE
        end
      end
    end
    if any(localnets, function(self)
      return ip.contains_ip(self, l3.dst)
    end) then
      return nf.action.CONTINUE
    end
    if l3.protocol == ip.proto.TCP then
      if ip.proto.TCP and l4.spt == 80 then
        return nf.action.CONTINUE
      end
      if l4.dpt == 80 then
        to_redirect:send(pkt)
      end
    end
    return nf.action.DROP
  end
  local _list_0 = {
    nf.family.IPV4,
    nf.family.IPV6
  }
  for _index_0 = 1, #_list_0 do
    local pf = _list_0[_index_0]
    nf.register({
      pf = pf,
      hooknum = nf.inet_hooks.FORWARD,
      priority = nf.ip_priority.FILTER,
      hook = hook
    })
  end
end
