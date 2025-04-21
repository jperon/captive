local cfg = require("captive.cfg")
local thread = require("thread")
local bidirectional
bidirectional = require("ipparse.fun").bidirectional
local eth = require("ipparse.l2.ethernet")
local ip = require("ipparse.l3.ip")
local tcp = require("ipparse.l4.tcp")
local linux = require("linux")
local skt = require("socket")
local ETH_P_ALL, IFACE = 0x0003, linux.ifindex(cfg.iface)
local mail = require("mailbox")
local errno = bidirectional((function()
  local _tbl_0 = { }
  for k, v in pairs(linux.errno) do
    _tbl_0[k] = v
  end
  return _tbl_0
end)())
return function()
  local from_hook = mail.inbox("captive_http", false)
  local raw = skt.new(skt.af.PACKET, skt.sock.RAW, ETH_P_ALL)
  cfg.code = cfg.code or "302 Found"
  local http_reply = "HTTP/1.1 " .. tostring(cfg.code) .. "\nLocation: " .. tostring(cfg.url) .. "\nConnection: close\n"
  while not thread.shouldstop() do
    xpcall((function()
      while not thread.shouldstop() do
        do
          local pkt = from_hook:receive()
          if pkt then
            local l2 = eth.parse(pkt)
            local l3 = ip.parse(pkt, l2.data_off)
            local l4 = tcp.parse(pkt, l3.data_off)
            l2.src, l2.dst, l2.data = l2.dst, l2.src, l3
            l3.src, l3.dst, l3.data = l3.dst, l3.src, l4
            local seq, ack = l4.ack_n, l4.seq_n + #pkt - l4.data_off
            l4.spt, l4.dpt, l4.seq_n, l4.ack_n, l4.fin = l4.dpt, l4.spt, seq, ack, true
            l4.data = http_reply
            local redirect = tostring(l2)
            print("Redirect " .. tostring(eth.mac2s(l2.src)))
            raw:send(redirect, IFACE)
          else
            linux.schedule(100)
          end
        end
      end
    end), function(self)
      print("CAPTIVE ERROR: " .. tostring(errno[self] or self))
      return print(debug.traceback())
    end)
  end
end
