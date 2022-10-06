enet = require 'enet'
local inspect = require 'inspect'

local host = nil
local event = nil

local state = {
  clients = {},
}

local world

local function parse (str)
  local result = {}

  for token in string.gmatch(str, '[^,]+') do
    table.insert(result, token)
  end

  return result
end

local function createClient ()
  return {
    input = '',
    x = 100,
    y = 100
  }
end

local function contains (tbl, val)
  local result = false

  for i,v in ipairs(tbl) do
    if v == val then
      result = true
      break
    end
  end

  return result
end

local function stringify (tbl)
  local result = ''
  local len = 0
  local i = 0
  local x, y

  for k,v in pairs(tbl) do
    len = len + 1
  end

  for k,v in pairs(tbl) do
    i = i + 1
    x, y = v.body:getPosition()
    vx, vy = v.body:getLinearVelocity()

    if i == len then
      result = result .. x .. ',' .. y .. ',' .. vx .. ',' .. vy
    else
      
      result = result .. x .. ',' .. y .. ',' .. vx .. ',' .. vy .. ','
    end
  end

  return result
end

function love.load (args)
	-- establish host for receiving msg
	host = enet.host_create("localhost:3000")

  world = love.physics.newWorld(0, 0, false)
end

function love.update (dt)
  event = host:service(100)
  world:update(dt)

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
      end
    end

    if event.type == "receive" then
      local keys = parse(event.data)
      state.clients[event.peer].input = event.data
      local vx, vy = state.clients[event.peer].body:getLinearVelocity()
      
      if contains(keys, 'up') then
        if vy > -200 then
          state.clients[event.peer].body:applyForce(0, -50)
        end
      end

      if contains(keys, 'right') then
        if vx < 200 then
          state.clients[event.peer].body:applyForce(50, 0)
        end
      end

      if contains(keys, 'down') then
        if vy < 200 then
          state.clients[event.peer].body:applyForce(0, 50)
        end
      end

      if contains(keys, 'left') then
        if vx > -200 then
          state.clients[event.peer].body:applyForce(-50, 0)
        end
      end
      
      host:broadcast(stringify(state.clients))
    end
  end
end

function love.draw ()
  local offset = 10

  love.graphics.setColor(255, 255, 255)

  for k,v in pairs(state.clients) do
    love.graphics.print('inputs: ' .. v.input, 10, offset)
    offset = offset + 20
  end
end

function love.quit ()
  host:destroy()
end
