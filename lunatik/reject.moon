cfg = require"captive.cfg"
thread = require"thread"
linux = require"linux"
mail = require"mailbox"
eth = require"ipparse.l2.ethernet"
ip  = require"ipparse.l3.ip"
tcp = require"ipparse.l4.tcp"
skt = require"socket"
ETH_P_ALL, IFACE = 0x0003, linux.ifindex cfg.iface


->
  from_hook = mail.inbox "captive_reject", false
  raw = skt.new skt.af.PACKET, skt.sock.RAW, ETH_P_ALL
  reject = =>
    l2, l3_off = eth.parse @
    l3 = ip.parse @, l3_off, l2.protocol
    return nil if l3.protocol ~= ip.proto.TCP
    l4 = tcp.parse @, l3.data_off
    l2.dst, l2.src, l2.data = l2.src, l2.dst, l3
    l3.src, l3.dst, l3.data = l3.dst, l3.src, l4
    seq, ack = l4.ack_n, l4.seq_n + 1
    l4.spt, l4.dpt, l4.seq_n, l4.ack_n = l4.dpt, l4.spt, seq, ack
    l4.ack = true
    l4.rst = true
    resp = "#{l2}"
    raw\send resp, IFACE
  
  while not thread.shouldstop!
    xpcall (->
      while not thread.shouldstop!
        if pkt = from_hook\receive!
          reject pkt
        else
          linux.schedule 1
    ), =>
      print "CAPTIVE reject ERROR: #{@}"
      print debug.traceback!
