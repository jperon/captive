cfg = require"captive.cfg"
thread = require"thread"
--:hexdump = require"ipparse"
:bidirectional = require"ipparse.fun"
eth = require"ipparse.l2.ethernet"
ip  = require"ipparse.l3.ip"
tcp = require"ipparse.l4.tcp"
linux = require"linux"
skt = require"socket"
ETH_P_ALL, IFACE = 0x0003, linux.ifindex cfg.iface
mail = require"mailbox"

errno = bidirectional {k, v for k, v in pairs linux.errno}


->
  from_hook = mail.inbox "captive_redirect", false
  raw = skt.new skt.af.PACKET, skt.sock.RAW, ETH_P_ALL
  cfg.code or= "302 Found"
  http_reply = "HTTP/1.1 #{cfg.code}\nLocation: #{cfg.url}\nConnection: close\n"
  while not thread.shouldstop!
    xpcall (->
      while not thread.shouldstop!
        if pkt = from_hook\receive!
          l2 = eth.parse pkt
          l3 = ip.parse pkt, l2.data_off
          l4 = tcp.parse pkt, l3.data_off

          l2.src, l2.dst, l2.data = l2.dst, l2.src, l3
          l3.src, l3.dst, l3.data = l3.dst, l3.src, l4
          seq, ack = l4.ack_n, l4.seq_n + #pkt - l4.data_off
          l4.spt, l4.dpt, l4.seq_n, l4.ack_n, l4.fin  = l4.dpt, l4.spt, seq, ack, true

          l4.data = http_reply
          redirect = "#{l2}"
          print "Redirect #{eth.mac2s l2.src}"
          raw\send redirect, IFACE
        else
          linux.schedule 100
    ), =>
      print "CAPTIVE redirect ERROR: #{errno[@] or @}"
      print debug.traceback!
