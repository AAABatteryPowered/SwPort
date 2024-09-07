local runService = game:GetService("RunService")

if runService:IsServer() then
	return require(script.Server)
else
	return require(script.Client)
end
