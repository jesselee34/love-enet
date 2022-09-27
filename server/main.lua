enet = require 'enet'
local inspect = require 'inspect'

local host = nil
local event = nil

local state = {
  clients = {},
}

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

  for k,v in pairs(tbl) do
    len = len + 1
  end

  for k,v in pairs(tbl) do
    i = i + 1

    if i == len then
      result = result .. v.x .. ',' .. v.y
    else
      
      result = result .. v.x .. ',' .. v.y .. ','
    end
  end

  return result
end

function love.load (args)
	-- establish host for receiving msg
	host = enet.host_create("localhost:3000")
end

function love.update ()
  event = host:service(100)

  if event then
    if event.type == "connect" then
      if state.clients[event.peer] == nil then
        state.clients[event.peer] = createClient()
      end
    end

    if event.type == "receive" then
      local keys = parse(event.data)
      state.clients[event.peer].input = event.data
      
      if contains(keys, 'up') then
        state.clients[event.peer].y = state.clients[event.peer].y - 10
      end

      if contains(keys, 'right') then
        state.clients[event.peer].x = state.clients[event.peer].x + 10
      end

      if contains(keys, 'down') then
        state.clients[event.peer].y = state.clients[event.peer].y + 10
      end

      if contains(keys, 'left') then
        state.clients[event.peer].x = state.clients[event.peer].x - 10
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
