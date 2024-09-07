--!strict

local port = {}

local runService = game:GetService("RunService")

local server_ports = {}

function port:Connect(func: (...any) -> nil)
	assert(type(func) == "function", "[SwiftPort] - Attempt to connect non-function to a Port")

	local stored_func = func

	table.insert(self._connections,stored_func)
	
	local disconnect = function()
		table.remove(self._connections,table.find(self._connections,stored_func))
	end

	return disconnect
end

function port:FireAll(...)
	table.insert(self._send_queue, {
		target = nil,
		method = "fireall",
		data = ...
	})
end

function port:FireTarget(targest: Player, ...)
	table.insert(self._send_queue, {
		target = targest,
		method = "firetarget",
		data = ...
	})
end

function port:Init()
	local remoteevent = script.Parent.EventManager
	
	remoteevent.OnServerEvent:Connect(function(plr, portname, a)
		--here 
		if portname == self._name then
			table.insert(self._receive_queue,{
				sender = plr,
				data = a
			})
		end
	end)
	
	runService.Heartbeat:Connect(function()

		for i, v in pairs(self._receive_queue) do
			for i, connection in pairs(self._connections) do
				connection(v.sender, table.unpack(v.data))
			end
			table.remove(self._receive_queue,table.find(self._receive_queue,v))
		end

		--sending queue
		for i, v in pairs(self._send_queue) do
			if v.method == "fireall" then
				remoteevent:FireAllClients(self._name, v.data)
			elseif v.method == "firetarget" then
				remoteevent:FireClient(v.target,self._name, v.data)
			end
			table.remove(self._send_queue,table.find(self._send_queue,v))
		end
	end)
end

function port:OpenPort(name: string)
	assert(type(name) == "string", "[SwiftPort] - Port names must be a string")
	
	local found = server_ports[name]
	if found then
		return found
	end
	
	o = {}
	setmetatable(o, self)
	self.__index = self

	self._name = name
	
	self._connections = {}
	
	self._send_queue = {}
	self._receive_queue = {}
	
	
	
	server_ports[self._name] = self
	
	getmetatable(o):Init()
	
	return getmetatable(o)
end

return port

