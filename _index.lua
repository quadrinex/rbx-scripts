-- CONFIG
local apiUrl = "https://api.github.com/repos/quadrinex/rbx-scripts/contents/"

-- SERVICES
local HttpService   = game:GetService("HttpService")
local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local CoreGui       = game:GetService("CoreGui")
local RunService    = game:GetService("RunService")
local Lighting      = game:GetService("Lighting")

local player = Players.LocalPlayer

-- STATE
local runningScripts = {}
local minimized = false
local currentTab = "Scripts"
local searchQuery = ""

-- ===== GUI (TOPMOST) =====
local guiParent = (gethui and gethui()) or CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "RepoLoader"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2147483647
gui.Parent = guiParent
if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end

local function setAllZ(root, z)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") then d.ZIndex = z end
	end
end

local function mk(cls, props, parent)
	local o = Instance.new(cls)
	for k,v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end

local function stroke(parent, t, col, tr)
	return mk("UIStroke", {
		Thickness = t or 1,
		Color = col or Color3.fromRGB(90,92,100),
		Transparency = tr == nil and 0.45 or tr
	}, parent)
end

-- ===== DEV-CONSOLE LOOK =====
local C_BG      = Color3.fromRGB(30, 32, 38)
local C_BG2     = Color3.fromRGB(26, 28, 34)
local C_LINE    = Color3.fromRGB(90, 92, 100)
local C_TEXT    = Color3.fromRGB(235,235,245)
local C_MUTED   = Color3.fromRGB(165,165,178)
local C_ACCENT  = Color3.fromRGB(0, 170, 255)

-- ===== MAIN FRAME =====
local frame = mk("Frame", {
	Size = UDim2.fromOffset(720, 420),
	Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(360, 210),
	BackgroundColor3 = C_BG,
	BackgroundTransparency = 0.18,
	BorderSizePixel = 0,
	Active = true,
}, gui)
stroke(frame, 1, C_LINE, 0.35)

-- ===== TOP BAR (Tabs) =====
local topBar = mk("Frame", {
	Size = UDim2.new(1,0,0,34),
	BackgroundColor3 = C_BG2,
	BackgroundTransparency = 0.10,
	BorderSizePixel = 0,
	Active = true,
}, frame)
stroke(topBar, 1, C_LINE, 0.45)

local tabScripts = mk("TextButton", {
	Position = UDim2.new(0,8,0,0),
	Size = UDim2.new(0,140,1,0),
	BackgroundTransparency = 1,
	Text = "Scripts",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = C_TEXT,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, topBar)

local tabSession = mk("TextButton", {
	Position = UDim2.new(0,156,0,0),
	Size = UDim2.new(0,140,1,0),
	BackgroundTransparency = 1,
	Text = "Session",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = C_MUTED,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, topBar)

local tabUnderline = mk("Frame", {
	Position = UDim2.new(0,8,1,-3),
	Size = UDim2.new(0,140,0,3),
	BackgroundColor3 = C_ACCENT,
	BorderSizePixel = 0,
}, topBar)

-- top-right buttons
local function topBtn(txt, xOffset)
	local b = mk("TextButton", {
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(26, 18),
		BackgroundTransparency = 1,
		Text = txt,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C_TEXT,
		BorderSizePixel = 0,
	}, topBar)
	return b
end

local stopBtn     = topBtn("S", -104)
local refreshBtn  = topBtn("R",  -72)
local minimizeBtn = topBtn("-",  -40)
local closeBtn    = topBtn("X",   -8)

-- ===== SEARCH ROW (no checkboxes) =====
local searchRow = mk("Frame", {
	Position = UDim2.new(0,0,0,34),
	Size = UDim2.new(1,0,0,30),
	BackgroundColor3 = C_BG2,
	BackgroundTransparency = 0.10,
	BorderSizePixel = 0,
}, frame)
stroke(searchRow, 1, C_LINE, 0.45)

local searchBox = mk("TextBox", {
	AnchorPoint = Vector2.new(1,0.5),
	Position = UDim2.new(1,-10,0.5,0),
	Size = UDim2.fromOffset(240, 22),
	BackgroundColor3 = Color3.fromRGB(18,18,22),
	BackgroundTransparency = 0.10,
	Text = "",
	PlaceholderText = "Search scripts",
	PlaceholderColor3 = C_MUTED,
	ClearTextOnFocus = false,
	TextEditable = true,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = C_TEXT,
	BorderSizePixel = 0,
}, searchRow)
stroke(searchBox, 1, C_LINE, 0.45)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = string.lower(searchBox.Text or "")
end)

-- ===== CONTENT AREA =====
local content = mk("Frame", {
	Position = UDim2.new(0,0,0,64),
	Size = UDim2.new(1,0,1,-64),
	BackgroundTransparency = 1,
}, frame)

-- Panel: Session (copyable)
local sessionPanel = mk("Frame", {
	Position = UDim2.new(0,8,0,8),
	Size = UDim2.new(1,-16,1,-16),
	BackgroundColor3 = Color3.fromRGB(20,20,24),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Visible = false,
}, content)
stroke(sessionPanel, 1, C_LINE, 0.45)

local sessionTitle = mk("TextLabel", {
	Position = UDim2.new(0,8,0,6),
	Size = UDim2.new(1,-16,0,18),
	BackgroundTransparency = 1,
	Text = "Session info",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C_TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, sessionPanel)

local sessionText = mk("TextBox", {
	Position = UDim2.new(0,8,0,28),
	Size = UDim2.new(1,-16,1,-36),
	BackgroundTransparency = 1,

	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = C_MUTED,

	TextWrapped = true,
	MultiLine = true,
	ClearTextOnFocus = false,
	TextEditable = false,
	Selectable = true,
	Text = "",
}, sessionPanel)

-- Panel: Scripts
local scriptsPanel = mk("Frame", {
	Position = UDim2.new(0,8,0,8),
	Size = UDim2.new(1,-16,1,-16),
	BackgroundColor3 = Color3.fromRGB(18,18,22),
	BackgroundTransparency = 0.10,
	BorderSizePixel = 0,
	Visible = true,
}, content)
stroke(scriptsPanel, 1, C_LINE, 0.45)

local scriptsHeader = mk("TextLabel", {
	Position = UDim2.new(0,8,0,6),
	Size = UDim2.new(1,-120,0,18),
	BackgroundTransparency = 1,
	Text = "Scripts (.lua)",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C_TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, scriptsPanel)

local statusPill = mk("TextLabel", {
	AnchorPoint = Vector2.new(1,0),
	Position = UDim2.new(1,-8,0,6),
	Size = UDim2.fromOffset(140, 18),
	BackgroundColor3 = Color3.fromRGB(20,30,22),
	BackgroundTransparency = 0.15,
	Text = "Ready",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(140,255,170),
	BorderSizePixel = 0,
}, scriptsPanel)
stroke(statusPill, 1, C_LINE, 0.55)

local scroll = mk("ScrollingFrame", {
	Position = UDim2.new(0,8,0,28),
	Size = UDim2.new(1,-16,1,-36),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0,0,0,0),
	ScrollBarThickness = 6,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, scriptsPanel)

local layout = mk("UIListLayout", {
	Padding = UDim.new(0,6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 6)
end)

-- ===== REOPEN BUTTON =====
local reopenBtn = mk("TextButton", {
	Size = UDim2.fromOffset(140, 28),
	Position = UDim2.new(0,8,1,-36),
	BackgroundColor3 = C_BG2,
	BackgroundTransparency = 0.10,
	TextColor3 = C_TEXT,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Text = "Repo Loader",
	BorderSizePixel = 0,
	Visible = false,
	AutoButtonColor = true,
}, gui)
stroke(reopenBtn, 1, C_LINE, 0.45)

-- ===== DRAG + RESIZE =====
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local minW, minH = 520, 320
local maxW, maxH = 1100, 780
local resizeHandle = mk("TextButton", {
	AnchorPoint = Vector2.new(1,1),
	Position = UDim2.new(1,0,1,0),
	Size = UDim2.fromOffset(14,14),
	BackgroundTransparency = 1,
	Text = "",
	BorderSizePixel = 0,
}, frame)

local resizing = false
local rsStart, szStart
resizeHandle.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		rsStart = i.Position
		szStart = frame.AbsoluteSize
	end
end)
UIS.InputChanged:Connect(function(i)
	if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - rsStart
		local w = math.clamp(szStart.X + d.X, minW, maxW)
		local h = math.clamp(szStart.Y + d.Y, minH, maxH)
		frame.Size = UDim2.fromOffset(w, h)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
end)

-- ===== INFO =====
local function fmtBool(b) return b and "true" or "false" end

local function getSessionInfo()
	local ping = "N/A"
	pcall(function()
		if player and player.GetNetworkPing then
			ping = string.format("%.0f ms", player:GetNetworkPing() * 1000)
		end
	end)

	local serverType = "Public"
	pcall(function()
		if game.PrivateServerId and game.PrivateServerId ~= "" then serverType = "PrivateServer"
		elseif game.VIPServerId and game.VIPServerId ~= "" then serverType = "VIPServer"
		end
	end)

	local httpEnabled = "N/A"
	pcall(function() httpEnabled = fmtBool(HttpService.HttpEnabled) end)

	local exec = "N/A"
	pcall(function()
		if identifyexecutor then exec = identifyexecutor()
		elseif getexecutorname then exec = getexecutorname()
		end
	end)

	return {
		playerName = player and player.Name or "N/A",
		userId = player and tostring(player.UserId) or "N/A",
		accountAge = player and tostring(player.AccountAge) or "N/A",
		placeId = tostring(game.PlaceId),
		gameId = tostring(game.GameId),
		jobId = tostring(game.JobId),
		serverType = serverType,
		ping = ping,
		httpEnabled = httpEnabled,
		executor = exec,
	}
end

local function renderSession(info, fps)
	sessionText.Text =
		("Player: %s (UserId: %s) | AccountAge: %s days\n"):format(info.playerName, info.userId, info.accountAge) ..
		("PlaceId: %s | GameId: %s\n"):format(info.placeId, info.gameId) ..
		("JobId: %s\n"):format(info.jobId) ..
		("Server: %s | Ping: %s | FPS: %s\n"):format(info.serverType, info.ping, fps or "N/A") ..
		("HttpEnabled: %s | Executor: %s"):format(info.httpEnabled, info.executor)
end

-- ===== LIST / ITEMS =====
local function clearList()
	for _,v in ipairs(scroll:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
end

local function makeItem(name, onRun)
	local row = mk("Frame", {
		Size = UDim2.new(1,0,0,34),
		BackgroundColor3 = Color3.fromRGB(22,22,26),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
	}, scroll)
	stroke(row, 1, C_LINE, 0.60)

	mk("TextLabel", {
		Position = UDim2.new(0,8,0,0),
		Size = UDim2.new(1,-120,1,0),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = C_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local runBtn = mk("TextButton", {
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,-8,0.5,0),
		Size = UDim2.fromOffset(88, 22),
		BackgroundColor3 = Color3.fromRGB(35, 55, 95),
		BackgroundTransparency = 0.10,
		Text = "Run",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C_TEXT,
		BorderSizePixel = 0,
		AutoButtonColor = true,
	}, row)
	stroke(runBtn, 1, C_LINE, 0.55)

	runBtn.MouseButton1Click:Connect(onRun)
end

local function setStatus(t)
	statusPill.Text = t
end

local function passesSearch(name)
	if searchQuery == "" then return true end
	return string.find(string.lower(name), searchQuery, 1, true) ~= nil
end

local function loadRepo()
	setStatus("Loading…")
	clearList()

	local ok, bodyOrErr = pcall(function() return game:HttpGet(apiUrl) end)
	if not ok then
		setStatus("HTTP error")
		makeItem(("Failed: %s"):format(tostring(bodyOrErr)), function() end)
		return
	end

	local files
	ok, files = pcall(function() return HttpService:JSONDecode(bodyOrErr) end)
	if not ok or type(files) ~= "table" then
		setStatus("Decode error")
		makeItem("JSON decode failed", function() end)
		return
	end

	local count = 0
	for _,file in ipairs(files) do
		if file.type == "file" and type(file.name) == "string" and file.name:match("%.lua$") then
			if passesSearch(file.name) then
				count += 1
				makeItem(file.name, function()
					setStatus("Running: "..file.name)
					local src = game:HttpGet(file.download_url)

					local env = { __STOP = false }
					setmetatable(env, { __index = getfenv() })

					local fn = loadstring(src)
					setfenv(fn, env)
					task.spawn(fn)

					runningScripts[file.name] = env
				end)
			end
		end
	end

	setStatus("Ready ("..count..")")
	setAllZ(gui, 3000)
end

-- Update list while typing
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = string.lower(searchBox.Text or "")
	if currentTab == "Scripts" then loadRepo() end
end)

-- ===== TAB LOGIC =====
local function setTab(tab)
	currentTab = tab
	if tab == "Scripts" then
		tabScripts.TextColor3 = C_TEXT
		tabSession.TextColor3 = C_MUTED
		tabUnderline.Position = UDim2.new(0,8,1,-3)
		tabUnderline.Size = UDim2.new(0,140,0,3)

		scriptsPanel.Visible = true
		sessionPanel.Visible = false
		searchRow.Visible = true

		loadRepo()
	else
		tabScripts.TextColor3 = C_MUTED
		tabSession.TextColor3 = C_TEXT
		tabUnderline.Position = UDim2.new(0,156,1,-3)
		tabUnderline.Size = UDim2.new(0,140,0,3)

		scriptsPanel.Visible = false
		sessionPanel.Visible = true
		searchRow.Visible = false
	end
end

tabScripts.MouseButton1Click:Connect(function() setTab("Scripts") end)
tabSession.MouseButton1Click:Connect(function() setTab("Session") end)

-- ===== BUTTONS =====
closeBtn.MouseButton1Click:Connect(function()
	if blur then blur:Destroy() end
	gui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = true
	frame.Visible = false
	reopenBtn.Visible = true
end)

reopenBtn.MouseButton1Click:Connect(function()
	minimized = false
	frame.Visible = true
	reopenBtn.Visible = false
	setAllZ(gui, 3000)
end)

refreshBtn.MouseButton1Click:Connect(function()
	if currentTab == "Scripts" then loadRepo() end
end)

stopBtn.MouseButton1Click:Connect(function()
	for _,env in pairs(runningScripts) do env.__STOP = true end
	table.clear(runningScripts)
	setStatus("Stopped all")
end)

-- ===== LIVE SESSION (FPS) =====
local last = os.clock()
local frames = 0
local cached = getSessionInfo()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = os.clock()
	if now - last >= 0.5 then
		local fps = math.floor(frames / (now - last) + 0.5)
		frames = 0
		last = now

		pcall(function()
			if player and player.GetNetworkPing then
				cached.ping = string.format("%.0f ms", player:GetNetworkPing() * 1000)
			end
		end)

		renderSession(cached, tostring(fps))
	end
end)

-- INIT
renderSession(cached, "…")
setTab("Scripts")
setAllZ(gui, 3000)
