enet = require 'enet'
inspect = require 'inspect'

host = nil
peer = nil

local tick = 0.016
local timer = 0
local keys = {}
local event

local DT = 0
-- rdt is the time since the last 1/60 tick.
local rdt = 0

local state = {}
local currentState
local readyFlag = false

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
  local result = {}

  for token in string.gmatch(str, '[^,]+') do
    table.insert(result, token)
  end

  return result
end

local function interpolate (rdt, stateOne, stateTwo)
  local x1 = stateOne[1]
  local y1 = stateOne[2]
  local x2 = stateTwo[1]
  local y2 = stateTwo[2]
  local x = x1 + ((x2 - x1) * (rdt/tick))
  local y = y1 + (x - x1) * ((y2 - y1) / (x2 - x1))

  local result = { x, y }

  if stateOne[3] then
    x1 = stateOne[3]
    y1 = stateOne[4]
    x2 = stateTwo[3]
    y2 = stateTwo[4]
    x = x1 + ((x2 - x1) * (rdt/tick))
    y = y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
    table.insert(result, x)
    table.insert(result, y)
  end

  return result
end

function love.load(args)
	-- establish a connection to host on same PC
	host = enet.host_create()
  peer = host:connect("localhost:3000")
  -- peer = host:connect("159.223.99.80:2555")
end

function love.update(dt)
  DT = DT + dt

  if love.keyboard.isDown('up') then table.insert(keys, 'up') end
  if love.keyboard.isDown('down') then table.insert(keys, 'down') end
  if love.keyboard.isDown('left') then table.insert(keys, 'left') end
  if love.keyboard.isDown('right') then table.insert(keys, 'right') end

  if DT > tick then
    DT = 0
  end
  
  
  local status, error = pcall(function ()
    event = host:service()
  end)
  
  timer = timer + DT
  if timer >= tick then
    timer = 0
    peer:send(join(keys))
    keys = {}
  end

  if readyFlag then
    rdt = rdt + DT

    if rdt >= tick then
      rdt = 0
      table.remove(state, 1)
    end

    if state[1] and state[2] then
      currentState = interpolate(rdt, state[1], state[2])
      -- currentState = state[1]
    end
  end

  if event then
    if event.type == 'receive' then
      table.insert(state, parse(event.data))

      if readyFlag == false and #state >= 3 then
        currentState = state[1]
        readyFlag = true
      end
    end
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255)

  love.graphics.print(peer:round_trip_time(), 10, 10)

  if currentState and currentState[1] then
    love.graphics.rectangle('fill', tonumber(currentState[1]) - 5, tonumber(currentState[2]) - 5, 10, 10)
  end

  if currentState and currentState[3] then
    love.graphics.rectangle('fill', tonumber(currentState[3]) - 5, tonumber(currentState[4]) - 5, 10, 10)
  end
end

function love.quit ()
  peer:disconnect()
end
