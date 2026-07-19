--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.ProfileStore)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local PROFILE_TEMPLATE = {
	Coins = 250, -- enough for a couple of first summons; without a card, income is 0
	Gems = 0,
	Cards = {}, -- collection: [cardId] = copies (>= 1 means discovered in the index)
	Prestige = 0,
	Luck = 1, -- multiplies non-Common conveyor spawn weights; raised by prestige/gamepasses later
	-- Note: pre-pivot dev profiles may still carry Cash/Units/Rebirths keys
	-- (Reconcile only adds missing keys, never removes). Harmless; ignore or
	-- wipe test data.
}

local PlayerStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

local Profiles: { [Player]: any } = {}

local PlayerData = {}

local function replicate(player: Player)
	local profile = Profiles[player]
	if profile then
		Remotes.DataChanged:FireClient(player, profile.Data)
	end
end

function PlayerData.Get(player: Player): { [string]: any }?
	local profile = Profiles[player]
	return profile and profile.Data
end

function PlayerData.Set(player: Player, key: string, value: any)
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile.Data[key] = value
	replicate(player)
end

function PlayerData.Increment(player: Player, key: string, amount: number)
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile.Data[key] = (profile.Data[key] or 0) + amount
	replicate(player)
end

function PlayerData.Init()
	-- Client pulls its initial state when its UI is ready.
	Remotes.RequestData.OnServerInvoke = function(player)
		local profile = Profiles[player]
		return profile and profile.Data
	end

	local function onPlayerAdded(player: Player)
		local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if not profile then
			player:Kick("Data failed to load. Please rejoin.")
			return
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Data session ended. Please rejoin.")
		end)

		if player.Parent ~= Players then
			profile:EndSession()
			return
		end

		Profiles[player] = profile
		replicate(player) -- covers the case where the client is already listening
	end

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
end

-- Run a mutation against the player's data and replicate once.
-- Do NOT yield inside `fn` — the read/validate/write must stay atomic.
function PlayerData.Mutate(player: Player, fn: (data: { [string]: any }) -> ()): boolean
	local profile = Profiles[player]
	if not profile then
		return false
	end
	fn(profile.Data)
	replicate(player)
	return true
end

return PlayerData
