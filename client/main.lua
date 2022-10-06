enet = require 'enet'
inspect = require 'inspect'

host = nil
peer = nil

local tick = 0.015
local timer = 0
local keys = {}
local event

local DT = 0

local state = {
  { x = 10, y = 10, vx = 0, vy = 0 }
}

local localState = {}

local world

local function join (tbl)
  local result = ''

  for i, v in ipairs(tbl) do
    if i == table.getn(tbl) then
      result = v
    else
      result = result .. v .. ','
    end
  end

  return result
end

local function parse (str)
  local parsed = {}
  local clients = {}

  for token in string.gmatch(str, '[^,]+') do
    table.insert(parsed, token)
  end


  if parsed[1] then
    table.insert(clients, {
      x = tonumber(parsed[1]),
      y = tonumber(parsed[2]),
      vx = tonumber(parsed[3]),
      vy = tonumber(parsed[4]) 
    })
  end

  if parsed[5] then
    table.insert(clients, {
      x = tonumber(parsed[5]),
      y = tonumber(parsed[6]),
      vx = tonumber(parsed[7]),
      vy = tonumber(parsed[8]) 
    })
  end
  

  return clients
end

function love.load(args)
	-- establish a connection to host on same PC
	host = enet.host_create()
  peer = host:connect("localhost:3000")
  world = love.physics.newWorld(0, 0, false)
end

function love.update(dt)
  DT = DT + dt

  if love.keyboard.isDown('up') then table.insert(keys, 'up') end
  if love.keyboard.isDown('down') then table.insert(keys, 'down') end
  if love.keyboard.isDown('left') then table.insert(keys, 'left') end
  if love.keyboard.isDown('right') then table.insert(keys, 'right') end

  if DT > 1/60 then
    DT = 0
  end
  
  timer = timer + DT
  event = host:service()

  if timer >= tick then
    timer = 0
    peer:send(join(keys))
    keys = {}
  end

  if event then
    if event.type == 'receive' then
      state = parse(event.data)

      for i,v in ipairs(state) do
        if localState[i] == nil then
          local body = love.physics.newBody(world, 0, 0, 'dynamic')
          local shape = love.physics.newRectangleShape(10, 10)
          local fixture = love.physics.newFixture(body, shape, 1)
    
          localState[i] = {
            body = body,
            shape = shape, 
            fixture = fixture
          }
        end
    
        local x,y = localState[i].body:getPosition()
        if math.abs(x - v.x) > 30 or math.abs(y - v.y) > 30 then
          localState[i].body:setPosition(v.x, v.y)
        end

        localState[i].body:setLinearVelocity(v.vx, v.vy)
      end
    end
  end

  world:update(dt)
end

function love.draw ()
  love.graphics.setColor(255, 255, 255)

  love.graphics.print(peer:round_trip_time(), 0, 0)

  if localState[1] then
    local x,y = localState[1].body:getPosition()
    love.graphics.rectangle('fill', x, y, 10, 10)
  end

  if localState[2] then
    local x,y = localState[2].body:getPosition()
    love.graphics.rectangle('fill', x, y, 10, 10)
  end
end

function love.quit ()
  peer:disconnect()
end
