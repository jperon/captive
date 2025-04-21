{
  iface: "br-lan"
  url: "https://etude.stemarie.dynv6.net/lua/captive"
  code: "302 Found"
  device: "captive"
  localnets: {
    "127.0.0.0/8"             -- IPv4 loopback
    "192.168.0.0/16"          -- IPv4 private net
    "172.16.0.0/12"           -- IPv4 private net
    "10.0.0.0/8"              -- IPv4 private net
    "169.254.0.0/16"          -- IPv4 link-local
    "224.0.0.0/4"             -- IPv4 multicast
    "::1/128"                 -- IPv6 loopback
    "fc00::/7"                -- IPv6 ULA
    "fe80::/10"               -- IPv6 link-local
    "ff00::/8"                -- IPv6 multicast
    "2001:db8:abcd:1234::/64" -- Replace by local IPv6 range
  }
}
