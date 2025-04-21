#!/usr/bin/env moon

arg = arg
usage = "Usage: #{arg[0]} all root@openwrt [/www/lua] [/lib/modules/lua]"

UHTTPD_LUA_DIR = "/www/lua"
LUNATIK_DIR = "/lib/modules/lua"
LUNATIK_SUBDIR = "captive"
SCP = "scp -O"

:execute = os
:remove = table
unpack or= table.unpack

compile_moonscript = ->
  print"---------------- Compiling moonscript files… ----------------"
  execute"moonc `find . -name \\*.moon`"

install_uhttpd = (dir=UHTTPD_LUA_DIR) =>
  print"---------------- Installing uhttpd_lua files… ---------------"
  execute"ssh #{@} mkdir -p #{dir}"
  execute"cd uhttpd_lua && #{SCP} -r * .* #{@}:#{dir}/ 2>/dev/null"

install_lunatik = (dir=LUNATIK_DIR) =>
  print"---------------- Installing lunatik files… ------------------"
  execute"ssh #{@} mkdir -p #{dir}/#{LUNATIK_SUBDIR}"
  execute"cd lunatik && #{SCP} * .* #{@}:#{dir}/#{LUNATIK_SUBDIR}/ 2>/dev/null"

install_luci = =>
  print"---------------- Installing luci files… ---------------------"
  execute"coffee -bc luci-app-captive/htdocs/luci-static/resources/view/captive/form.coffee"
  execute"cd luci-app-captive/root && #{SCP} -r * #{@}:/"
  execute"cd luci-app-captive/htdocs && #{SCP} -r * #{@}:/www/"

install_default_config = =>
  print"---------------- (Re)setting config… ------------------------"
  execute"#{SCP} luci-app-captive/root/etc/uci-defaults/80_captive #{@}:/etc/uci-defaults/"
  execute"ssh #{@} sh /etc/uci-defaults/80_captive"

all = (uhttpd_lua_dir=UHTTPD_LUA_DIR, lunatik_dir=LUNATIK_DIR) =>
  compile_moonscript!
  install_uhttpd @, uhttpd_lua_dir
  install_lunatik @, lunatik_dir

f = :all, :compile_moonscript, :install_uhttpd, :install_lunatik, :install_luci, :install_default_config

action = #arg > 1 and remove(arg, 1) or "all"
assert arg[1]\match"@", "Missing destination. #{usage}"
f[action] unpack arg
