:schedule = require"linux"
:shouldstop = require"thread"
:outbox = require"mailbox"

(queue) ->
  box = outbox "my_test_msgbox", false
  while not shouldstop!
    schedule 2000
    xpcall (-> box\send "essai"), => print @
