--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Net"

-- Server creates the folder/remotes on require; client waits for them.
local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local folder = getFolder()

local function getRemote(className: string, name: string): Instance
	if RunService:IsServer() then
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		return remote
	end
	return folder:WaitForChild(name)
end

return {
	DataChanged = getRemote("RemoteEvent", "DataChanged") :: RemoteEvent,
	RequestData = getRemote("RemoteFunction", "RequestData") :: RemoteFunction,
	-- Conveyor card shop: server pushes offers, client asks to buy one.
	OfferSpawned = getRemote("RemoteEvent", "OfferSpawned") :: RemoteEvent,
	OfferRemoved = getRemote("RemoteEvent", "OfferRemoved") :: RemoteEvent,
	BuyOffer = getRemote("RemoteEvent", "BuyOffer") :: RemoteEvent,
	Notify = getRemote("RemoteEvent", "Notify") :: RemoteEvent,
}
