arg = arg
{IFACE, ADDR, PORT, URL, BEGIN, END} = arg
BEGIN = nil if BEGIN == ""
END = nil if END == ""
NFT = "/tmp/.captive.nft"
:tcp = require"socket"
:execute, :exit = os
:open = io

accept_open = "iifname \"#{IFACE}\" %s ether saddr @captive_auth accept comment Captive_portal_open"\format(
  BEGIN and END and "hour \"#{BEGIN}\" - \"#{END}\"" or ""
)

with open NFT, "w"
  \write"
    table inet captive
    delete table inet captive
    table inet captive {
      set captive_auth {
        type ether_addr; timeout 60s;
      }
      chain input_lan {
        type filter hook input priority filter; policy accept;
        tcp dport {80, 443} accept comment Captive_portal
      }
      chain forward_lan {
        type filter hook forward priority filter; policy accept;
        ct state vmap { established : accept, related : accept }
        #{accept_open}
        iifname \"#{IFACE}\" meta l4proto tcp reject with tcp reset comment Captive_portal_closed
        iifname \"#{IFACE}\" meta l4proto != { icmp, icmpv6 } reject comment Captive_portal_closed
      }
      chain dstnat_lan {
        type nat hook prerouting priority dstnat; policy accept;
        ct state vmap { established : accept, related : accept }
        ether saddr @captive_auth accept
        tcp dport 80 redirect to 80 comment Captive_portal_redirection
      }
    }
  "
  \close!

execute "nft -f #{NFT}"

ok, err = pcall ->
  print"Launching redirection to captive portal on #{ADDR}:#{PORT}"
  server = with assert tcp!
    \bind ADDR, PORT
    \listen!
  
  while true
    client, err = server\accept!
    if client
      _, err = client\receive!
      client\send"HTTP/1.1 307 Temporary Redirect\nLocation: #{URL}\nContent-Length: 0\n\n" if not err
    else
      print err
      server\close!
      break

print err if not ok
exit 1
