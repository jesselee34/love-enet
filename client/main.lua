enet = require 'enet'
inspect = require 'inspect'

host = nil
peer = nil

local tick = 0.015
local timer = 0
local keys = {}
local event

local DT = 0

local state = {100, 100}

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

function love.load(args)
	-- establish a connection to host on same PC
	host = enet.host_create()
  peer = host:connect("localhost:3000")
end

function love.update(dt)
  DT = DT + dt

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
    end
  end
end

function love.draw ()
  love.graphics.setColor(255, 255, 255)

  love.graphics.print(peer:round_trip_time(), 0, 0)

  if state[1] then
    love.graphics.rectangle('fill', tonumber(state[1]), tonumber(state[2]), 10, 10)
  end

  if state[3] then
    love.graphics.rectangle('fill', tonumber(state[3]), tonumber(state[4]), 10, 10)
  end
end

function love.quit ()
  peer:disconnect()
end

function love.keypressed (k)
  table.insert(keys, k)
end