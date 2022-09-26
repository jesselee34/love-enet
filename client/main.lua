enet = require "enet"

host = nil
peer = nil

local tick = 0.015
local timer = 0
local key = ''
local event

function love.load(args)
	-- establish a connection to host on same PC
	host = enet.host_create()
  peer = host:connect("localhost:3000")
end

function love.update(dt)
  timer = timer + dt
  event = host:service()

  if timer >= tick then
    timer = 0
    peer:send(key)
  end

  if event then
    if event.type == 'recieve' then
      print('Recieved: ', event.data)
    end
  end

  key = ''
end

function love.draw ()
end

function love.quit ()
  peer:disconnect()
  client:flush()
end

function love.keypressed (k)
  key = k
end