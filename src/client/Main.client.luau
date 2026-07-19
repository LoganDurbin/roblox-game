--!strict
-- Flat test UI for the pack economy (M2). Everything here is display +
-- requests; the server owns all state and every roll. This whole layer gets
-- replaced by the physical plot/belt world in M4 — keep it functional, not
-- pretty.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardStats = require(Shared:WaitForChild("CardStats"))
local PageCatalog = require(Shared:WaitForChild("PageCatalog"))
local ModifierCatalog = require(Shared:WaitForChild("ModifierCatalog"))

local player = Players.LocalPlayer
local data: { [string]: any } = {}

local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4 }
local RARITY_COLOR = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
}

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent: Instance, size: UDim2, pos: UDim2, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = pos
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function makeScroll(pos: UDim2, size: UDim2): (ScrollingFrame, UIListLayout)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = pos
	scroll.Size = size
	scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	scroll.BackgroundTransparency = 0.4
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	return scroll, layout
end

-- ============================================================ conveyor belt
-- Server-pushed PACK offers slide right-to-left; tap the price to buy one
-- into your inventory before it rides off.

local belt = Instance.new("Frame")
belt.Name = "Conveyor"
belt.Size = UDim2.new(1, 0, 0, 96)
belt.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
belt.BackgroundTransparency = 0.25
belt.BorderSizePixel = 0
belt.ClipsDescendants = true
belt.Parent = gui

local PACK_WIDTH = 120
local offerFrames: { [number]: Frame } = {}

local function removeOffer(uid: number)
	local frame = offerFrames[uid]
	if frame then
		offerFrames[uid] = nil
		frame:Destroy()
	end
end

local function onOfferSpawned(offer: {
	uid: number,
	page: string,
	modifier: string,
	price: number,
	travelTime: number,
})
	local page = PageCatalog[offer.page]
	local mod = ModifierCatalog.byId[offer.modifier]
	if not page or not mod then
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(PACK_WIDTH, 84)
	frame.Position = UDim2.new(1, 0, 0, 6) -- enter from the right edge
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.BorderSizePixel = 0
	frame.Parent = belt

	local stroke = Instance.new("UIStroke")
	stroke.Color = mod.color
	stroke.Thickness = if mod.id == "mortal" then 1 else 3
	stroke.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.fromOffset(4, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Text = `{page.name} Pack`
	nameLabel.Parent = frame

	local modLabel = Instance.new("TextLabel")
	modLabel.Size = UDim2.new(1, -8, 0, 18)
	modLabel.Position = UDim2.fromOffset(4, 22)
	modLabel.BackgroundTransparency = 1
	modLabel.TextColor3 = mod.color
	modLabel.Font = Enum.Font.GothamMedium
	modLabel.TextScaled = true
	modLabel.Text = if mod.id == "mortal" then "" else `{mod.name} x{mod.mult}`
	modLabel.Parent = frame

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, -8, 0, 36)
	buyBtn.Position = UDim2.fromOffset(4, 44)
	buyBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.Font = Enum.Font.GothamMedium
	buyBtn.TextScaled = true
	buyBtn.Text = `{offer.price}`
	buyBtn.Parent = frame
	buyBtn.Activated:Connect(function()
		Remotes.BuyOffer:FireServer(offer.uid)
	end)

	offerFrames[offer.uid] = frame

	local tween = TweenService:Create(
		frame,
		TweenInfo.new(offer.travelTime, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(0, -PACK_WIDTH, 0, 6) }
	)
	tween.Completed:Connect(function()
		removeOffer(offer.uid)
	end)
	tween:Play()
end

Remotes.OfferSpawned.OnClientEvent:Connect(onOfferSpawned)
Remotes.OfferRemoved.OnClientEvent:Connect(removeOffer)

-- =================================================================== stats

local coinsLabel = makeLabel(
	gui,
	UDim2.fromOffset(280, 40),
	UDim2.fromOffset(16, 108),
	Color3.fromRGB(255, 215, 90)
)
coinsLabel.Text = "Coins: ..."

local rateLabel = makeLabel(
	gui,
	UDim2.fromOffset(280, 24),
	UDim2.fromOffset(16, 152),
	Color3.fromRGB(120, 230, 140)
)
rateLabel.Font = Enum.Font.Gotham
rateLabel.Text = "+0/s while claimed"

local claimAllBtn = Instance.new("TextButton")
claimAllBtn.Size = UDim2.fromOffset(280, 36)
claimAllBtn.Position = UDim2.fromOffset(16, 180)
claimAllBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 70)
claimAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimAllBtn.Font = Enum.Font.GothamBold
claimAllBtn.TextScaled = true
claimAllBtn.Text = "Collect All"
claimAllBtn.Parent = gui
claimAllBtn.Activated:Connect(function()
	Remotes.ClaimAll:FireServer()
end)

local toast = makeLabel(
	gui,
	UDim2.fromOffset(320, 36),
	UDim2.fromOffset(16, 222),
	Color3.fromRGB(240, 240, 240)
)
toast.Font = Enum.Font.Gotham
toast.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toast.Visible = false

local toastToken = 0
local function showToast(msg: string)
	toast.Text = msg
	toast.Visible = true
	toastToken += 1
	local token = toastToken
	task.delay(2.5, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end
Remotes.Notify.OnClientEvent:Connect(showToast)

-- ==================================================== inventory + placement
-- Stored packs (buy -> here) and placed packs (timer -> open). Both lists
-- rebuild on every data change; the 1 Hz loop below only refreshes timers.

local invHeader = makeLabel(
	gui,
	UDim2.fromOffset(280, 24),
	UDim2.fromOffset(16, 266),
	Color3.fromRGB(255, 255, 255)
)
invHeader.Text = "Inventory (packs)"

local invScroll = makeScroll(UDim2.fromOffset(16, 292), UDim2.new(0, 280, 1, -300))

local placedHeader = makeLabel(
	gui,
	UDim2.fromOffset(280, 24),
	UDim2.fromOffset(312, 108),
	Color3.fromRGB(255, 255, 255)
)
placedHeader.Text = "Placed (opening)"

local placedScroll = makeScroll(UDim2.fromOffset(312, 134), UDim2.new(0, 280, 0, 320))

type PlacedRow = { timer: TextLabel, openBtn: TextButton, uid: string }
local placedRows: { PlacedRow } = {}

local function sortedPackUids(): { string }
	local uids: { string } = {}
	for uid in data.Packs or {} do
		table.insert(uids, uid)
	end
	table.sort(uids, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	return uids
end

local function rebuildPackLists()
	for _, child in invScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, child in placedScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(placedRows)

	local packs = data.Packs or {}
	local order = 0
	for _, uid in sortedPackUids() do
		local pack = packs[uid]
		local page = PageCatalog[pack.page]
		local mod = ModifierCatalog.byId[pack.modifier]
		if not page or not mod then
			continue
		end
		order += 1

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 34)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		row.BorderSizePixel = 0
		row.LayoutOrder = order

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -78, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = mod.color
		label.Font = Enum.Font.Gotham
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		local modPrefix = if mod.id == "mortal" then "" else `{mod.name} `
		label.Text = `  {modPrefix}{page.name} Pack`
		label.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(70, 28)
		btn.Position = UDim2.new(1, -74, 0, 3)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamMedium
		btn.TextScaled = true
		btn.Parent = row

		if pack.state == "stored" then
			btn.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
			btn.Text = "Place"
			btn.Activated:Connect(function()
				Remotes.PlacePack:FireServer(uid)
			end)
			row.Parent = invScroll
		else -- placed
			btn.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
			btn.Text = "..."
			btn.Activated:Connect(function()
				Remotes.OpenPack:FireServer(uid)
			end)

			local timer = Instance.new("TextLabel")
			timer.Size = UDim2.new(0, 70, 1, 0)
			timer.Position = UDim2.new(1, -148, 0, 0)
			timer.BackgroundTransparency = 1
			timer.TextColor3 = Color3.fromRGB(200, 200, 210)
			timer.Font = Enum.Font.Gotham
			timer.TextScaled = true
			timer.Text = ""
			timer.Parent = row

			table.insert(placedRows, { timer = timer, openBtn = btn, uid = uid })
			row.Parent = placedScroll
		end
	end
end

-- =================================================================== index
-- Collection book: owned rows accrue pending Coins — tap a row to claim it.

local index = makeScroll(UDim2.new(1, -312, 0, 108), UDim2.new(0, 296, 1, -116))

type CardRow = { button: TextButton, cardId: string, cardName: string, rarity: string }
type PageEntry = { header: TextLabel, page: PageCatalog.Page, rows: { CardRow } }
local pageEntries: { PageEntry } = {}

local orderedPages: { PageCatalog.Page } = {}
for _, page in PageCatalog do
	table.insert(orderedPages, page)
end
table.sort(orderedPages, function(a, b)
	return a.order < b.order
end)

local layoutOrder = 0
for _, page in orderedPages do
	layoutOrder += 1
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -8, 0, 28)
	header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	header.BackgroundTransparency = 0.1
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.Font = Enum.Font.GothamBold
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = layoutOrder
	header.Text = page.name
	header.Parent = index

	local cards = table.clone(CardStats.pageCards[page.id] or {})
	table.sort(cards, function(a, b)
		local ra, rb = RARITY_ORDER[a.rarity] :: number, RARITY_ORDER[b.rarity] :: number
		if ra ~= rb then
			return ra < rb
		end
		return a.name < b.name
	end)

	local rows: { CardRow } = {}
	for _, card in cards do
		layoutOrder += 1
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -8, 0, 24)
		row.BackgroundTransparency = 1
		row.TextColor3 = RARITY_COLOR[card.rarity] :: Color3
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = layoutOrder
		row.Text = "  ???"
		row.Parent = index
		row.Activated:Connect(function()
			Remotes.ClaimCard:FireServer(card.id)
		end)
		table.insert(
			rows,
			{ button = row, cardId = card.id, cardName = card.name, rarity = card.rarity }
		)
	end

	table.insert(pageEntries, { header = header, page = page, rows = rows })
end

-- ================================================================ rendering

-- Live bits (pack timers, per-card pending) refresh every second; structural
-- bits rebuild only when the server replicates a data change.
local function renderLive()
	local now = os.time()
	local cards: { [string]: CardStats.CardEntry } = data.Cards or {}
	local completionMult = CardStats.completionMult(cards)

	for _, row in placedRows do
		local pack = (data.Packs or {})[row.uid]
		if not pack then
			continue
		end
		local left = pack.openReadyAt - now
		if left <= 0 then
			row.timer.Text = ""
			row.openBtn.Text = "Open"
			row.openBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 70)
		else
			row.timer.Text = `{left}s`
		end
	end

	for _, entry in pageEntries do
		local owned = 0
		for _, row in entry.rows do
			local cardEntry = cards[row.cardId]
			if cardEntry and cardEntry.copies >= 1 then
				owned += 1
				local rate = CardStats.rateFor(row.cardId, cardEntry, completionMult)
				local pending = math.floor(CardStats.pendingFor(rate, cardEntry, now))
				local mod = ModifierCatalog.byId[cardEntry.modifier]
				local modTag = if mod and mod.id ~= "mortal" then ` [{mod.name}]` else ""
				row.button.Text = `  {row.cardName} ×{cardEntry.copies}{modTag}  {pending} ⛃`
			else
				row.button.Text = "  ???"
			end
		end
		local total = #entry.rows
		if owned == total and total > 0 then
			entry.header.Text = `{entry.page.name}  ✓ COMPLETE (x{entry.page.completionBonus})`
		else
			entry.header.Text = `{entry.page.name}  {owned}/{total}`
		end
	end

	coinsLabel.Text = `Coins: {math.floor(data.Coins or 0)}`
	rateLabel.Text = `+{CardStats.totalRate(cards)}/s while claimed`
end

local function onData(newData: { [string]: any })
	data = newData
	rebuildPackLists()
	renderLive()
end

-- Listen first, then pull initial state. If the profile isn't loaded yet
-- the invoke returns nil, and the server's push covers us.
Remotes.DataChanged.OnClientEvent:Connect(onData)

local initial = Remotes.RequestData:InvokeServer()
if initial then
	onData(initial)
end

task.spawn(function()
	while true do
		task.wait(1)
		renderLive()
	end
end)
