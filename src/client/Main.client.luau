--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardStats = require(Shared:WaitForChild("CardStats"))
local PageCatalog = require(Shared:WaitForChild("PageCatalog"))
local SummonCatalog = require(Shared:WaitForChild("SummonCatalog"))

local player = Players.LocalPlayer
local data: { [string]: any } = {}

local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4 }
local RARITY_COLOR = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
}

-- Minimal HUD, built in code so it lives in source control.
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(220, 48)
coinsLabel.Position = UDim2.fromOffset(16, 16)
coinsLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
coinsLabel.BackgroundTransparency = 0.3
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextScaled = true
coinsLabel.Text = "Coins: ..."
coinsLabel.Parent = gui

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Size = UDim2.fromOffset(220, 28)
incomeLabel.Position = UDim2.fromOffset(16, 68)
incomeLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
incomeLabel.BackgroundTransparency = 0.3
incomeLabel.TextColor3 = Color3.fromRGB(120, 230, 140)
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextScaled = true
incomeLabel.Text = "+0/s"
incomeLabel.Parent = gui

-- Toast for server feedback
local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(320, 40)
toast.Position = UDim2.fromOffset(16, 104)
toast.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toast.BackgroundTransparency = 0.2
toast.TextColor3 = Color3.fromRGB(240, 240, 240)
toast.Font = Enum.Font.Gotham
toast.TextScaled = true
toast.Visible = false
toast.Parent = gui

local toastToken = 0
local function showToast(msg: string)
	toast.Text = msg
	toast.Visible = true
	toastToken += 1
	local token = toastToken
	task.delay(2, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end
Remotes.Notify.OnClientEvent:Connect(showToast)

-- Summon button (one banner for now)
local banner = SummonCatalog.standard
local summonBtn = Instance.new("TextButton")
summonBtn.Size = UDim2.fromOffset(220, 52)
summonBtn.Position = UDim2.fromOffset(16, 152)
summonBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
summonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
summonBtn.Font = Enum.Font.GothamBold
summonBtn.TextScaled = true
summonBtn.Text = `Summon ({banner.cost})`
summonBtn.Parent = gui
summonBtn.Activated:Connect(function()
	Remotes.Summon:FireServer(banner.id)
end)

-- Index: one scrolling list, a header per page, a row per card.
-- Built once; row/header texts update on data change.
local index = Instance.new("ScrollingFrame")
index.Size = UDim2.new(0, 280, 1, -232)
index.Position = UDim2.fromOffset(16, 216)
index.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
index.BackgroundTransparency = 0.4
index.BorderSizePixel = 0
index.ScrollBarThickness = 6
index.AutomaticCanvasSize = Enum.AutomaticSize.Y
index.CanvasSize = UDim2.fromOffset(0, 0)
index.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = index

-- Pages in display order; cards within a page by rarity then name.
local orderedPages: { PageCatalog.Page } = {}
for _, page in PageCatalog do
	table.insert(orderedPages, page)
end
table.sort(orderedPages, function(a, b)
	return a.order < b.order
end)

type CardRow = { label: TextLabel, cardId: string, cardName: string }
type PageEntry = { header: TextLabel, page: PageCatalog.Page, rows: { CardRow } }
local pageEntries: { PageEntry } = {}

local layoutOrder = 0
for _, page in orderedPages do
	layoutOrder += 1
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -8, 0, 30)
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
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -8, 0, 24)
		row.BackgroundTransparency = 1
		row.TextColor3 = RARITY_COLOR[card.rarity] :: Color3
		row.Font = Enum.Font.Gotham
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = layoutOrder
		row.Text = "  ???"
		row.Parent = index
		table.insert(rows, { label = row, cardId = card.id, cardName = card.name })
	end

	table.insert(pageEntries, { header = header, page = page, rows = rows })
end

local function render()
	local cards: { [string]: number } = data.Cards or {}
	coinsLabel.Text = `Coins: {math.floor(data.Coins or 0)}`
	incomeLabel.Text = `+{CardStats.totalIncome(cards)}/s`

	for _, entry in pageEntries do
		local owned = 0
		for _, row in entry.rows do
			local copies = cards[row.cardId] or 0
			if copies >= 1 then
				owned += 1
				local income = CardStats.incomeFor(row.cardId, copies)
				row.label.Text = `  {row.cardName}  ×{copies}  (+{income}/s)`
			else
				row.label.Text = "  ???"
			end
		end
		local total = #entry.rows
		if owned == total and total > 0 then
			entry.header.Text = `{entry.page.name}  ✓ COMPLETE (x{entry.page.completionBonus})`
		else
			entry.header.Text = `{entry.page.name}  {owned}/{total}`
		end
	end
end

local function onData(newData: { [string]: any })
	data = newData
	render()
end

-- Listen first, then pull initial state. If the profile isn't loaded yet
-- the invoke returns nil, and the server's push covers us.
Remotes.DataChanged.OnClientEvent:Connect(onData)

local initial = Remotes.RequestData:InvokeServer()
if initial then
	onData(initial)
end
