--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.ProfileStore)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local PROFILE_TEMPLATE = {
	Coins = 250, -- enough for a couple of first packs; without a card, income is 0
	Gems = 0,
	-- Collection: [cardId] = { copies, modifier, lastClaimAt }.
	-- copies >= 1 means discovered in the index; modifier is best-wins;
	-- lastClaimAt anchors lazy income accrual (see CardStats).
	Cards = {},
	-- Pack inventory + placed packs: [uid string] = { page, modifier, state,
	-- openReadyAt }. state is "stored" or "placed"; openReadyAt is os.time()
	-- when a placed pack becomes openable. String keys keep the table
	-- DataStore-safe.
	Packs = {},
	NextPackUid = 1, -- per-player counter so pack uids survive rejoins
	Prestige = 0,
	Luck = 1, -- reserved: belt-side pack luck (upgrades, M3)
	MutationLuck = 1, -- multiplies non-Mortal modifier spawn weights (upgrades, M3)
	-- Note: older dev profiles may still carry stale keys (Cash/Units/...) —
	-- Reconcile only adds missing keys, never removes. Harmless; ignore or
	-- wipe test data.
}

-- Older card-core profiles stored Cards[id] as a plain copy count. Normalize
-- to the entry table so the rest of the code can assume one shape.
local function migrate(data: { [string]: any })
	local now = os.time()
	if type(data.Cards) == "table" then
		for id, value in data.Cards do
			if type(value) == "number" then
				data.Cards[id] = { copies = value, modifier = "mortal", lastClaimAt = now }
			end
		end
	end
end

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
		migrate(profile.Data)

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
