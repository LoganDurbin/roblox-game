--!strict
-- Pack lifecycle: stored (inventory) -> placed (open timer running) ->
-- opened (card rolled, pack consumed).
--
-- The card inside a pack is rolled HERE, at open time, from the pack's page
-- using PackConfig.RARITY_WEIGHT — fixed odds that no stat modifies. The
-- pack's modifier transfers to the rolled card if it outranks the card's
-- current one (best-wins; equal or worse never downgrades).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardCatalog = require(Shared:WaitForChild("CardCatalog"))
local CardStats = require(Shared:WaitForChild("CardStats"))
local ModifierCatalog = require(Shared:WaitForChild("ModifierCatalog"))
local PackConfig = require(Shared:WaitForChild("PackConfig"))
local PlayerData = require(script.Parent.PlayerData)

local Packs = {}

local rng = Random.new()

local function countPlaced(packs: { [string]: any }): number
	local placed = 0
	for _, pack in packs do
		if pack.state == "placed" then
			placed += 1
		end
	end
	return placed
end

-- Weighted roll over the page's cards. Weight comes from rarity only.
local function rollCard(pageId: string): CardCatalog.Card
	local pool = CardStats.pageCards[pageId]
	local total = 0
	for _, card in pool do
		total += PackConfig.RARITY_WEIGHT[card.rarity] :: number
	end

	local pick = rng:NextNumber() * total
	local acc = 0
	for _, card in pool do
		acc += PackConfig.RARITY_WEIGHT[card.rarity] :: number
		if pick < acc then
			return card
		end
	end
	return pool[#pool] -- float-edge fallback
end

local function tryPlace(player: Player, uid: any)
	if type(uid) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local pack = data.Packs[uid]
	if not pack or pack.state ~= "stored" then
		return
	end
	if countPlaced(data.Packs) >= PackConfig.PLACEMENT_LIMIT then
		Remotes.Notify:FireClient(
			player,
			`Placement full ({PackConfig.PLACEMENT_LIMIT} packs max).`
		)
		return
	end

	local mod = ModifierCatalog.byId[pack.modifier]
	local openTime = if mod then mod.openTime else ModifierCatalog.byId.mortal.openTime
	PlayerData.Mutate(player, function(d)
		local p = d.Packs[uid]
		if p and p.state == "stored" then
			p.state = "placed"
			p.openReadyAt = os.time() + openTime
		end
	end)
end

local function tryOpen(player: Player, uid: any)
	if type(uid) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local pack = data.Packs[uid]
	if not pack or pack.state ~= "placed" then
		return
	end
	local now = os.time()
	if now < pack.openReadyAt then
		Remotes.Notify:FireClient(player, `Not ready — {pack.openReadyAt - now}s left.`)
		return
	end

	-- Roll before mutating; the mutation itself must stay yield-free.
	local card = rollCard(pack.page)
	local packMod = ModifierCatalog.byId[pack.modifier] or ModifierCatalog.byId.mortal

	local isNew = false
	local upgraded = false
	PlayerData.Mutate(player, function(d)
		d.Packs[uid] = nil

		local entry = d.Cards[card.id]
		if not entry then
			isNew = true
			d.Cards[card.id] = {
				copies = 1,
				modifier = packMod.id,
				lastClaimAt = now,
			}
			return
		end

		-- Bank pending income at the card's OLD rate before its rate
		-- changes (more copies / better modifier), so the increase is
		-- never applied retroactively to time already accrued.
		local completionMult = CardStats.completionMult(d.Cards)
		local oldRate = CardStats.rateFor(card.id, entry, completionMult)
		d.Coins += CardStats.pendingFor(oldRate, entry, now)
		entry.lastClaimAt = now

		entry.copies += 1
		local currentMod = ModifierCatalog.byId[entry.modifier]
		if not currentMod or packMod.rank > currentMod.rank then
			entry.modifier = packMod.id
			upgraded = true
		end
	end)

	local modPrefix = if packMod.id == "mortal" then "" else `{packMod.name} `
	if isNew then
		Remotes.Notify:FireClient(player, `NEW! {modPrefix}{card.name} ({card.rarity})`)
	elseif upgraded then
		Remotes.Notify:FireClient(player, `{card.name} upgraded to {packMod.name}!`)
	else
		Remotes.Notify:FireClient(player, `{card.name} ({card.rarity}) leveled up!`)
	end
end

function Packs.Init()
	Remotes.PlacePack.OnServerEvent:Connect(tryPlace)
	Remotes.OpenPack.OnServerEvent:Connect(tryOpen)
end

return Packs
