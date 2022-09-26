enet = require "enet"
inspect = require 'inspect'

local host = nil
local event = nil
local state = {}

function love.load(args)
	-- establish host for receiving msg
	host = enet.host_create("localhost:3000")
end

function love.update(dt)
  event = host:service(100)

  if event then
    if event.type == "connect" then 
      print(event.peer, "connected.")
    end
    if event.type == "receive" then
      state[event.peer] = event.data
      print('input: ', event.data)
      host:broadcast(inspect(state))
    end
  end
end

function love.quit ()
  host:destroy()
end
