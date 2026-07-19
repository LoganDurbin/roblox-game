--!strict
-- Pure functions for card math, shared so the client displays exactly what
-- the server pays. No state, no side effects.

local CardCatalog = require(script.Parent.CardCatalog)
local PageCatalog = require(script.Parent.PageCatalog)

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

-- Coins/sec a single card produces at `copies` copies.
-- Linear for now: each duplicate adds another baseIncome. Tune later.
function CardStats.incomeFor(cardId: string, copies: number): number
	local card = CardCatalog[cardId]
	if not card or copies < 1 then
		return 0
	end
	return card.baseIncome * copies
end

-- Whether every card on `pageId` is owned (>= 1 copy).
function CardStats.isPageComplete(cards: { [string]: number }, pageId: string): boolean
	local list = pageCards[pageId]
	if not list or #list == 0 then
		return false
	end
	for _, card in list do
		if (cards[card.id] or 0) < 1 then
			return false
		end
	end
	return true
end

-- Total Coins/sec for a player's collection: sum of per-card income times
-- the product of every completed page's bonus.
function CardStats.totalIncome(cards: { [string]: number }): number
	local base = 0
	for cardId, copies in cards do
		base += CardStats.incomeFor(cardId, copies)
	end

	local multiplier = 1
	for pageId, page in PageCatalog do
		if CardStats.isPageComplete(cards, pageId) then
			multiplier *= page.completionBonus
		end
	end

	return base * multiplier
end

return CardStats
