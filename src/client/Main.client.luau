--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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