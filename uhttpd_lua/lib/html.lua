local concat, remove
do
  local _obj_0 = table
  concat, remove = _obj_0.concat, _obj_0.remove
end
local html = {
  __index = function(self, k)
    return function(...)
      local ct, props = { }, { }
      for i = 1, select('#', ...) do
        local arg = select(i, ...)
        local _exp_0 = type(arg)
        if "table" == _exp_0 then
          while #arg > 0 do
            ct[#ct + 1] = remove(arg, 1)
          end
          for _k, _v in pairs(arg) do
            props[#props + 1] = " " .. tostring(_k) .. "=\"" .. tostring(_v) .. "\""
          end
        elseif "function" == _exp_0 then
          ct[#ct + 1] = arg()
        elseif ("string" or "number") == _exp_0 then
          ct[#ct + 1] = arg
        end
      end
      return #ct == 0 and "<" .. tostring(k) .. tostring(concat(props)) .. "/>" or "<" .. tostring(k) .. tostring(concat(props)) .. ">" .. tostring(concat(ct, '\n')) .. "</" .. tostring(k) .. ">"
    end
  end
}
return setmetatable(html, html)
