DEBUG = false
script_path = debug.getinfo(1, "S").source\sub(2)\match"(.*)/" or "."
package.path ..= ";#{script_path}/lib/?.lua;#{script_path}/lib/?/init.lua"

uhttpd = assert uhttpd
:send = uhttpd
html = require"html"
:decode, :encode = require"base64"
:execute, :date, :time = os
:open, :popen, :stderr = io
:concat = table

read = (what="*a")=> if @
  ret = @read what
  @close! and ret
uci_get = (config="captive") => read(popen"uci get #{config}.#{@}")\sub 1, -2

USERS = {u, h for u, h in uci_get"users.users"\gmatch"(%S+):(%S+)"}
CSS = uci_get"common.css"
DAY_BEGIN = uci_get"common.day_begin"
DAY_END = uci_get"common.day_end"
MODE = uci_get"common.mode"
AUTHENTICATED = "/tmp/.captive_portal_authenticated"

:validate = require"htpasswd" USERS

log = (...) -> if DEBUG then stderr\write(concat(["#{i}" for i in *{...}], " ") .. "\n")

wrap = (msg) =>
  if DEBUG
    (...) ->
      log msg, ...
      @ ...
  else @

execute = wrap execute, "EXECUTE"
send = wrap send, "SEND"

open_access = ({
  lunatik: => with open "/dev/captive", "w"
    \write "+ #{@}"
    \close!
  nft: =>
    execute"nft -f - <<EOF
      add element inet captive captive_auth { #{@} }
      delete element inet captive captive_auth { #{@} }
      add element inet captive captive_auth { #{@} }
      EOF
    "
})[MODE]

close_access = ({
  lunatik: => with open "/dev/captive", "w"
    \write "- #{@}"
    \close!
  nft: =>
    execute"nft -f - <<EOF
      add element inet captive captive_auth { #{@} }
      delete element inet captive captive_auth { #{@} }
      EOF
    "
})[MODE]

(params, data) =>
  authenticated = if txt = read open AUTHENTICATED
    {cookie, t for cookie, t in txt\gmatch"([^%s:]+):(%S+)"}
  else {}
  ip = @REMOTE_HOST
  log "IP", ip
  mac = read(popen"ip neigh")\match"#{ip}%sdev%s.-lladdr%s([^\n%s]+)"
  log "MAC", mac
  cookie = if cookies = @headers.cookie
    if auth = cookies\match"auth=([^;]+)"
      if t = authenticated[auth]
        if not params.logout and time! < tonumber(t) and mac == decode(auth)\match"[^|]+|([^|]+)|[^|]+"
          auth
        else
          authenticated[auth] = nil
  cookie or= if data.usr
    if usr = validate data.usr, data.pwd
      t = time! + 3600
      c = encode "#{usr}|#{mac}|#{t}"
      authenticated[c] = t
      c
      
  hour = date"%H:%M"
  night = if DAY_END <= hour or hour < DAY_BEGIN
    "Internet est bloqué de #{DAY_BEGIN} à #{DAY_END}."
  with html
    send "Status: 200 OK\nContent-Type: text/html\n#{cookie and "Set-Cookie: auth=#{cookie}; Max-Age: 3600" or ''}\n\n<!DOCTYPE html>" .. .html(
      lang:"fr"
      .head
        .meta charset:"utf-8"
        .meta name:"viewport", content:"width=device-width,initial-scale=1"
        cookie and .meta "http-equiv":"refresh", content:"30"
        .style read(open CSS) or ""
      cookie and .body(
        .p "Connecté"
        .p "Fermer cet onglet vous déconnectera ; il faudra alors fermer et rouvrir votre navigateur pour vous reconnecter."
        night and .p night or ""
        .p .a href:"?logout=true", "Déconnexion"
        .p style:"text-align:right", .small .a href:"#{@REQUEST_URI}/users"\gsub("//", "/"), "Gestion des utilisateurs"
      ) or .body .main .form(
        method:"POST"
        action: @REQUEST_URI\gsub "logout=[^&]+", ""
        .fieldset(
          .legend "Authentification"
          .input name:"usr", type:"text"
          .input name:"pwd", type:"password"
          .button "OK"
        )
      )
      cookie and night and .script"window.alert('#{night}')"
    )
  
  if cookie
    open_access mac
  else
    close_access mac

  if f = open AUTHENTICATED, "w"
    f\write concat ["#{u}:#{c}\n" for u, c in pairs authenticated when u]
    f\close!
