--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UnitCatalog"))

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local data: { [string]: any } = {}

-- Minimal HUD, built in code so it lives in source control.
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.fromOffset(220, 48)
cashLabel.Position = UDim2.fromOffset(16, 16)
cashLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
cashLabel.BackgroundTransparency = 0.3
cashLabel.TextColor3 = Color3.fromRGB(120, 230, 140)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.Text = "Cash: ..."
cashLabel.Parent = gui

local function render()
	cashLabel.Text = `Cash: {data.Cash or 0}`
end

-- Toast for server feedback
local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(320, 40)
toast.Position = UDim2.fromOffset(16, 76)
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

-- One buy button per catalog unit
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.fromOffset(220, 200)
shopFrame.Position = UDim2.fromOffset(16, 128)
shopFrame.BackgroundTransparency = 1
shopFrame.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = shopFrame

for id, unit in Catalog do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(220, 44)
	btn.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamMedium
	btn.TextScaled = true
	btn.Text = `Buy {unit.name} ({unit.price})`
	btn.Parent = shopFrame
	btn.Activated:Connect(function()
		Remotes.BuyUnit:FireServer(id)
	end)
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