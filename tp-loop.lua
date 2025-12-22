-- Roblox Solara Script
-- UI 2 colonnes (joueurs / offset) + TP ON/OFF + auto-cycle + spin très rapide + offset random rapide
-- Noir sur blanc

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ===== UI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TP_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Parent = ScreenGui
Main.Size = UDim2.new(0, 520, 0, 380)
Main.Position = UDim2.new(0, 20, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(255,255,255)
Main.BorderColor3 = Color3.fromRGB(0,0,0)
Main.BorderSizePixel = 1

local Header = Instance.new("TextLabel")
Header.Parent = Main
Header.Size = UDim2.new(1, 0, 0, 32)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(255,255,255)
Header.BorderColor3 = Color3.fromRGB(0,0,0)
Header.BorderSizePixel = 1
Header.TextColor3 = Color3.fromRGB(0,0,0)
Header.Font = Enum.Font.SourceSansBold
Header.TextSize = 18
Header.Text = "TP / CYCLE / OFFSET"

local Footer = Instance.new("TextLabel")
Footer.Parent = Main
Footer.Size = UDim2.new(1, 0, 0, 26)
Footer.Position = UDim2.new(0, 0, 1, -26)
Footer.BackgroundColor3 = Color3.fromRGB(255,255,255)
Footer.BorderColor3 = Color3.fromRGB(0,0,0)
Footer.BorderSizePixel = 1
Footer.TextColor3 = Color3.fromRGB(0,0,0)
Footer.Font = Enum.Font.SourceSans
Footer.TextSize = 14
Footer.Text = "Cible: - | Offset: (0,0,-3)"

local Body = Instance.new("Frame")
Body.Parent = Main
Body.Size = UDim2.new(1, 0, 1, -58)
Body.Position = UDim2.new(0, 0, 0, 32)
Body.BackgroundTransparency = 1

-- Colonnes
local Left = Instance.new("Frame")
Left.Parent = Body
Left.Size = UDim2.new(0, 300, 1, 0)
Left.Position = UDim2.new(0, 0, 0, 0)
Left.BackgroundColor3 = Color3.fromRGB(255,255,255)
Left.BorderColor3 = Color3.fromRGB(0,0,0)
Left.BorderSizePixel = 1

local Right = Instance.new("Frame")
Right.Parent = Body
Right.Size = UDim2.new(1, -304, 1, 0)
Right.Position = UDim2.new(0, 304, 0, 0)
Right.BackgroundColor3 = Color3.fromRGB(255,255,255)
Right.BorderColor3 = Color3.fromRGB(0,0,0)
Right.BorderSizePixel = 1

local function styleBtn(b)
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	b.TextColor3 = Color3.fromRGB(0,0,0)
	b.BorderColor3 = Color3.fromRGB(0,0,0)
	b.BorderSizePixel = 1
	b.Font = Enum.Font.SourceSans
	b.TextSize = 14
end

local function makeTitle(parent, text)
	local t = Instance.new("TextLabel")
	t.Parent = parent
	t.Size = UDim2.new(1, 0, 0, 24)
	t.BackgroundColor3 = Color3.fromRGB(255,255,255)
	t.BorderColor3 = Color3.fromRGB(0,0,0)
	t.BorderSizePixel = 1
	t.TextColor3 = Color3.fromRGB(0,0,0)
	t.Font = Enum.Font.SourceSansBold
	t.TextSize = 16
	t.Text = text
	return t
end

makeTitle(Left, "JOUEURS")
makeTitle(Right, "CONTROLES")

local LeftList = Instance.new("ScrollingFrame")
LeftList.Parent = Left
LeftList.Size = UDim2.new(1, 0, 1, -24)
LeftList.Position = UDim2.new(0, 0, 0, 24)
LeftList.BackgroundTransparency = 1
LeftList.BorderSizePixel = 0
LeftList.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftList.ScrollBarThickness = 6

local LeftLayout = Instance.new("UIListLayout")
LeftLayout.Parent = LeftList
LeftLayout.Padding = UDim.new(0, 4)

local RightPad = Instance.new("Frame")
RightPad.Parent = Right
RightPad.Size = UDim2.new(1, -10, 1, -34)
RightPad.Position = UDim2.new(0, 5, 0, 29)
RightPad.BackgroundTransparency = 1

local RightLayout = Instance.new("UIListLayout")
RightLayout.Parent = RightPad
RightLayout.Padding = UDim.new(0, 6)

-- ===== Etat =====
local selectedPlayer = nil
local tpEnabled = false
local autoCycle = false
local cycleIndex = 1
local lastSwitch = 0
local cycleInterval = 0.1

local offset = Vector3.new(0, 0, -3)

local spinEnabled = false
local spinSpeedDegPerSec = 2500 -- très vite

local randomOffsetEnabled = false
local randomLast = 0
local randomInterval = 0.05 -- très rapidement

local function updateFooter()
	local name = selectedPlayer and selectedPlayer.Name or "-"
	Footer.Text = string.format(
		"Cible: %s | Offset: (%.1f,%.1f,%.1f) | TP:%s AUTO:%s SPIN:%s RAND:%s",
		name, offset.X, offset.Y, offset.Z,
		tpEnabled and "ON" or "OFF",
		autoCycle and "ON" or "OFF",
		spinEnabled and "ON" or "OFF",
		randomOffsetEnabled and "ON" or "OFF"
	)
end

-- ===== Boutons contrôle (colonne droite) =====
local BtnTP = Instance.new("TextButton")
BtnTP.Parent = RightPad
BtnTP.Size = UDim2.new(1, 0, 0, 30)
BtnTP.Text = "TP: OFF"
styleBtn(BtnTP)
BtnTP.MouseButton1Click:Connect(function()
	tpEnabled = not tpEnabled
	BtnTP.Text = tpEnabled and "TP: ON" or "TP: OFF"
	updateFooter()
end)

local BtnAUTO = Instance.new("TextButton")
BtnAUTO.Parent = RightPad
BtnAUTO.Size = UDim2.new(1, 0, 0, 30)
BtnAUTO.Text = "AUTO CYCLE: OFF (0.1s)"
styleBtn(BtnAUTO)
BtnAUTO.MouseButton1Click:Connect(function()
	autoCycle = not autoCycle
	BtnAUTO.Text = autoCycle and "AUTO CYCLE: ON (0.1s)" or "AUTO CYCLE: OFF (0.1s)"
	updateFooter()
end)

local Sep1 = Instance.new("TextLabel")
Sep1.Parent = RightPad
Sep1.Size = UDim2.new(1, 0, 0, 20)
Sep1.BackgroundTransparency = 1
Sep1.TextColor3 = Color3.fromRGB(0,0,0)
Sep1.Font = Enum.Font.SourceSansBold
Sep1.TextSize = 14
Sep1.Text = "OFFSET (clic = +/-1)"

local OffsetGrid = Instance.new("Frame")
OffsetGrid.Parent = RightPad
OffsetGrid.Size = UDim2.new(1, 0, 0, 132)
OffsetGrid.BackgroundTransparency = 1

local function mkSmall(parent, text, onClick)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size = UDim2.new(0.5, -3, 0, 28)
	b.Text = text
	styleBtn(b)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function addOffset(v)
	offset += v
	updateFooter()
end

-- 3 lignes de 2 boutons
local b1 = mkSmall(OffsetGrid, "+X", function() addOffset(Vector3.new(1,0,0)) end)
b1.Position = UDim2.new(0, 0, 0, 0)
local b2 = mkSmall(OffsetGrid, "-X", function() addOffset(Vector3.new(-1,0,0)) end)
b2.Position = UDim2.new(0.5, 3, 0, 0)

local b3 = mkSmall(OffsetGrid, "+Y", function() addOffset(Vector3.new(0,1,0)) end)
b3.Position = UDim2.new(0, 0, 0, 34)
local b4 = mkSmall(OffsetGrid, "-Y", function() addOffset(Vector3.new(0,-1,0)) end)
b4.Position = UDim2.new(0.5, 3, 0, 34)

local b5 = mkSmall(OffsetGrid, "+Z", function() addOffset(Vector3.new(0,0,1)) end)
b5.Position = UDim2.new(0, 0, 0, 68)
local b6 = mkSmall(OffsetGrid, "-Z", function() addOffset(Vector3.new(0,0,-1)) end)
b6.Position = UDim2.new(0.5, 3, 0, 68)

local ResetOffset = Instance.new("TextButton")
ResetOffset.Parent = OffsetGrid
ResetOffset.Size = UDim2.new(1, 0, 0, 28)
ResetOffset.Position = UDim2.new(0, 0, 0, 102)
ResetOffset.Text = "RESET OFFSET (0,0,-3)"
styleBtn(ResetOffset)
ResetOffset.MouseButton1Click:Connect(function()
	offset = Vector3.new(0,0,-3)
	updateFooter()
end)

local Sep2 = Instance.new("TextLabel")
Sep2.Parent = RightPad
Sep2.Size = UDim2.new(1, 0, 0, 20)
Sep2.BackgroundTransparency = 1
Sep2.TextColor3 = Color3.fromRGB(0,0,0)
Sep2.Font = Enum.Font.SourceSansBold
Sep2.TextSize = 14
Sep2.Text = "EXTRAS"

local BtnSPIN = Instance.new("TextButton")
BtnSPIN.Parent = RightPad
BtnSPIN.Size = UDim2.new(1, 0, 0, 30)
BtnSPIN.Text = "SPIN: OFF (très rapide)"
styleBtn(BtnSPIN)
BtnSPIN.MouseButton1Click:Connect(function()
	spinEnabled = not spinEnabled
	BtnSPIN.Text = spinEnabled and "SPIN: ON (très rapide)" or "SPIN: OFF (très rapide)"
	updateFooter()
end)

local BtnRAND = Instance.new("TextButton")
BtnRAND.Parent = RightPad
BtnRAND.Size = UDim2.new(1, 0, 0, 30)
BtnRAND.Text = "OFFSET RANDOM: OFF (1..10 rapide)"
styleBtn(BtnRAND)
BtnRAND.MouseButton1Click:Connect(function()
	randomOffsetEnabled = not randomOffsetEnabled
	BtnRAND.Text = randomOffsetEnabled and "OFFSET RANDOM: ON (1..10 rapide)" or "OFFSET RANDOM: OFF (1..10 rapide)"
	updateFooter()
end)

-- ===== Liste joueurs (colonne gauche) =====
local entries = {}

local function clearEntries()
	for _,e in ipairs(entries) do
		if e.btn then e.btn:Destroy() end
	end
	entries = {}
end

local function highlightButtons()
	for _,e in ipairs(entries) do
		if e.player == selectedPlayer then
			e.btn.BackgroundColor3 = Color3.fromRGB(240,240,240)
		else
			e.btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
		end
	end
end

local function refreshPlayers()
	clearEntries()

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local btn = Instance.new("TextButton")
			btn.Parent = LeftList
			btn.Size = UDim2.new(1, -10, 0, 28)
			btn.Text = plr.Name
			styleBtn(btn)

			btn.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				highlightButtons()
				updateFooter()
			end)

			table.insert(entries, {player = plr, btn = btn})
		end
	end

	task.defer(function()
		local total = 0
		for _,c in ipairs(LeftList:GetChildren()) do
			if c:IsA("TextButton") then total += (c.Size.Y.Offset + LeftLayout.Padding.Offset) end
		end
		LeftList.CanvasSize = UDim2.new(0, 0, 0, math.max(total + 10, LeftList.AbsoluteSize.Y))
	end)

	highlightButtons()
	updateFooter()
end

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(plr)
	if selectedPlayer == plr then selectedPlayer = nil end
	refreshPlayers()
end)

-- ===== Boucles =====
local function getHRP(plr)
	local ch = plr and plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

updateFooter()

RunService.Heartbeat:Connect(function(dt)
	-- random offset rapide
	if randomOffsetEnabled and (tick() - randomLast >= randomInterval) then
		randomLast = tick()
		local rx = math.random(1,10) * (math.random(0,1) == 0 and -1 or 1)
		local ry = math.random(1,10) * (math.random(0,1) == 0 and -1 or 1)
		local rz = math.random(1,10) * (math.random(0,1) == 0 and -1 or 1)
		offset = Vector3.new(rx, ry, rz)
		updateFooter()
	end

	-- auto-cycle cible
	if autoCycle and (tick() - lastSwitch >= cycleInterval) and #entries > 0 then
		lastSwitch = tick()
		cycleIndex = (cycleIndex % #entries) + 1
		selectedPlayer = entries[cycleIndex].player
		highlightButtons()
		updateFooter()
	end

	-- TP
	if tpEnabled and selectedPlayer then
		local t = getHRP(selectedPlayer)
		local m = getHRP(LocalPlayer)
		if t and m then
			m.CFrame = t.CFrame * CFrame.new(offset)
		end
	end

	-- Spin (sur toi-même)
	if spinEnabled then
		local m = getHRP(LocalPlayer)
		if m then
			local addYaw = math.rad(spinSpeedDegPerSec) * dt
			m.CFrame = m.CFrame * CFrame.Angles(0, addYaw, 0)
		end
	end
end)

-- AJOUT : fenêtre déplaçable (drag & drop)
-- À placer APRÈS la création de Main (Frame principal)

local UserInputService = game:GetService("UserInputService")

local dragging = false
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	Main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

-- Drag via le header (barre du haut)
Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if dragging then
			update(input)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		update(input)
	end
end)

-- AJOUT : bouton X pour fermer la fenêtre et arrêter totalement le script
-- À placer APRÈS la création de Header

-- ===== STOP GLOBAL =====
local stopped = false
local connections = {}

local function stopScript()
	if stopped then return end
	stopped = true

	-- couper états
	tpEnabled = false
	autoCycle = false
	spinEnabled = false
	randomOffsetEnabled = false

	-- déconnecter événements
	for _,c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	connections = {}

	-- détruire UI
	if ScreenGui then
		ScreenGui:Destroy()
	end
end

-- ===== BOUTON X =====
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Header
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextColor3 = Color3.fromRGB(0,0,0)
CloseBtn.BorderColor3 = Color3.fromRGB(0,0,0)
CloseBtn.BorderSizePixel = 1
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 18

table.insert(connections, CloseBtn.MouseButton1Click:Connect(stopScript))

-- ===== MODIF BOUCLE PRINCIPALE =====
-- Remplacer RunService.Heartbeat:Connect(...) par :

local hbConn
hbConn = RunService.Heartbeat:Connect(function(dt)
	if stopped then
		hbConn:Disconnect()
		return
	end

	-- random offset rapide
	if randomOffsetEnabled and (tick() - randomLast >= randomInterval) then
		randomLast = tick()
		offset = Vector3.new(
			math.random(-10,10),
			math.random(-10,10),
			math.random(-10,10)
		)
		updateFooter()
	end

	-- auto-cycle
	if autoCycle and (tick() - lastSwitch >= cycleInterval) and #entries > 0 then
		lastSwitch = tick()
		cycleIndex = (cycleIndex % #entries) + 1
		selectedPlayer = entries[cycleIndex].player
		highlightButtons()
		updateFooter()
	end

	-- TP
	if tpEnabled and selectedPlayer then
		local t = getHRP(selectedPlayer)
		local m = getHRP(LocalPlayer)
		if t and m then
			m.CFrame = t.CFrame * CFrame.new(offset)
		end
	end

	-- Spin
	if spinEnabled then
		local m = getHRP(LocalPlayer)
		if m then
			m.CFrame = m.CFrame * CFrame.Angles(0, math.rad(spinSpeedDegPerSec) * dt, 0)
		end
	end
end)

table.insert(connections, hbConn)
