--!strict

local port = {}

local runService = game:GetService("RunService")

local client_ports = {}

function port:Connect(func: (...any) -> nil)
	assert(type(func) == "function", "[SwiftPort] - Attempt to connect non-function to a Port")

	local stored_func = func

	table.insert(self._connections,stored_func)
	
	local disconnect = function()
		table.remove(self._connections,table.find(self._connections,stored_func))
	end

	return disconnect
end

function port:FireServer(...)
	table.insert(self._send_queue, {
		target = "server",
		data = {...}
	})
end

function port:Init()
	local remoteevent = script.Parent.EventManager
	
	if not remoteevent then
		error("[SwiftPort] - Could not find matching server port for "..self._name..". Have you initialized the server?")
	end
	runService.Heartbeat:Connect(function()

		--send queue
		for i, v in pairs(self._send_queue) do
			remoteevent:FireServer(self._name,v.data)
			table.remove(self._send_queue,table.find(self._send_queue,v))
		end
		
	end)
	remoteevent.OnClientEvent:Connect(function(portname, data)	
		if self._name == portname then
			for i, connection in pairs(self._connections) do
				connection(data)
			end
		end
	end)
end

function port:OpenPort(name: string)
	assert(type(name) == "string", "[SwiftPort] - Port names must be a string")
	
	local found = client_ports[name]
	if found then
		return found
	end
	
	o = {}
	setmetatable(o, self)
	self.__index = self

	self._name = name
	
	self._connections = {}
	
	self._send_queue = {}
	self._recieve_queue = {}
	
	client_ports[self._name] = self
	
	getmetatable(o):Init()
	
	return getmetatable(o)
end

return port

