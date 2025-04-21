local DEBUG
--DEBUG = "/tmp/uhttpd_lua.log"
dir = debug.getinfo(1, "S").source\sub(2)\match"(.*)/" or "."
package.path = package.path .. ";#{dir}/?.lua;#{dir}/?/init.lua;#{dir}/lib/?.lua;#{dir}/lib/?/init.lua"
uhttpd = assert uhttpd, "Only suitable with uhttpd"
:recv, :send = uhttpd
html = require"html"
:concat = table
:open, :popen = io
log = (...) -> if DEBUG
  with open DEBUG, "a"
    \write concat(["#{i}" for i in *{...}], " ") .. "\n\n"
    \close!

if DEBUG
  with open DEBUG, "w"
    \write""
    \close!
  _send = send
  send = (...) ->
    log ...
    _send ...

read = (what="*a")=> if @
  ret = @read what
  @close! and ret


export handle_request = =>
  local params, data
  params = { k, v for k, v in @QUERY_STRING\gmatch"([^&=]+)=?([^&]*)"}
  if data = select 2, recv!
    data = {k, v for k, v in data\gmatch"([^&=]+)=?([^&]*)"}
  else data = {}

  if @PATH_INFO and @PATH_INFO ~= "/"
    require(@PATH_INFO\gsub "/$", "") @, params, data

  else
    with html
      send "Status: 200 OK\nContent-Type: text/html\n\n\n<!DOCTYPE html>\n" .. .html(
        .head(
          .title"uhttpd lua"
          .meta charset:"utf-8"
          .meta name:"viewport", content:"width=device-width, initial-scale=1"
          .meta name:"color-scheme", content:"dark"
        )
        .body [ .a href:"./#{u}", u for u in read(
          popen"find #{dir} -type d -maxdepth 1"
        )\gmatch"#{dir}/(%w+)" when u ~= "lib" and u\sub(1, 1) ~= "." ]
      )

  if DEBUG
    with html
      send .footer .script(
        "console.log('\\n\\n\\nENV')"
        concat ["console.log('#{k}', '#{v}')" for k, v in pairs @], "\n"
        "console.log('\\n\\n\\nHEADERS')"
        concat ["console.log('#{k}', '#{v}')" for k, v in pairs @headers], "\n"
      ) or ""
