rcu = require"rcu"
runner = rcu and require"lunatik.runner"
thread = require"thread"
linux = require"linux"

->
  runner.spawn "captive/redirect"
  runner.spawn "captive/reject"
  runner.spawn "captive/dev"
  hook = runner.run "captive/hook", false
  hook\resume!

  while not thread.shouldstop!
    linux.schedule 1000