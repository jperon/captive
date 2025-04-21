:execute, :time = os
:open, :popen = io
:concat, :sort = table
:decode = require"base64"

read = (what="*a")=> if @
  ret = @read what
  @close! and ret

opairs = (f) =>
  i, keys = 0, [k for k in pairs @]
  sort keys, f
  ->
    i += 1
    k = keys[i]
    k, @[k]

=>
  users = @ if type(@) == "table"
  htpasswd = @ if type(@) == "string"
  if htpasswd
    if txt = read assert open htpasswd
      users = {u, h for u, h in txt\gmatch"(%S+):(%S+)"}
  
  adduser = (pwd) =>
    return nil, "No username given" if not @
    tmp = "/tmp/.htpwd_#{time!}.tmp"
    with popen "openssl passwd -apr1 -stdin > #{tmp}", "w"
      \write pwd
      \close!
    users[@] = read(open tmp)\sub 1, -2
    execute"rm #{tmp}"
    if htpasswd
      if out = assert open htpasswd, "w"
        out\write concat ["#{u}:#{h}\n" for u, h in opairs users]
        out\close!
        return @
      return nil, "Couldn’t write into #{htpasswd}"
    @
    

  validate = (pwd) =>
    return nil, "No username given" if not @
    h = users[@]
    return nil, "Invalid user" if not h
    a, s = h\match"$(%S+)$(%S+)$%S+"
    tmp = "/tmp/.htpwd_#{time!}.tmp"
    with popen "openssl passwd -#{a} -salt #{s} -stdin > #{tmp}", "w"
      \write pwd
      \close!
    _h = read(open tmp)\sub 1, #h
    execute"rm #{tmp}"
    return nil, "Bad password" if h ~= _h
    @
  
  validate_b64 = =>
    usr, pwd = decode(@)\match"([^%s:]+):(%S+)"
    validate usr, pwd
    
  :validate, :validate_b64, :adduser, :users