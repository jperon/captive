local schedule
schedule = require("linux").schedule
local shouldstop
shouldstop = require("thread").shouldstop
local outbox
outbox = require("mailbox").outbox
return function(queue)
  local box = outbox("my_test_msgbox", false)
  while not shouldstop() do
    schedule(2000)
    xpcall((function()
      return box:send("essai")
    end), function(self)
      return print(self)
    end)
  end
end
