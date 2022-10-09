local enet = require 'enet'
local TSerial = require 't-serial'

local host = nil
local peer = nil
local tick = 0.0166
local timer = 0
local keys = {}
local event

local DT = 0
-- rdt is the time since the last 1/60 tick.
local rdt = 0

local state = {}
local currentState
local readyFlag = false

local function interpolate (rdt, stateOne, stateTwo)  
  local x, y, x1, x2, y1, y2, deltaX, deltaY
  local result = {}
  
  for i=1,#stateOne,1 do
    x1 = math.floor(stateOne[i][1])
    y1 = math.floor(stateOne[i][2])
    x2 = math.floor(stateTwo[i][1])
    y2 = math.floor(stateTwo[i][2])
  
    deltaY = y2 - y1
    deltaX = x2 - x1
  
    if deltaY == 0 and deltaX == 0 then
      x = x1
      y = y1
    elseif deltaY == 0 then
      y = y1
      x = math.floor(x1 + ((x2 - x1) * (rdt/tick)))
    elseif deltaX == 0 then
      x = x1
      y = math.floor(y1 + (y2 - y1) * (rdt/tick))
    else
      x = math.floor(x1 + ((x2 - x1) * (rdt/tick)))
      y = math.floor(y1 + (x - x1) * ((y2 - y1) / (x2 - x1)))
    end

    table.insert(result, { x, y })
    -- print('x1: ' .. x1 .. ', y1: ' .. y1 .. ', x2: ' .. x2 .. ', y2: ' .. y2 .. ', x: ' .. x .. ', y: ' .. y )
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
  DT = dt
  if DT > tick then DT = tick end

  if love.keyboard.isDown('up') then table.insert(keys, 'up') end
  if love.keyboard.isDown('down') then table.insert(keys, 'down') end
  if love.keyboard.isDown('left') then table.insert(keys, 'left') end
  if love.keyboard.isDown('right') then table.insert(keys, 'right') end

  timer = timer + DT
  if timer >= tick then
    timer = 0
    peer:send(TSerial.pack(keys))
    keys = {}
  end

  local status, error = pcall(function ()
    event = host:service()
  end)

  if event then
    if event.type == 'receive' then
      table.insert(state, TSerial.unpack(event.data))
    end
  end

  if #state >= 4 then    
    -- If we're ever 16 frames behind, catch up.
    if #state >= 16 then
      for i=1,#state - 4,1 do
        table.remove(state, 1)
      end
    end

    currentState = interpolate(rdt, state[1], state[2])

    rdt = rdt + DT
    if rdt >= tick then
      rdt = 0
      table.remove(state, 1)
    end
  end

  DT = 0
end

function love.draw ()
  love.graphics.setColor(255, 255, 255)

  love.graphics.print(peer:round_trip_time(), 10, 10)

  if currentState then
    for i=1,#currentState,1 do
      love.graphics.rectangle('fill', tonumber(currentState[i][1]) - 5, tonumber(currentState[i][2]) - 5, 10, 10)
    end
  end
end

function love.quit ()
  peer:disconnect()
end
