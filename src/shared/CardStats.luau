--!strict
-- Pure functions for card math, shared so the client displays exactly what
-- the server pays. No state, no side effects.
--
-- Income model: each unlocked card accrues its own Coin pool at `rate`
-- Coins/sec, up to STORAGE_CAP_SECONDS worth. Claiming banks
-- rate × min(elapsed, cap) and resets the card's accrual clock. Nothing is
-- auto-credited; accrual is computed lazily from lastClaimAt (which also
-- handles offline time for free).

local CardCatalog = require(script.Parent.CardCatalog)
local PageCatalog = require(script.Parent.PageCatalog)
local ModifierCatalog = require(script.Parent.ModifierCatalog)
local PackConfig = require(script.Parent.PackConfig)

-- A player's per-card collection entry (PlayerData.Cards values).
export type CardEntry = {
	copies: number,
	modifier: string, -- ModifierCatalog id; best-wins, never downgrades
	lastClaimAt: number, -- os.time() of last claim (or unlock)
}

local CardStats = {}

-- Cards on each page, precomputed once (catalogs are static).
local pageCards: { [string]: { CardCatalog.Card } } = {}
for _, card in CardCatalog do
	local list = pageCards[card.page]
	if not list then
		list = {}
		pageCards[card.page] = list
	end
	table.insert(list, card)
end
CardStats.pageCards = pageCards

-- Whether every card on `pageId` is owned (>= 1 copy).
function CardStats.isPageComplete(cards: { [string]: CardEntry }, pageId: string): boolean
	local list = pageCards[pageId]
	if not list or #list == 0 then
		return false
	end
	for _, card in list do
		local entry = cards[card.id]
		if not entry or entry.copies < 1 then
			return false
		end
	end
	return true
end

-- Product of every completed page's bonus. Applies to ALL cards' rates.
function CardStats.completionMult(cards: { [string]: CardEntry }): number
	local mult = 1
	for pageId, page in PageCatalog do
		if CardStats.isPageComplete(cards, pageId) then
			mult *= page.completionBonus
		end
	end
	return mult
end

-- Coins/sec one card generates:
-- baseIncome × page tier mult × copies × modifier mult × completion mult.
-- The tier multiplier tracks pack pricing (PackConfig.CLIMB_RATE) so every
-- page earns in proportion to what the next rung costs.
-- (Global cash upgrades / Robux multipliers fold in here in M3.)
function CardStats.rateFor(cardId: string, entry: CardEntry, completionMult: number): number
	local card = CardCatalog[cardId]
	if not card or entry.copies < 1 then
		return 0
	end
	local page = PageCatalog[card.page]
	local tierMult = if page then PackConfig.tierIncomeMult(page.tier) else 1
	local mod = ModifierCatalog.byId[entry.modifier]
	local modMult = if mod then mod.mult else 1
	return card.baseIncome * tierMult * entry.copies * modMult * completionMult
end

-- Unclaimed Coins sitting on a card at time `now`. Accrual stops at the
-- storage cap until claimed.
function CardStats.pendingFor(rate: number, entry: CardEntry, now: number): number
	local elapsed = math.max(now - entry.lastClaimAt, 0)
	return rate * math.min(elapsed, PackConfig.STORAGE_CAP_SECONDS)
end

-- Total Coins/sec across the collection (HUD display).
function CardStats.totalRate(cards: { [string]: CardEntry }): number
	local completionMult = CardStats.completionMult(cards)
	local total = 0
	for cardId, entry in cards do
		total += CardStats.rateFor(cardId, entry, completionMult)
	end
	return total
end

return CardStats
