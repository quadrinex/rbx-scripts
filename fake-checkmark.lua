local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CUSTOM_NAME = player.DisplayName .. ""

local followConnection
local currentModel

local function createFake(character)
	local head = character:WaitForChild("Head")
  
	if followConnection then
		followConnection:Disconnect()
	end
	if currentModel then
		currentModel:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "LocalFakeNPC"
	model.Parent = workspace
	currentModel = model

	local fakeHead = Instance.new("Part")
	fakeHead.Name = "Head"
	fakeHead.Size = Vector3.new(2,1,1)
	fakeHead.Transparency = 0.99
	fakeHead.Anchored = true
	fakeHead.CanCollide = false
	fakeHead.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = CUSTOM_NAME
	humanoid.NameDisplayDistance = 100
	humanoid.Parent = model

	model.PrimaryPart = fakeHead

	followConnection = RunService.RenderStepped:Connect(function()
		if head and fakeHead and model.Parent then
			fakeHead.CFrame = head.CFrame
		end
	end)
end

local function ensureExists()
	while true do
		task.wait(1)
		if player.Character then
			if not workspace:FindFirstChild("LocalFakeNPC") then
				createFake(player.Character)
			end
		end
	end
end

player.CharacterAdded:Connect(function(char)
	task.wait(1)
	createFake(char)
end)

if player.Character then
	createFake(player.Character)
end

task.spawn(ensureExists)
