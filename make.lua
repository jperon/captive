local arg = arg
local usage = "Usage: " .. tostring(arg[0]) .. " all root@openwrt [/www/lua] [/lib/modules/lua]"
local UHTTPD_LUA_DIR = "/www/lua"
local LUNATIK_DIR = "/lib/modules/lua"
local LUNATIK_SUBDIR = "captive"
local SCP = "scp -O"
local execute
execute = os.execute
local remove
remove = table.remove
local unpack = unpack or table.unpack
local compile_moonscript
compile_moonscript = function()
  print("---------------- Compiling moonscript files… ----------------")
  return execute("moonc `find . -name \\*.moon`")
end
local install_uhttpd
install_uhttpd = function(self, dir)
  if dir == nil then
    dir = UHTTPD_LUA_DIR
  end
  print("---------------- Installing uhttpd_lua files… ---------------")
  execute("ssh " .. tostring(self) .. " mkdir -p " .. tostring(dir))
  return execute("cd uhttpd_lua && " .. tostring(SCP) .. " -r * .* " .. tostring(self) .. ":" .. tostring(dir) .. "/ 2>/dev/null")
end
local install_lunatik
install_lunatik = function(self, dir)
  if dir == nil then
    dir = LUNATIK_DIR
  end
  print("---------------- Installing lunatik files… ------------------")
  execute("ssh " .. tostring(self) .. " mkdir -p " .. tostring(dir) .. "/" .. tostring(LUNATIK_SUBDIR))
  return execute("cd lunatik && " .. tostring(SCP) .. " * .* " .. tostring(self) .. ":" .. tostring(dir) .. "/" .. tostring(LUNATIK_SUBDIR) .. "/ 2>/dev/null")
end
local install_service
install_service = function(self)
  print("---------------- Installing init.d files… -------------------")
  execute(tostring(SCP) .. " init.d/captive " .. tostring(self) .. ":/etc/init.d/")
  execute(tostring(SCP) .. " init.d/captive_nft " .. tostring(self) .. ":/etc/init.d/")
  execute("ssh " .. tostring(self) .. " chmod +x /etc/init.d/*")
  return execute(tostring(SCP) .. " init.d/usr_bin_captive_nft.lua " .. tostring(self) .. ":/usr/bin/captive_nft.lua")
end
local install_luci
install_luci = function(self)
  print("---------------- Installing luci files… ---------------------")
  execute("coffee -bc luci-app-captive/htdocs/luci-static/resources/view/captive/form.coffee")
  execute("cd luci-app-captive/root && " .. tostring(SCP) .. " -r * " .. tostring(self) .. ":/")
  return execute("cd luci-app-captive/htdocs && " .. tostring(SCP) .. " -r * " .. tostring(self) .. ":/www/")
end
local install_default_config
install_default_config = function(self)
  print("---------------- (Re)setting config… ------------------------")
  execute(tostring(SCP) .. " luci-app-captive/root/etc/uci-defaults/80_captive " .. tostring(self) .. ":/etc/uci-defaults/")
  return execute("ssh " .. tostring(self) .. " sh /etc/uci-defaults/80_captive")
end
local all
all = function(self, uhttpd_lua_dir, lunatik_dir)
  if uhttpd_lua_dir == nil then
    uhttpd_lua_dir = UHTTPD_LUA_DIR
  end
  if lunatik_dir == nil then
    lunatik_dir = LUNATIK_DIR
  end
  compile_moonscript()
  install_uhttpd(self, uhttpd_lua_dir)
  install_lunatik(self, lunatik_dir)
  return install_service(self)
end
local f = {
  all = all,
  compile_moonscript = compile_moonscript,
  install_uhttpd = install_uhttpd,
  install_lunatik = install_lunatik,
  install_luci = install_luci,
  install_default_config = install_default_config
}
local action = #arg > 1 and remove(arg, 1) or "all"
assert(arg[1]:match("@"), "Missing destination. " .. tostring(usage))
return f[action](unpack(arg))
