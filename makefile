ifeq ($(OS), Windows_NT)
SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -Command
endif

build:
	cp lib/t-serial/init.lua server/t-serial.lua
	cp lib/t-serial/init.lua client/t-serial.lua

host:
	love ./server

local:
	love ./client
