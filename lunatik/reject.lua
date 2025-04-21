local cfg = require("captive.cfg")
local thread = require("thread")
local linux = require("linux")
local mail = require("mailbox")
local eth = require("ipparse.l2.ethernet")
local ip = require("ipparse.l3.ip")
local tcp = require("ipparse.l4.tcp")
local skt = require("socket")
local ETH_P_ALL, IFACE = 0x0003, linux.ifindex(cfg.iface)
return function()
  local from_hook = mail.inbox("captive_reject", false)
  local raw = skt.new(skt.af.PACKET, skt.sock.RAW, ETH_P_ALL)
  local reject
  reject = function(self)
    local l2, l3_off = eth.parse(self)
    local l3 = ip.parse(self, l3_off, l2.protocol)
    if l3.protocol ~= ip.proto.TCP then
      return nil
    end
    local l4 = tcp.parse(self, l3.data_off)
    l2.dst, l2.src, l2.data = l2.src, l2.dst, l3
    l3.src, l3.dst, l3.data = l3.dst, l3.src, l4
    local seq, ack = l4.ack_n, l4.seq_n + 1
    l4.spt, l4.dpt, l4.seq_n, l4.ack_n = l4.dpt, l4.spt, seq, ack
    l4.ack = true
    l4.rst = true
    local resp = tostring(l2)
    return raw:send(resp, IFACE)
  end
  while not thread.shouldstop() do
    xpcall((function()
      while not thread.shouldstop() do
        do
          local pkt = from_hook:receive()
          if pkt then
            reject(pkt)
          else
            linux.schedule(1)
          end
        end
      end
    end), function(self)
      print("CAPTIVE reject ERROR: " .. tostring(self))
      return print(debug.traceback())
    end)
  end
end
