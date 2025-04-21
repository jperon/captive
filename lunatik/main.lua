local rcu = require("rcu")
local runner = rcu and require("lunatik.runner")
local thread = require("thread")
local linux = require("linux")
return function()
  runner.spawn("captive/redirect")
  runner.spawn("captive/reject")
  runner.spawn("captive/dev")
  local hook = runner.run("captive/hook", false)
  hook:resume()
  while not thread.shouldstop() do
    linux.schedule(1000)
  end
end
