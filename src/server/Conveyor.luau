--!strict
-- Pack-shop conveyor. Every SPAWN_INTERVAL the server rolls a page pack per
-- player — a uniform page pick, plus a modifier ("mutation") rolled from
-- ModifierCatalog weights with the player's MutationLuck multiplying every
-- non-Mortal weight — and pushes it to their belt. Offers expire after
-- TRAVEL_TIME. Buying moves the pack into the player's inventory (Packs);
-- the card inside is NOT decided here — it's rolled when the pack is opened
-- (Packs.luau).
--
-- All rolls happen HERE (or in Packs.luau), never on the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local PageCatalog = require(Shared:WaitForChild("PageCatalog"))
local ModifierCatalog = require(Shared:WaitForChild("ModifierCatalog"))
local PackConfig = require(Shared:WaitForChild("PackConfig"))
local Config = require(Shared:WaitForChild("ConveyorConfig"))
local PlayerData = require(script.Parent.PlayerData)

type Offer = {
	uid: number,
	page: string,
	modifier: string,
	price: number,
	expiresAt: number, -- os.clock() based
}

local Conveyor = {}

local rng = Random.new()
local nextOfferUid = 0

-- Per-player belt state. Session-only; cleared on leave.
local offers: { [Player]: { [number]: Offer } } = {}
local nextSpawnAt: { [Player]: number } = {}

-- Pages sorted by tier for the weighted appearance roll.
local pagesByTier: { PageCatalog.Page } = {}
for _, page in PageCatalog do
	table.insert(pagesByTier, page)
end
table.sort(pagesByTier, function(a, b)
	return a.tier < b.tier
end)

-- Roll which page's pack appears. Low tiers dominate; Luck flattens the
-- falloff so higher-tier packs surface more often (see ConveyorConfig).
local function rollPage(luck: number): PageCatalog.Page
	local safeLuck = math.max(luck, 1)
	local total = 0
	local weights: { number } = {}
	for i, page in pagesByTier do
		local w = Config.PAGE_FALLOFF ^ ((page.tier - 1) / safeLuck)
		weights[i] = w
		total += w
	end

	local pick = rng:NextNumber() * total
	local acc = 0
	for i, page in pagesByTier do
		acc += weights[i]
		if pick < acc then
			return page
		end
	end
	return pagesByTier[1] -- float-edge fallback
end

local function rollModifier(mutationLuck: number): string
	local total = 0
	local weights: { [number]: number } = {}
	for i, mod in ModifierCatalog.list do
		local w = if mod.id == "mortal" then mod.weight else mod.weight * mutationLuck
		weights[i] = w
		total += w
	end

	local pick = rng:NextNumber() * total
	local acc = 0
	for i, mod in ModifierCatalog.list do
		acc += weights[i]
		if pick < acc then
			return mod.id
		end
	end
	return "mortal" -- float-edge fallback
end

local function spawnOffer(player: Player, luck: number, mutationLuck: number)
	local belt = offers[player]
	if not belt then
		return
	end

	local page = rollPage(luck)
	local modifier = rollModifier(mutationLuck)
	local mod = ModifierCatalog.byId[modifier]

	nextOfferUid += 1
	local offer: Offer = {
		uid = nextOfferUid,
		page = page.id,
		modifier = modifier,
		-- Price = page ladder price × modifier mult (a Divine tier-1 pack
		-- costs 100 × 10 = 1000). Server-computed and stored on the offer;
		-- the client only displays it.
		price = PackConfig.offerPrice(page.tier, mod.mult),
		expiresAt = os.clock() + Config.TRAVEL_TIME,
	}
	belt[offer.uid] = offer

	Remotes.OfferSpawned:FireClient(player, {
		uid = offer.uid,
		page = offer.page,
		modifier = offer.modifier,
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
	local page = PageCatalog[offer.page]
	if data.Coins < offer.price then
		Remotes.Notify:FireClient(
			player,
			`Not enough Coins for that {page.name} Pack ({offer.price}).`
		)
		return
	end

	-- 4. Consume the offer, then apply atomically — no yields between the
	--    check above and here, or two rapid buys could both pass step 3.
	belt[uid] = nil

	PlayerData.Mutate(player, function(d)
		d.Coins -= offer.price
		local packUid = tostring(d.NextPackUid)
		d.NextPackUid += 1
		d.Packs[packUid] = {
			page = offer.page,
			modifier = offer.modifier,
			state = "stored",
			openReadyAt = 0, -- set when placed
		}
	end)

	Remotes.OfferRemoved:FireClient(player, uid)
	local mod = ModifierCatalog.byId[offer.modifier]
	local prefix = if mod.id == "mortal" then "" else `{mod.name} `
	Remotes.Notify:FireClient(player, `Bought a {prefix}{page.name} Pack!`)
end

function Conveyor.Init()
	local function track(player: Player)
		offers[player] = {}
		nextSpawnAt[player] = os.clock() + Config.SPAWN_INTERVAL
	end

	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
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
						spawnOffer(player, data.Luck or 1, data.MutationLuck or 1)
					end
				end
			end
		end
	end)
end

return Conveyor
