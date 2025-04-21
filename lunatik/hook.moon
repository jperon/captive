cfg = require"captive.cfg"
lunatik = require"lunatik"
nf = require"netfilter"
eth = require"ipparse.l2.ethernet"
ip  = require"ipparse.l3.ip"
tcp = require"ipparse.l4.tcp"
udp = require"ipparse.l4.udp"
mail = require"mailbox"
:any, :map = require"ipparse.fun"

localnets = cfg.localnets and map(cfg.localnets, ip.s2net)\toarray! or {}


->
  env = lunatik._ENV
  to_redirect = mail.outbox "captive_http", false

  hook = =>
    pkt = @getstring 0
    l2 = eth.parse pkt
    l3 = ip.parse pkt, l2.data_off

    l4 = switch l3.protocol
      when ip.proto.UDP
        udp.parse pkt, l3.data_off
      when ip.proto.TCP
        tcp.parse pkt, l3.data_off

    return nf.action.CONTINUE if not l4  -- other protocols than TCP/UDP

    if allowed = env.captive_allowed  -- guard against race conditions
      return nf.action.CONTINUE if allowed[l2.src]

    return nf.action.CONTINUE if any localnets, => ip.contains_ip @, l3.dst

    if l3.protocol == ip.proto.TCP
      return nf.action.CONTINUE if ip.proto.TCP and l4.spt == 80
      to_redirect\send pkt if l4.dpt == 80

    return nf.action.DROP

  for pf in *{nf.family.IPV4, nf.family.IPV6}
    nf.register :pf, hooknum: nf.inet_hooks.FORWARD, priority: nf.ip_priority.FILTER, :hook