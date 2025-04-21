:concat, :remove = table

html = __index: (k) => (...) ->
  ct, props = {}, {}
  for i = 1, select '#', ...
    arg = select i, ...
    switch type arg
      when "table"
        while #arg > 0
          ct[#ct+1] = remove arg, 1
        props[#props+1] = " #{_k}=\"#{_v}\"" for _k, _v in pairs arg
      when "function"
        ct[#ct+1] = arg!
      when "string" or "number"
        ct[#ct+1] = arg
  #ct == 0 and "<#{k}#{concat props}/>" or "<#{k}#{concat props}>#{concat ct, '\n'}</#{k}>"

setmetatable html, html
