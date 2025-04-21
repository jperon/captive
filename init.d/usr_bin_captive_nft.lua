local arg = arg
local IFACE, ADDR, PORT, URL, BEGIN, END
IFACE, ADDR, PORT, URL, BEGIN, END = arg[1], arg[2], arg[3], arg[4], arg[5], arg[6]
if BEGIN == "" then
  BEGIN = nil
end
if END == "" then
  END = nil
end
local NFT = "/tmp/.captive.nft"
local tcp
tcp = require("socket").tcp
local execute, exit
do
  local _obj_0 = os
  execute, exit = _obj_0.execute, _obj_0.exit
end
local open
open = io.open
local accept_open = ("iifname \"" .. tostring(IFACE) .. "\" %s ether saddr @captive_auth accept comment Captive_portal_open"):format(BEGIN and END and "hour \"" .. tostring(BEGIN) .. "\" - \"" .. tostring(END) .. "\"" or "")
do
  local _with_0 = open(NFT, "w")
  _with_0:write("\n    table inet captive\n    delete table inet captive\n    table inet captive {\n      set captive_auth {\n        type ether_addr; timeout 60s;\n      }\n      chain input_lan {\n        type filter hook input priority filter; policy accept;\n        tcp dport {80, 443} accept comment Captive_portal\n      }\n      chain forward_lan {\n        type filter hook forward priority filter; policy accept;\n        ct state vmap { established : accept, related : accept }\n        " .. tostring(accept_open) .. "\n        iifname \"" .. tostring(IFACE) .. "\" meta l4proto tcp reject with tcp reset comment Captive_portal_closed\n        iifname \"" .. tostring(IFACE) .. "\" meta l4proto != { icmp, icmpv6 } reject comment Captive_portal_closed\n      }\n      chain dstnat_lan {\n        type nat hook prerouting priority dstnat; policy accept;\n        ct state vmap { established : accept, related : accept }\n        ether saddr @captive_auth accept\n        tcp dport 80 redirect to 80 comment Captive_portal_redirection\n      }\n    }\n  ")
  _with_0:close()
end
execute("nft -f " .. tostring(NFT))
local ok, err = pcall(function()
  print("Launching redirection to captive portal on " .. tostring(ADDR) .. ":" .. tostring(PORT))
  local server
  do
    local _with_0 = assert(tcp())
    _with_0:bind(ADDR, PORT)
    _with_0:listen()
    server = _with_0
  end
  while true do
    local client
    client, err = server:accept()
    if client then
      local _
      _, err = client:receive()
      if not err then
        client:send("HTTP/1.1 307 Temporary Redirect\nLocation: " .. tostring(URL) .. "\nContent-Length: 0\n\n")
      end
    else
      print(err)
      server:close()
      break
    end
  end
end)
if not ok then
  print(err)
end
return exit(1)
