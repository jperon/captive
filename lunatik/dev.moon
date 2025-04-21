cfg = require"captive.cfg"
lunatik = require"lunatik"
data = require"data"
rcu = require"rcu"
linux = require"linux"
device = require"device"
eth = require"ipparse.l2.ethernet"
:concat, :sort = table


->
  _true, nop = data.new(1), ->
  env = lunatik._ENV
  env.captive_allowed = rcu.table 2048
  driver =
    name: cfg.device, mode: linux.stat.IRUSR | linux.stat.IWUSR
    open: nop, release: nop
    read: =>
      allowed = {}
      rcu.map env.captive_allowed, => allowed[#allowed+1] = eth.mac2s @
      sort allowed
      concat(allowed, ",") .. "\n"
    write: (s) =>
      op, mac = s\match"([+-])%s*([^\n]+)"
      switch op
        when "+"
          print "CAPTIVE: adding #{mac} to allowed"
          env.captive_allowed[eth.s2mac mac] = _true
        when "-"
          print "CAPTIVE: removing #{mac} from allowed"
          env.captive_allowed[eth.s2mac mac] = nil
        else
          print "CAPTIVE ERROR: malformed entry #{s}"
  device.new driver