local enet = require 'enet'
local TSerial = require 't-serial'

local host = nil
local event = nil
local DT = 0
local tick = 0.0166
local timer = 0
local frame = 1

local state = {
  clients = {},
}

local world
local leftB, rightB, topB, bottomB
local leftS, rightS, topS, bottomS
local leftF, rightF, topF, bottomF

local function createClient ()
  return {
    input = '',
    x = 100,
    y = 100
  }
end

local function contains (tbl, val)
  local result = false

  if type(tbl) == 'table' then
    for i,v in ipairs(tbl) do
      if v == val then
        result = true
        break
      end
    end
  end

  return result
end

local function pack (frm, clients)
  local result = { frame = frm }

  for k,v in pairs(clients) do
    table.insert(result, { v.body:getPosition() })
  end

  return TSerial.pack(result)
end

function love.load (args)
	-- establish host for receiving msg
	host = enet.host_create("localhost:3000")

  world = love.physics.newWorld(0, 0, false)

  leftB = love.physics.newBody(world, 0, 300, 'static')
  rightB = love.physics.newBody(world, 800, 300, 'static')
  topB = love.physics.newBody(world, 400, 0, 'static')
  bottomB = love.physics.newBody(world, 400, 600, 'static')

  leftS = love.physics.newRectangleShape(10, 600)
  rightS = love.physics.newRectangleShape(10, 600)
  topS = love.physics.newRectangleShape(800, 10)
  bottomS = love.physics.newRectangleShape(800, 10)

  leftF = love.physics.newFixture(leftB, leftS)
  rightF = love.physics.newFixture(rightB, rightS)
  topF = love.physics.newFixture(topB, topS)
  bottomF = love.physics.newFixture(bottomB, bottomS)
end

function love.update (dt)
  DT = dt
  timer = timer + DT
  if DT >= tick then DT = tick end
  
  event = host:service(100)
  world:update(DT)

  if event then
    if event.type == "connect" then
      if state.clients[event.peer] == nil then
        state.clients[event.peer] = createClient()
        state.clients[event.peer].body = love.physics.newBody(world, 10, 10, 'dynamic')
        state.clients[event.peer].shape = love.physics.newRectangleShape(10, 10)
        state.clients[event.peer].fixture = love.physics.newFixture(
          state.clients[event.peer].body,
          state.clients[event.peer].shape,
          1
        )

        state.clients[event.peer].body:setFixedRotation(true)
      end
    end

    if event.type == "disconnect" then
      state.clients[event.peer] = nil
    end

    if event.type == "receive" then
      local keys = TSerial.unpack(event.data)
      state.clients[event.peer].input = keys
    end
  end

  for k,v in pairs(state.clients) do
    if contains(v.input, 'up') then
      v.body:applyForce(0, -50)
    end

    if contains(v.input, 'right') then
      v.body:applyForce(50, 0)
    end

    if contains(v.input, 'down') then
      v.body:applyForce(0, 50)
    end

    if contains(v.input, 'left') then
      v.body:applyForce(-50, 0)
    end
  end

  if timer >= tick then
    timer = 0
    host:broadcast(pack(frame, state.clients), 0, 'unreliable')
    frame = frame + 1

    if frame >= 60 then
      frame = 1
    end
  end

  DT = 0
end

function love.draw ()
  local offset = 10

  love.graphics.setColor(255, 255, 255)

  for k,v in pairs(state.clients) do
    if type(v.input) == 'table' then
      love.graphics.print('inputs: ' .. TSerial.pack(v.input), 10, offset)
    end
    offset = offset + 20

    love.graphics.polygon('fill', v.body:getWorldPoints(v.shape:getPoints()))
  end

  love.graphics.polygon('fill', leftB:getWorldPoints(leftS:getPoints()))
  love.graphics.polygon('fill', rightB:getWorldPoints(rightS:getPoints()))
  love.graphics.polygon('fill', topB:getWorldPoints(topS:getPoints()))
  love.graphics.polygon('fill', bottomB:getWorldPoints(bottomS:getPoints()))
end

function love.quit ()
  host:destroy()
end
