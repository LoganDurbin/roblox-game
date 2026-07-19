--!strict
-- Card-shop conveyor. Every SPAWN_INTERVAL the server rolls a card offer per
-- player (weighted by rarity, shifted by their Luck stat) and pushes it to
-- their belt. Offers expire after TRAVEL_TIME. Buying is a request for a
-- specific offer uid; the server validates existence, expiry, and Coins.
--
-- The roll happens HERE, never on the client — the client only renders
-- offers the server already decided on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardCatalog = require(Shared:WaitForChild("CardCatalog"))
local Config = require(Shared:WaitForChild("ConveyorConfig"))
local PlayerData = require(script.Parent.PlayerData)

type Offer = {
	uid: number,
	cardId: string,
	price: number,
	expiresAt: number, -- os.clock() based
}

local Conveyor = {}

local rng = Random.new()
local nextUid = 0

-- Per-player belt state. Cleared on leave.
local offers: { [Player]: { [number]: Offer } } = {}
local nextSpawnAt: { [Player]: number } = {}

-- Cards grouped by rarity, precomputed once (catalog is static).
local cardsByRarity: { [string]: { CardCatalog.Card } } = {}
for _, card in CardCatalog do
	local list = cardsByRarity[card.rarity]
	if not list then
		list = {}
		cardsByRarity[card.rarity] = list
	end
	table.insert(list, card)
end
-- Deterministic order within a rarity (map iteration isn't).
for _, list in cardsByRarity do
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
end

-- Roll a rarity bucket (Luck multiplies non-Common weights), then a uniform
-- card within it.
local function rollCard(luck: number): CardCatalog.Card
	local weights: { [string]: number } = {}
	local total = 0
	for rarity, base in Config.WEIGHT do
		local w = if rarity == "Common" then base else base * luck
		weights[rarity] = w
		total += w
	end

	local pick = rng:NextNumber() * total
	local acc = 0
	local chosen = "Common"
	for rarity, w in weights do
		acc += w
		if pick < acc then
			chosen = rarity
			break
		end
	end

	local list = cardsByRarity[chosen]
	return list[rng:NextInteger(1, #list)]
end

local function spawnOffer(player: Player, luck: number)
	local belt = offers[player]
	if not belt then
		return
	end

	local card = rollCard(luck)
	nextUid += 1
	local offer: Offer = {
		uid = nextUid,
		cardId = card.id,
		price = Config.PRICE[card.rarity] :: number,
		expiresAt = os.clock() + Config.TRAVEL_TIME,
	}
	belt[offer.uid] = offer

	Remotes.OfferSpawned:FireClient(player, {
		uid = offer.uid,
		cardId = offer.cardId,
		price = offer.price,
		travelTime = Config.TRAVEL_TIME,
	})
end

local function tryBuy(player: Player, uid: any)
	-- 1. Validate the input itself. The client can send anything.
	if type(uid) ~= "number" then
		return
	end
	local belt = offers[player]
	local offer = belt and belt[uid]
	if not offer then
		return -- unknown uid, or already bought/expired
	end
	if os.clock() >= offer.expiresAt then
		belt[uid] = nil -- rode off the end of the belt
		return
	end

	-- 2. Read authoritative state.
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	-- 3. Validate affordability.
	local card = CardCatalog[offer.cardId]
	if data.Coins < offer.price then
		Remotes.Notify:FireClient(player, `Not enough Coins for {card.name} ({offer.price}).`)
		return
	end

	-- 4. Consume the offer, then apply atomically — no yields between the
	--    check above and here, or two rapid buys could both pass step 3.
	belt[uid] = nil

	local isNew = false
	PlayerData.Mutate(player, function(d)
		d.Coins -= offer.price
		local copies = (d.Cards[offer.cardId] or 0) + 1
		d.Cards[offer.cardId] = copies
		isNew = copies == 1
	end)

	Remotes.OfferRemoved:FireClient(player, uid)
	if isNew then
		Remotes.Notify:FireClient(player, `NEW! {card.name} ({card.rarity})`)
	else
		Remotes.Notify:FireClient(player, `{card.name} ({card.rarity}) leveled up!`)
	end
end

function Conveyor.Init()
	Players.PlayerAdded:Connect(function(player)
		offers[player] = {}
		nextSpawnAt[player] = os.clock() + Config.SPAWN_INTERVAL
	end)
	for _, player in Players:GetPlayers() do
		offers[player] = {}
		nextSpawnAt[player] = os.clock() + Config.SPAWN_INTERVAL
	end

	Players.PlayerRemoving:Connect(function(player)
		offers[player] = nil
		nextSpawnAt[player] = nil
	end)

	Remotes.BuyOffer.OnServerEvent:Connect(tryBuy)

	-- Single heartbeat loop: spawn offers on schedule, prune expired ones.
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for player, belt in offers do
				-- Prune offers that rode off the end of the belt.
				for uid, offer in belt do
					if now >= offer.expiresAt then
						belt[uid] = nil
					end
				end

				local spawnAt = nextSpawnAt[player]
				if spawnAt and now >= spawnAt then
					nextSpawnAt[player] = now + Config.SPAWN_INTERVAL
					local data = PlayerData.Get(player)
					-- Skip until the profile is loaded; no offers for nobody.
					if data then
						spawnOffer(player, data.Luck or 1)
					end
				end
			end
		end
	end)
end

return Conveyor
