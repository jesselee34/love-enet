enet = require 'enet'
inspect = require 'inspect'

host = nil
peer = nil

local tick = 0.015
local timer = 0
local keys = {}
local event

local DT = 0
-- rdt is the time since the last 1/60 tick.
local rdt = 0

local state = {}
local currentState

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

local function interpolate (rdt, pt1, pt2)
  local x1 = pt1[1]
  local y1 = pt1[2]
  local x2 = pt2[1]
  local y2 = pt2[2]
  local x = (x1 - x2) * (rdt/(1/60))
  local y = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)

  return { x, y }
end

function love.load(args)
	-- establish a connection to host on same PC
	host = enet.host_create()
  peer = host:connect("localhost:3000")
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
  
  local status, error = pcall(function ()
    event = host:service()
  end)

  if timer >= tick then
    timer = 0
    peer:send(join(keys))
    keys = {}
  end

  if currentState then
    rdt = rdt + DT

    if rdt >= 1/60 then
      rdt = 1/60 - rdt
      table.remove(state, 1)
    end

    -- TODO: Make sure state[2] exists need to pause

    currentState = interpolate(rdt, state[1], state[2])
  end

  if event then
    if event.type == 'receive' then
      table.insert(state, parse(event.data))

      if #state >= 4 then
        currentState = state[1]
      end
    end
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255)

  love.graphics.print(peer:round_trip_time(), 0, 0)

  if currentState and currentState[1] then
    love.graphics.rectangle('fill', tonumber(currentState[1]), tonumber(currentState[2]), 10, 10)
  end

  if currentState and currentState[3] then
    love.graphics.rectangle('fill', tonumber(currentState[3]), tonumber(currentState[4]), 10, 10)
  end
end

function love.quit ()
  peer:disconnect()
end
