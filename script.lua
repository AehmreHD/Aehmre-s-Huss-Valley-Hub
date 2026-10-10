-- // AEHMRE'S HUSS VALLEY HUB - CAMERA FOV //
-- MADE BY: Emre_31er

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local alive = true

local Settings = {
	ApplySpeed = false,
	Speed = 16,
	ApplyJumpPower = false,
	JumpPower = 50,
	FieldOfView = 70,
	InvisSpeed = 12,
	ShowGlobalESP = false,
	ShowTeamESP = false,
	Invisibility = false,
	InvisibilityMode = "Air"
}

local Connections = {}
local CharacterConnections = {}
local ESPConnections = {}
local ESPHighlights = {}
local UIRefreshers = {}
local InvisibilityConnection = nil
local InvisibilityCharacterConnection = nil
local InvisTrack = nil
local InvisParts = {}
local InvisOriginalTransparency = {}
local InvisLastGroundY = nil
local InvisCurrentCharacter = nil
local InvisCurrentRoot = nil
local InvisCurrentHumanoid = nil
local InvisOriginalCameraSubject = nil
local InvisOriginalCameraOffset = nil
local InvisModeActive = nil
local InvisibilityWarning = nil
local CurrentHumanoid = nil
local OriginalWalkSpeed = nil
local OriginalJumpPower = nil
local OriginalUseJumpPower = nil
local OriginalFieldOfView = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local VisibleTab = "Character"
local IsMinimized = false
local NoticeSerial = 0

local Colors = {
	Main = Color3.fromRGB(9, 10, 13),
	Panel = Color3.fromRGB(15, 16, 21),
	Card = Color3.fromRGB(21, 22, 28),
	Hover = Color3.fromRGB(31, 32, 40),
	Input = Color3.fromRGB(35, 37, 45),
	Border = Color3.fromRGB(67, 69, 80),
	Accent = Color3.fromRGB(224, 49, 64),
	White = Color3.fromRGB(245, 246, 249),
	Muted = Color3.fromRGB(158, 161, 173),
	Green = Color3.fromRGB(72, 219, 126)
}

local function Connect(signal, callback, registry)
	local connection = signal:Connect(callback)
	table.insert(registry or Connections, connection)
	return connection
end

local function DisconnectAll(registry)
	for _, connection in ipairs(registry) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(registry)
end

local function New(className, parent, props)
	local object = Instance.new(className)
	for property, value in pairs(props or {}) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function Corner(parent, radius)
	return New("UICorner", parent, {CornerRadius = UDim.new(0, radius or 6)})
end

local function Stroke(parent, color, thickness)
	return New("UIStroke", parent, {Color = color or Colors.Border, Thickness = thickness or 1})
end

local function Label(parent, text, size, position, fontSize, color, font)
	return New("TextLabel", parent, {
		Size = size,
		Position = position,
		Text = text,
		BackgroundTransparency = 1,
		TextColor3 = color or Colors.White,
		TextSize = fontSize or 12,
		Font = font or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd
	})
end

local function Button(parent, title, size, position, color, fontSize, square)
	local button = New("TextButton", parent, {
		Size = size,
		Position = position,
		Text = title,
		BackgroundColor3 = color or Colors.Input,
		TextColor3 = Colors.White,
		TextSize = fontSize or 11,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = true
	})
	if not square then Corner(button, 5) end
	Stroke(button, Colors.Border)
	return button
end

local function GetCharacter()
	return LocalPlayer.Character
end

local function GetCharacterParts()
	local character = GetCharacter()
	return character,
		character and character:FindFirstChildOfClass("Humanoid") or nil,
		character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function EnforceCharacterValues()
	if not alive then return end
	local character, humanoid = GetCharacterParts()
	if not character or not humanoid then return end
	if Settings.ApplySpeed and humanoid.WalkSpeed ~= Settings.Speed then
		humanoid.WalkSpeed = Settings.Speed
	end
	if Settings.ApplyJumpPower then
		if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
		if humanoid.JumpPower ~= Settings.JumpPower then
			humanoid.JumpPower = Settings.JumpPower
		end
	end
end

local function EnforceCameraFieldOfView()
	if not alive then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local requested = math.clamp(tonumber(Settings.FieldOfView) or 70, 10, 300)
	local supported = math.clamp(requested, 10, 120)
	if math.abs(camera.FieldOfView - supported) > 0.001 then
		camera.FieldOfView = supported
	end
end

local function BindHumanoid(character)
	DisconnectAll(CharacterConnections)
	CurrentHumanoid = nil
	OriginalWalkSpeed = nil
	OriginalJumpPower = nil
	OriginalUseJumpPower = nil
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not alive or not humanoid or LocalPlayer.Character ~= character then return end
	CurrentHumanoid = humanoid
	OriginalWalkSpeed = humanoid.WalkSpeed
	OriginalJumpPower = humanoid.JumpPower
	OriginalUseJumpPower = humanoid.UseJumpPower
	Connect(humanoid:GetPropertyChangedSignal("WalkSpeed"), function()
		if alive and Settings.ApplySpeed and humanoid == CurrentHumanoid and humanoid.WalkSpeed ~= Settings.Speed then
			humanoid.WalkSpeed = Settings.Speed
		end
	end, CharacterConnections)
	Connect(humanoid:GetPropertyChangedSignal("JumpPower"), function()
		if alive and Settings.ApplyJumpPower and humanoid == CurrentHumanoid and humanoid.JumpPower ~= Settings.JumpPower then
			humanoid.JumpPower = Settings.JumpPower
		end
	end, CharacterConnections)
	Connect(humanoid:GetPropertyChangedSignal("UseJumpPower"), function()
		if alive and Settings.ApplyJumpPower and humanoid == CurrentHumanoid and not humanoid.UseJumpPower then
			humanoid.UseJumpPower = true
		end
	end, CharacterConnections)
	EnforceCharacterValues()
end

local function RestoreCharacterValues()
	local humanoid = CurrentHumanoid
	if humanoid and humanoid.Parent then
		if OriginalWalkSpeed ~= nil then humanoid.WalkSpeed = OriginalWalkSpeed end
		if OriginalJumpPower ~= nil then humanoid.JumpPower = OriginalJumpPower end
		if OriginalUseJumpPower ~= nil then humanoid.UseJumpPower = OriginalUseJumpPower end
	end
end

local function RemoveESP(player)
	local object = ESPHighlights[player]
	if object then
		ESPHighlights[player] = nil
		if object.Parent then object:Destroy() end
	end
end

local function UpdateESP(player)
	if player == LocalPlayer then return end
	if not alive or (not Settings.ShowGlobalESP and not Settings.ShowTeamESP) then
		RemoveESP(player)
		return
	end
	local character = player.Character
	if not character or not character.Parent then
		RemoveESP(player)
		return
	end
	local highlight = ESPHighlights[player]
	if highlight and highlight.Parent ~= character then
		RemoveESP(player)
		highlight = nil
	end
	if not highlight then
		highlight = New("Highlight", character, {
			Name = "HussValleyCharacterESP",
			Adornee = character,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillTransparency = 0.65,
			OutlineTransparency = 0
		})
		ESPHighlights[player] = highlight
	end
	local color = Settings.ShowGlobalESP and Colors.White or (player.Neutral and Colors.White or player.TeamColor.Color)
	highlight.FillColor = color
	highlight.OutlineColor = color
end

local function RefreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		UpdateESP(player)
	end
end

local function BindESPPlayer(player)
	if player == LocalPlayer then return end
	Connect(player.CharacterAdded, function(character)
		if not alive then return end
		RemoveESP(player)
		task.defer(function()
			if alive and player.Character == character then UpdateESP(player) end
		end)
	end, ESPConnections)
	Connect(player.CharacterRemoving, function()
		RemoveESP(player)
	end, ESPConnections)
	Connect(player:GetPropertyChangedSignal("TeamColor"), function()
		UpdateESP(player)
	end, ESPConnections)
	Connect(player:GetPropertyChangedSignal("Neutral"), function()
		UpdateESP(player)
	end, ESPConnections)
	UpdateESP(player)
end

local function ReleaseInvisibility()
	if InvisibilityConnection then
		InvisibilityConnection:Disconnect()
		InvisibilityConnection = nil
	end
	if InvisibilityCharacterConnection then
		InvisibilityCharacterConnection:Disconnect()
		InvisibilityCharacterConnection = nil
	end
	if InvisTrack then
		pcall(function() InvisTrack:Stop() InvisTrack:Destroy() end)
		InvisTrack = nil
	end
	for part, transparency in pairs(InvisOriginalTransparency) do
		if part and part.Parent then part.Transparency = transparency end
	end
	table.clear(InvisOriginalTransparency)
	table.clear(InvisParts)
	local root = InvisCurrentRoot
	local humanoid = InvisCurrentHumanoid
	if InvisModeActive == "Bottom" and root and root.Parent and InvisLastGroundY then
		local p = root.Position
		root.CFrame = CFrame.new(p.X, InvisLastGroundY + 3, p.Z) * (root.CFrame - root.CFrame.Position)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if humanoid and humanoid.Parent and InvisOriginalCameraOffset then
		humanoid.CameraOffset = InvisOriginalCameraOffset
	end
	local camera = workspace.CurrentCamera
	if camera and InvisModeActive then
		local _, currentHumanoid = GetCharacterParts()
		local originalSubject = InvisOriginalCameraSubject
		camera.CameraSubject = (originalSubject and originalSubject.Parent and originalSubject) or currentHumanoid
	end
	if InvisibilityWarning then InvisibilityWarning.Visible = false end
	InvisLastGroundY = nil
	InvisModeActive = nil
	InvisCurrentRoot = nil
	InvisCurrentHumanoid = nil
	InvisCurrentCharacter = nil
	InvisOriginalCameraSubject = nil
	InvisOriginalCameraOffset = nil
end

local function TrackInvisPart(object)
	if object:IsA("BasePart") and InvisOriginalTransparency[object] == nil then
		InvisOriginalTransparency[object] = object.Transparency
		InvisParts[#InvisParts + 1] = object
	end
end

local function StartInvisibility()
	ReleaseInvisibility()
	if not alive or not Settings.Invisibility then return end
	local character, humanoid, root = GetCharacterParts()
	if not character or not humanoid or not root or humanoid.Health <= 0 then return end
	local mode = Settings.InvisibilityMode
	if mode == "Air" and humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		Settings.Invisibility = false
		warn("[Huss Valley] Air invisibility requires an R6 character")
		return
	end
	InvisCurrentCharacter = character
	InvisCurrentHumanoid = humanoid
	InvisCurrentRoot = root
	InvisModeActive = mode
	InvisLastGroundY = nil
	local camera = workspace.CurrentCamera
	InvisOriginalCameraSubject = camera and camera.CameraSubject or nil
	InvisOriginalCameraOffset = humanoid.CameraOffset
	for _, object in ipairs(character:GetDescendants()) do TrackInvisPart(object) end
	InvisibilityCharacterConnection = character.DescendantAdded:Connect(TrackInvisPart)
	if mode == "Bottom" then
		if camera then camera.CameraSubject = humanoid end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character}
		params.IgnoreWater = true
		InvisibilityConnection = RunService.Heartbeat:Connect(function(dt)
			if not alive or not Settings.Invisibility or Settings.InvisibilityMode ~= "Bottom" then return end
			if LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then return end
			local nextPosition = root.Position
			if humanoid.MoveDirection.Magnitude > 0 then
				nextPosition += humanoid.MoveDirection.Unit * Settings.InvisSpeed * dt
			end
			local hit = workspace:Raycast(nextPosition + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), params)
			if hit then InvisLastGroundY = hit.Position.Y end
			if InvisLastGroundY then
				local lookVector = camera and camera.CFrame.LookVector or root.CFrame.LookVector
				local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
				if flatLook.Magnitude <= 0.1 then flatLook = Vector3.new(0, 0, -1) end
				nextPosition = Vector3.new(nextPosition.X, InvisLastGroundY - 3.25, nextPosition.Z)
				root.CFrame = CFrame.new(nextPosition, nextPosition + flatLook.Unit)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)
		print("[Huss Valley] Invisibility: Bottom (local character test)")
	else
		if camera then camera.CameraSubject = root end
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://215384594"
		local ok, track = pcall(function()
			local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
			return animator:LoadAnimation(animation)
		end)
		animation:Destroy()
		if ok then
			InvisTrack = track
			InvisTrack.Priority = Enum.AnimationPriority.Action4
		end
		local lastTransparencyUpdate = 0
		InvisibilityConnection = RunService.Heartbeat:Connect(function(dt)
			if not alive or not Settings.Invisibility or Settings.InvisibilityMode ~= "Air" then return end
			if LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then return end
			local activeCamera = workspace.CurrentCamera
			if humanoid.MoveDirection.Magnitude > 0 then
				root.CFrame += humanoid.MoveDirection.Unit * Settings.InvisSpeed * dt
			end
			if InvisibilityWarning then
				InvisibilityWarning.Visible = humanoid.FloorMaterial == Enum.Material.Air
			end
			local originalCF = root.CFrame
			local originalOffset = humanoid.CameraOffset
			local flatLook = activeCamera and activeCamera.CFrame.LookVector or originalCF.LookVector
			flatLook = Vector3.new(flatLook.X, 0, flatLook.Z)
			if flatLook.Magnitude <= 0.1 then flatLook = Vector3.new(0, 0, -1) end
			root.CFrame = CFrame.new(originalCF.Position, originalCF.Position + flatLook.Unit) * CFrame.Angles(math.rad(90), 0, 0)
			humanoid.CameraOffset = Vector3.new(0, 1.44, 0)
			if InvisTrack then
				pcall(function()
					if not InvisTrack.IsPlaying then InvisTrack:Play(0) end
					InvisTrack:AdjustSpeed(0)
					InvisTrack.TimePosition = 0.3
				end)
			end
			RunService.RenderStepped:Wait()
			if not root.Parent or LocalPlayer.Character ~= character then return end
			humanoid.CameraOffset = originalOffset
			root.CFrame = originalCF
			if not alive or not Settings.Invisibility or Settings.InvisibilityMode ~= "Air" then return end
			if InvisTrack then pcall(function() InvisTrack:Stop(0) end) end
			lastTransparencyUpdate += dt
			if lastTransparencyUpdate >= 0.2 then
				lastTransparencyUpdate = 0
				for _, part in ipairs(InvisParts) do
					if part and part.Parent and part.Transparency ~= 1 and part.Transparency ~= 0.5 then
						part.Transparency = 0.5
					end
				end
			end
		end)
		print("[Huss Valley] Invisibility: Air (R6 local character test)")
	end
end

local function SetSetting(key, value)
	if not alive or Settings[key] == nil then return end
	local oldValue = Settings[key]
	Settings[key] = value
	if key == "ApplySpeed" and not value and oldValue and CurrentHumanoid and CurrentHumanoid.Parent and OriginalWalkSpeed ~= nil then
		CurrentHumanoid.WalkSpeed = OriginalWalkSpeed
	end
	if key == "ApplyJumpPower" and not value and oldValue and CurrentHumanoid and CurrentHumanoid.Parent then
		if OriginalJumpPower ~= nil then CurrentHumanoid.JumpPower = OriginalJumpPower end
		if OriginalUseJumpPower ~= nil then CurrentHumanoid.UseJumpPower = OriginalUseJumpPower end
	end
	if key == "ShowGlobalESP" or key == "ShowTeamESP" then RefreshESP() end
	if key == "Invisibility" or key == "InvisibilityMode" then
		if Settings.Invisibility then StartInvisibility() else ReleaseInvisibility() end
	end
	if key == "ApplySpeed" or key == "Speed" or key == "ApplyJumpPower" or key == "JumpPower" then
		EnforceCharacterValues()
	end
	if key == "FieldOfView" then
		EnforceCameraFieldOfView()
	end
	for _, refresh in ipairs(UIRefreshers) do refresh() end
end

local Existing = PlayerGui:FindFirstChild("AehmresHussValleyHub")
if Existing then Existing:Destroy() end

local ScreenGui = New("ScreenGui", PlayerGui, {
	Name = "AehmresHussValleyHub",
	ResetOnSpawn = false,
	DisplayOrder = 999995,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = false
})

local MouseUnlocked = false
local PreviousMouseBehavior = Enum.MouseBehavior.Default
local PreviousMouseIconEnabled = true

local MouseUnlockModal = New("TextButton", ScreenGui, {
	Name = "MouseUnlockModal",
	Size = UDim2.fromOffset(1, 1),
	Position = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
	TextTransparency = 1,
	Text = "",
	BorderSizePixel = 0,
	Active = true,
	Selectable = false,
	AutoButtonColor = false,
	Visible = true,
	Modal = false
})

local function SetMouseUnlocked(enabled)
	enabled = enabled == true
	if MouseUnlocked == enabled then return end

	if enabled then
		PreviousMouseBehavior = UserInputService.MouseBehavior
		PreviousMouseIconEnabled = UserInputService.MouseIconEnabled
		MouseUnlocked = true
		MouseUnlockModal.Modal = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		MouseUnlocked = false
		MouseUnlockModal.Modal = false
		UserInputService.MouseBehavior = PreviousMouseBehavior
		UserInputService.MouseIconEnabled = PreviousMouseIconEnabled
	end

	print("[Huss Valley] Mouse " .. (MouseUnlocked and "UNLOCKED" or "RESTORED") .. " | N = toggle")
end

Connect(RunService.RenderStepped, function()
	if not alive or not MouseUnlocked or not MouseUnlockModal.Parent then return end
	if not MouseUnlockModal.Modal then MouseUnlockModal.Modal = true end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	if not UserInputService.MouseIconEnabled then
		UserInputService.MouseIconEnabled = true
	end
end)

local Main = New("Frame", ScreenGui, {
	Name = "MainWindow",
	Size = UDim2.fromOffset(550, 420),
	Position = UDim2.new(0.5, -275, 0.5, -210),
	BackgroundColor3 = Colors.Main,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true
})
Corner(Main, 9)
Stroke(Main, Colors.Accent, 1.5)

local Header = New("Frame", Main, {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Active = true
})
Label(Header, "Aehmre's Huss Valley Hub", UDim2.new(1, -115, 1, 0), UDim2.fromOffset(15, 0), 14, Colors.White, Enum.Font.GothamBold)

local HeaderButtonSize = UserInputService.TouchEnabled and 32 or 25
local CloseButton = Button(Header, "X", UDim2.fromOffset(HeaderButtonSize, HeaderButtonSize), UDim2.new(1, -(HeaderButtonSize + 8), 0.5, -HeaderButtonSize / 2), Color3.fromRGB(52, 26, 31), 12)
local MinimizeButton = Button(Header, "−", UDim2.fromOffset(HeaderButtonSize, HeaderButtonSize), UDim2.new(1, -(HeaderButtonSize * 2 + 14), 0.5, -HeaderButtonSize / 2), Colors.Input, 15)

local Body = New("Frame", Main, {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -42),
	Position = UDim2.fromOffset(0, 42),
	BackgroundTransparency = 1
})

local Sidebar = New("ScrollingFrame", Body, {
	Name = "Sidebar",
	Size = UDim2.new(0, 165, 1, 0),
	CanvasSize = UDim2.fromOffset(0, 295),
	ScrollBarThickness = 2,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0
})

local SidebarTitle = Label(Sidebar, "NAVIGATION", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), 10, Colors.Muted, Enum.Font.GothamBold)

local Content = New("Frame", Body, {
	Name = "PageContainer",
	Position = UDim2.fromOffset(165, 0),
	Size = UDim2.new(1, -165, 1, 0),
	BackgroundTransparency = 1
})

local Notification = New("Frame", ScreenGui, {
	Name = "InterfaceClosedNotification",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(340, 76),
	Position = UDim2.new(1, -18, 1, -18),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30
})
Corner(Notification, 7)
Stroke(Notification, Colors.Green, 1.5)

InvisibilityWarning = New("TextLabel", ScreenGui, {
	Name = "AirInvisibilityWarning",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(300, 35),
	Position = UDim2.new(0.5, 0, 0.87, 0),
	BackgroundTransparency = 1,
	Text = "⚠️ YOU ARE VISIBLE ⚠️",
	TextColor3 = Color3.fromRGB(255, 230, 35),
	TextStrokeTransparency = 0.3,
	TextSize = 21,
	Font = Enum.Font.GothamBold,
	Visible = false
})
local NoticeText = Label(Notification, "The interface is closed. Press L to reopen.", UDim2.new(1, -50, 1, -10), UDim2.fromOffset(36, 5), 11, Colors.White, Enum.Font.GothamSemibold)
NoticeText.TextWrapped = true
NoticeText.TextTruncate = Enum.TextTruncate.None
local NoticeClose = Button(Notification, "X", UDim2.fromOffset(23, 23), UDim2.fromOffset(6, 6), Colors.Input, 10)
NoticeClose.ZIndex = 31

local function ShowNotice(message)
	NoticeSerial += 1
	local token = NoticeSerial
	NoticeText.Text = message
	Notification.Visible = true
	task.delay(4, function()
		if alive and token == NoticeSerial then Notification.Visible = false end
	end)
end

Connect(NoticeClose.MouseButton1Click, function()
	NoticeSerial += 1
	Notification.Visible = false
end)

local PageFrames = {}
local TabButtons = {}
local TabNames = {"Character", "Visuals & ESP", "Camera", "More coming soon!", "SETTINGS"}

local function RefreshTabs()
	for name, button in pairs(TabButtons) do
		local selected = VisibleTab == name
		button.BackgroundColor3 = selected and Colors.Accent or Colors.Card
		button.TextColor3 = selected and Colors.White or Colors.Muted
	end
	for name, frame in pairs(PageFrames) do frame.Visible = VisibleTab == name end
end

local function AddPage(name, index)
	local tab = Button(Sidebar, name, UDim2.new(1, -18, 0, 35), UDim2.fromOffset(9, 45 + (index - 1) * 43), Colors.Card, 11)
	tab.TextXAlignment = Enum.TextXAlignment.Left
	New("UIPadding", tab, {PaddingLeft = UDim.new(0, 10)})
	TabButtons[name] = tab
	Connect(tab.MouseButton1Click, function()
		VisibleTab = name
		RefreshTabs()
	end)

	local page = New("ScrollingFrame", Content, {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = name == VisibleTab
	})
	New("UIPadding", page, {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14)
	})
	New("UIListLayout", page, {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 9),
		HorizontalAlignment = Enum.HorizontalAlignment.Left
	})
	PageFrames[name] = page
	return page
end

local CharacterPage = AddPage(TabNames[1], 1)
local VisualsPage = AddPage(TabNames[2], 2)
local CameraPage = AddPage(TabNames[3], 3)
local ComingPage = AddPage(TabNames[4], 4)
local SettingsPage = AddPage(TabNames[5], 5)

local function Card(page, title, height)
	local card = New("Frame", page, {
		Name = title,
		Size = UDim2.new(1, -5, 0, height or 65),
		BackgroundColor3 = Colors.Card,
		BorderSizePixel = 0
	})
	Corner(card, 6)
	Stroke(card, Colors.Border, 1)
	return card
end

local function AddSection(page, text)
	local section = New("TextLabel", page, {
		Name = "Section",
		Size = UDim2.new(1, -5, 0, 20),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Colors.Accent,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return section
end

local function AddToggle(page, title, description, key)
	local card = Card(page, title, 60)
	Label(card, title, UDim2.new(1, -95, 0, 22), UDim2.fromOffset(12, 8), 12, Colors.White, Enum.Font.GothamBold)
	Label(card, description, UDim2.new(1, -92, 0, 20), UDim2.fromOffset(12, 32), 9, Colors.Muted)
	local button = Button(card, "OFF", UDim2.fromOffset(65, 28), UDim2.new(1, -77, 0.5, -14), Colors.Input, 11)
	local function Refresh()
		local enabled = Settings[key] == true
		button.Text = enabled and "ON" or "OFF"
		button.BackgroundColor3 = enabled and Colors.Green or Colors.Input
		button.TextColor3 = enabled and Colors.Main or Colors.White
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	Connect(button.MouseButton1Click, function()
		SetSetting(key, not Settings[key])
	end)
	return card
end

local function AddSlider(page, title, description, key, minimum, sliderMaximum, absoluteMaximum)
	local card = Card(page, title, 85)
	Label(card, title, UDim2.new(0, 115, 0, 21), UDim2.fromOffset(12, 6), 12, Colors.White, Enum.Font.GothamBold)
	local valueLabel = Label(card, "", UDim2.new(1, -140, 0, 21), UDim2.fromOffset(126, 6), 11, Colors.Accent, Enum.Font.GothamBold)
	Label(card, description, UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 28), 9, Colors.Muted)
	local track = New("Frame", card, {
		Name = "SliderTrack",
		Size = UDim2.new(1, -103, 0, 6),
		Position = UDim2.new(0, 12, 0, 62),
		BackgroundColor3 = Colors.Input,
		BorderSizePixel = 0,
		Active = true
	})
	Corner(track, 3)
	local fill = New("Frame", track, {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Colors.Accent,
		BorderSizePixel = 0
	})
	Corner(fill, 3)
	local knob = New("Frame", track, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, -7, 0.5, -7),
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0
	})
	Corner(knob, 7)
	local textbox = New("TextBox", card, {
		Name = "FixedValueTextbox",
		Size = UDim2.new(1, -103, 0, 26),
		Position = UDim2.new(0, 12, 0, 52),
		BackgroundColor3 = Colors.Input,
		BorderSizePixel = 0,
		TextColor3 = Colors.White,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Visible = false,
		PlaceholderText = "Enter a fixed value"
	})
	Stroke(textbox, Colors.White, 1)
	New("UIPadding", textbox, {PaddingLeft = UDim.new(0, 8)})
	local modeButtonSize = UserInputService.TouchEnabled and 32 or 25
	local setButton = Button(card, "S", UDim2.fromOffset(modeButtonSize, modeButtonSize), UDim2.new(1, -(modeButtonSize * 2 + 14), 0, 52), Colors.Hover, 12, true)
	local textButton = Button(card, "T", UDim2.fromOffset(modeButtonSize, modeButtonSize), UDim2.new(1, -(modeButtonSize + 14), 0, 52), Colors.Input, 12, true)
	local setStroke = setButton:FindFirstChildOfClass("UIStroke")
	local textStroke = textButton:FindFirstChildOfClass("UIStroke")
	setStroke.Color = Colors.White
	textStroke.Color = Colors.White
	local mode = "S"
	local dragging = false
	local function Format(value)
		if math.abs(value - math.floor(value + 0.5)) < 0.0001 then
			return tostring(math.floor(value + 0.5))
		end
		return string.format("%.2f", value)
	end
	local function Refresh()
		local value = Settings[key]
		valueLabel.Text = Format(value)
		local alpha = math.clamp((value - minimum) / (sliderMaximum - minimum), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -7, 0.5, -7)
		if not textbox:IsFocused() then textbox.Text = Format(value) end
		track.Visible = mode == "S"
		textbox.Visible = mode == "T"
		setButton.BackgroundColor3 = mode == "S" and Colors.Hover or Colors.Input
		textButton.BackgroundColor3 = mode == "T" and Colors.Hover or Colors.Input
		setStroke.Thickness = mode == "S" and 2 or 1
		textStroke.Thickness = mode == "T" and 2 or 1
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	local function Drag(input)
		if mode ~= "S" or track.AbsoluteSize.X <= 0 then return end
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = math.floor(minimum + (sliderMaximum - minimum) * alpha + 0.5)
		SetSetting(key, value)
	end
	Connect(track.InputBegan, function(input)
		if mode == "S" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = true
			Drag(input)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			Drag(input)
		end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	Connect(setButton.MouseButton1Click, function()
		mode = "S"
		Refresh()
	end)
	Connect(textButton.MouseButton1Click, function()
		mode = "T"
		Refresh()
		textbox:CaptureFocus()
	end)
	Connect(textbox.FocusLost, function()
		local number = tonumber(textbox.Text)
		if number and number == number and number ~= math.huge and number ~= -math.huge then
			SetSetting(key, math.clamp(number, minimum, absoluteMaximum))
		end
		Refresh()
	end)
	return card
end

local function AddModeSelector(page)
	local card = Card(page, "Invisibility Mode", 68)
	Label(card, "Invisibility Mode", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(12, 6), 12, Colors.White, Enum.Font.GothamBold)
	Label(card, "Air: R6 pose | Bottom: below floor", UDim2.new(1, -20, 0, 16), UDim2.fromOffset(12, 23), 9, Colors.Muted)
	local airButton = Button(card, "Air", UDim2.fromOffset(70, 23), UDim2.fromOffset(12, 42), Colors.Input, 10)
	local bottomButton = Button(card, "Bottom", UDim2.fromOffset(70, 23), UDim2.fromOffset(87, 42), Colors.Input, 10)
	local function Refresh()
		airButton.BackgroundColor3 = Settings.InvisibilityMode == "Air" and Colors.Accent or Colors.Input
		bottomButton.BackgroundColor3 = Settings.InvisibilityMode == "Bottom" and Colors.Accent or Colors.Input
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	Connect(airButton.MouseButton1Click, function() SetSetting("InvisibilityMode", "Air") end)
	Connect(bottomButton.MouseButton1Click, function() SetSetting("InvisibilityMode", "Bottom") end)
end

AddSection(CharacterPage, "CHARACTER SETTINGS")
AddToggle(CharacterPage, "Apply Speed", "Keep selected WalkSpeed using RunService", "ApplySpeed")
AddSlider(CharacterPage, "Speed", "S: slider (0-500) | T: exact value (up to 1,000,000)", "Speed", 0, 500, 1000000)
AddToggle(CharacterPage, "Apply JumpPower", "Keep selected JumpPower using RunService", "ApplyJumpPower")
AddSlider(CharacterPage, "JumpPower", "S: slider (0-500) | T: exact value (up to 1,000,000)", "JumpPower", 0, 500, 1000000)

AddSection(VisualsPage, "VISUALS & ESP")
AddToggle(VisualsPage, "Show Global ESP", "White highlight for every other player, all teams", "ShowGlobalESP")
AddToggle(VisualsPage, "Show Team ESP", "Highlight players with their own team colors", "ShowTeamESP")
AddToggle(VisualsPage, "Invisibility", "Local invisibility test with Air / Bottom mode", "Invisibility")
AddModeSelector(VisualsPage)
AddSlider(VisualsPage, "Invisibility Speed", "Move speed in Air and Bottom modes", "InvisSpeed", 1, 100, 200)
Label(VisualsPage, "Global ESP takes priority if both ESP modes are enabled.", UDim2.new(1, -10, 0, 32), UDim2.fromOffset(0, 0), 10, Colors.Muted)

AddSection(CameraPage, "CAMERA SETTINGS")
AddSlider(CameraPage, "Field Of View", "S/T: 10-300 | Roblox camera supports up to 120", "FieldOfView", 10, 300, 300)

AddSection(ComingPage, "MORE COMING SOON!")
local ComingCard = Card(ComingPage, "Future Features", 100)
Label(ComingCard, "New features will appear here.", UDim2.new(1, -24, 0, 35), UDim2.fromOffset(12, 24), 12, Colors.White)

AddSection(SettingsPage, "SETTINGS")
local PresetsCard = Card(SettingsPage, "Configuration Presets", 192)
local SaveButton = Button(PresetsCard, "Save Configuration Presets", UDim2.new(1, -24, 0, 33), UDim2.fromOffset(12, 10), Colors.Input, 11)
local PresetText = New("TextBox", PresetsCard, {
	Name = "PresetText",
	Size = UDim2.new(1, -24, 0, 75),
	Position = UDim2.fromOffset(12, 51),
	BackgroundColor3 = Colors.Input,
	BorderSizePixel = 0,
	TextColor3 = Colors.White,
	TextSize = 10,
	Font = Enum.Font.Code,
	Text = "",
	PlaceholderText = "Save to generate JSON, or paste a preset here",
	ClearTextOnFocus = false,
	TextWrapped = true,
	MultiLine = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top
})
Corner(PresetText, 4)
Stroke(PresetText, Colors.Border)
New("UIPadding", PresetText, {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
local LoadButton = Button(PresetsCard, "Load Preset", UDim2.new(1, -24, 0, 29), UDim2.fromOffset(12, 132), Colors.Input, 11)
local PresetStatus = Label(PresetsCard, "Copy the JSON manually to keep it between sessions.", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 165), 9, Colors.Muted)

Connect(SaveButton.MouseButton1Click, function()
	local ok, result = pcall(function() return HttpService:JSONEncode(Settings) end)
	if ok then
		PresetText.Text = result
		PresetStatus.Text = "Preset generated. Copy it to save it permanently."
		PresetStatus.TextColor3 = Colors.Green
	else
		PresetStatus.Text = "Couldn't generate a preset."
		PresetStatus.TextColor3 = Colors.Accent
	end
end)

Connect(LoadButton.MouseButton1Click, function()
	local ok, decoded = pcall(function() return HttpService:JSONDecode(PresetText.Text) end)
	if not ok or type(decoded) ~= "table" then
		PresetStatus.Text = "Invalid JSON preset."
		PresetStatus.TextColor3 = Colors.Accent
		return
	end
	if decoded.InvisibilityMode == "Air" or decoded.InvisibilityMode == "Bottom" then
		SetSetting("InvisibilityMode", decoded.InvisibilityMode)
	end
	local expectedBool = {ApplySpeed = true, ApplyJumpPower = true, ShowGlobalESP = true, ShowTeamESP = true, Invisibility = true}
	for key in pairs(expectedBool) do
		if type(decoded[key]) == "boolean" then SetSetting(key, decoded[key]) end
	end
	for _, key in ipairs({"Speed", "JumpPower", "InvisSpeed", "FieldOfView"}) do
		local number = decoded[key]
		if type(number) == "number" and number == number and number ~= math.huge and number ~= -math.huge then
			local minimum = key == "InvisSpeed" and 1 or key == "FieldOfView" and 10 or 0
			local maximum = key == "InvisSpeed" and 200 or key == "FieldOfView" and 300 or 1000000
			SetSetting(key, math.clamp(number, minimum, maximum))
		end
	end
	PresetStatus.Text = "Configuration preset loaded."
	PresetStatus.TextColor3 = Colors.Green
end)

local DestroyCard = Card(SettingsPage, "Destroy Matrix", 76)
local DestroyButton = Button(DestroyCard, "DESTROY MATRIX & WIPE GUI", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 17), Color3.fromRGB(83, 27, 37), 11)
local ConfirmationActive = false

local function WipeHub()
	if not alive then return end
	SetMouseUnlocked(false)
	Settings.Invisibility = false
	ReleaseInvisibility()
	Settings.ShowGlobalESP = false
	Settings.ShowTeamESP = false
	for player in pairs(ESPHighlights) do RemoveESP(player) end
	Settings.ApplySpeed = false
	Settings.ApplyJumpPower = false
	RestoreCharacterValues()
	local camera = workspace.CurrentCamera
	if camera then camera.FieldOfView = OriginalFieldOfView end
	alive = false
	DisconnectAll(CharacterConnections)
	DisconnectAll(ESPConnections)
	DisconnectAll(Connections)
	ScreenGui:Destroy()
	print("[Huss Valley] Hub destroyed")
end

Connect(DestroyButton.MouseButton1Click, function()
	if not ConfirmationActive then
		ConfirmationActive = true
		DestroyButton.Text = "CLICK AGAIN TO CONFIRM"
		task.delay(4, function()
			if alive then
				ConfirmationActive = false
				DestroyButton.Text = "DESTROY MATRIX & WIPE GUI"
			end
		end)
	else
		WipeHub()
	end
end)

local ResizeHandles = {}
local ExpandedWindowSize = Main.Size
local RestoreRectangle = nil
local IsMaximized = false
local ActiveWindowAction = nil
local ActivePointer = nil
local PointerStart = nil
local RectangleStart = nil
local LastPointerPosition = nil
local LastPointerTime = 0
local LastHeaderClickTime = 0
local LastHeaderClickPosition = nil
local LastMoveVelocity = Vector2.zero
local ActiveHandle = nil
local LastLayoutWidth = nil
local DisplayRectangle = {X = 0, Y = 0, W = 550, H = 420}
local TargetRectangle = {X = 0, Y = 0, W = 550, H = 420}
local HideStatusToken = 0
local HEADER_HEIGHT = 42
local WINDOW_MARGIN = 8
local MAGNET_DISTANCE = 15
local IsTouch = UserInputService.TouchEnabled

local MainBorder = Main:FindFirstChildOfClass("UIStroke")
local WindowShadow = New("Frame", ScreenGui, {
	Name = "WindowAmbientShadow",
	Size = Main.Size,
	Position = Main.Position,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1
})
Corner(WindowShadow, 13)
local ShadowStroke = Stroke(WindowShadow, Color3.fromRGB(0, 0, 0), 8)
ShadowStroke.Transparency = 0.67
Main.ZIndex = 2

local HeaderAccent = New("Frame", Header, {
	Name = "MotionAccent",
	Size = UDim2.new(1, 0, 0, 2),
	Position = UDim2.new(0, 0, 1, -2),
	BackgroundColor3 = Colors.Accent,
	BackgroundTransparency = 0.65,
	BorderSizePixel = 0,
	ZIndex = 7
})

local WindowStatus = New("TextLabel", Main, {
	Name = "WindowStatus",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -23, 1, -18),
	Size = UDim2.fromOffset(168, 25),
	BackgroundColor3 = Color3.fromRGB(35, 37, 47),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	TextColor3 = Colors.White,
	Text = "",
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextTransparency = 1,
	Visible = false,
	ZIndex = 85
})
Corner(WindowStatus, 5)
local StatusStroke = Stroke(WindowStatus, Colors.Accent, 1)
StatusStroke.Transparency = 0.4

local function GetSafeViewport()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	local insetTop, insetBottom = GuiService:GetGuiInset()
	return Vector2.new(math.max(1, viewport.X - insetTop.X - insetBottom.X), math.max(1, viewport.Y - insetTop.Y - insetBottom.Y))
end

local function GetDimensions(viewport)
	viewport = viewport or GetSafeViewport()
	local minWidth = math.min(320, math.max(1, viewport.X - 2 * WINDOW_MARGIN))
	local minHeight = math.min(265, math.max(1, viewport.Y - 2 * WINDOW_MARGIN))
	return minWidth, minHeight, math.max(1, viewport.X - 2 * WINDOW_MARGIN), math.max(1, viewport.Y - 2 * WINDOW_MARGIN)
end

local function CopyRect(rect)
	return {X = rect.X, Y = rect.Y, W = rect.W, H = rect.H}
end

local function ClampRect(rect, viewport, minWidth, minHeight)
	viewport = viewport or GetSafeViewport()
	local _, _, maxWidth, maxHeight = GetDimensions(viewport)
	minWidth = math.min(minWidth or 1, maxWidth)
	minHeight = math.min(minHeight or 1, maxHeight)
	local width = math.clamp(rect.W, minWidth, maxWidth)
	local height = math.clamp(rect.H, minHeight, maxHeight)
	return {
		X = math.clamp(rect.X, WINDOW_MARGIN, math.max(WINDOW_MARGIN, viewport.X - width - WINDOW_MARGIN)),
		Y = math.clamp(rect.Y, WINDOW_MARGIN, math.max(WINDOW_MARGIN, viewport.Y - height - WINDOW_MARGIN)),
		W = width,
		H = height
	}
end

local function SetTargetRectangle(rect, instant)
	TargetRectangle = CopyRect(rect)
	if instant then DisplayRectangle = CopyRect(rect) end
end

local function UpdateAdaptiveLayout(force)
	local width = DisplayRectangle.W
	if not force and LastLayoutWidth and math.abs(width - LastLayoutWidth) < 2 then return end
	LastLayoutWidth = width
	local sidebarWidth = width < 370 and 94 or width < 480 and 112 or 165
	Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
	Content.Position = UDim2.fromOffset(sidebarWidth, 0)
	Content.Size = UDim2.new(1, -sidebarWidth, 1, 0)
	for _, button in pairs(TabButtons) do
		button.TextWrapped = width < 480
		button.TextSize = width < 480 and 9 or 11
	end
end

local function ShowWindowStatus(message)
	HideStatusToken += 1
	WindowStatus.Text = message
	if not WindowStatus.Visible or WindowStatus.TextTransparency > 0.01 then
		WindowStatus.Visible = true
		TweenService:Create(WindowStatus, TweenInfo.new(0.13), {TextTransparency = 0}):Play()
	end
end

local function HideWindowStatus()
	HideStatusToken += 1
	local token = HideStatusToken
	TweenService:Create(WindowStatus, TweenInfo.new(0.22), {TextTransparency = 1}):Play()
	task.delay(0.24, function()
		if alive and HideStatusToken == token then WindowStatus.Visible = false end
	end)
end

local function SetMotionHighlight(enabled)
	if MainBorder then
		TweenService:Create(MainBorder, TweenInfo.new(0.16), {
			Thickness = enabled and 2.2 or 1.5,
			Color = enabled and Color3.fromRGB(255, 99, 110) or Colors.Accent
		}):Play()
	end
	TweenService:Create(HeaderAccent, TweenInfo.new(0.16), {
		BackgroundTransparency = enabled and 0.08 or 0.65
	}):Play()
	TweenService:Create(ShadowStroke, TweenInfo.new(0.2), {
		Thickness = enabled and 11 or 8,
		Transparency = enabled and 0.55 or 0.67
	}):Play()
end

local function StopWindowAction()
	if not ActiveWindowAction then return end
	local wasAction = ActiveWindowAction
	local touchFlick = ActivePointer and ActivePointer.UserInputType == Enum.UserInputType.Touch
	local flickRecent = os.clock() - LastPointerTime < 0.075
	ActiveWindowAction = nil
	ActivePointer = nil
	PointerStart = nil
	RectangleStart = nil
	LastPointerPosition = nil
	ActiveHandle = nil
	SetMotionHighlight(false)
	HideWindowStatus()
	if wasAction == "move" and not IsMaximized then
		local viewport = GetSafeViewport()
		local moved = CopyRect(TargetRectangle)
		if touchFlick and flickRecent then
			local velocity = LastMoveVelocity * 0.05
			if velocity.Magnitude > 42 then velocity = velocity.Unit * 42 end
			moved.X += velocity.X
			moved.Y += velocity.Y
		end
		local clamped = ClampRect(moved, viewport, TargetRectangle.W, TargetRectangle.H)
		local minX = WINDOW_MARGIN
		local minY = WINDOW_MARGIN
		local right = math.max(minX, viewport.X - clamped.W - WINDOW_MARGIN)
		local bottom = math.max(minY, viewport.Y - clamped.H - WINDOW_MARGIN)
		if math.abs(clamped.X - minX) < MAGNET_DISTANCE then clamped.X = minX end
		if math.abs(clamped.Y - minY) < MAGNET_DISTANCE then clamped.Y = minY end
		if math.abs(clamped.X - right) < MAGNET_DISTANCE then clamped.X = right end
		if math.abs(clamped.Y - bottom) < MAGNET_DISTANCE then clamped.Y = bottom end
		SetTargetRectangle(clamped, false)
	end
end

local function FitWindowToViewport()
	local viewport = GetSafeViewport()
	local minWidth, minHeight, maxWidth, maxHeight = GetDimensions(viewport)
	if RestoreRectangle then
		RestoreRectangle = ClampRect(RestoreRectangle, viewport, minWidth, minHeight)
	end
	if IsMaximized then
		SetTargetRectangle({X = WINDOW_MARGIN, Y = WINDOW_MARGIN, W = maxWidth, H = IsMinimized and HEADER_HEIGHT or maxHeight})
	else
		local current = CopyRect(TargetRectangle)
		current.W = math.clamp(current.W, minWidth, maxWidth)
		current.H = IsMinimized and HEADER_HEIGHT or math.clamp(current.H, minHeight, maxHeight)
		SetTargetRectangle(ClampRect(current, viewport, minWidth, IsMinimized and HEADER_HEIGHT or minHeight))
	end
	if IsMinimized then
		ExpandedWindowSize = UDim2.fromOffset(
			math.clamp(ExpandedWindowSize.X.Offset, minWidth, maxWidth),
			math.clamp(ExpandedWindowSize.Y.Offset, minHeight, maxHeight)
		)
	end
	UpdateAdaptiveLayout(true)
end

local function ToggleMaximize()
	if not alive or IsMinimized then return end
	StopWindowAction()
	local viewport = GetSafeViewport()
	local minWidth, minHeight, maxWidth, maxHeight = GetDimensions(viewport)
	if IsMaximized then
		IsMaximized = false
		SetTargetRectangle(RestoreRectangle and ClampRect(RestoreRectangle, viewport, minWidth, minHeight) or {
			X = WINDOW_MARGIN, Y = WINDOW_MARGIN, W = minWidth, H = minHeight
		})
		RestoreRectangle = nil
	else
		RestoreRectangle = CopyRect(TargetRectangle)
		IsMaximized = true
		SetTargetRectangle({X = WINDOW_MARGIN, Y = WINDOW_MARGIN, W = maxWidth, H = maxHeight})
	end
	ShowWindowStatus(IsMaximized and "MAXIMIZED" or "RESTORED")
	local token = HideStatusToken
	task.delay(0.8, function()
		if alive and token == HideStatusToken and not ActiveWindowAction then HideWindowStatus() end
	end)
end

local function SetMinimized(minimized)
	if minimized == IsMinimized then return end
	StopWindowAction()
	if minimized then
		ExpandedWindowSize = UDim2.fromOffset(TargetRectangle.W, TargetRectangle.H)
	end
	IsMinimized = minimized
	Body.Visible = not minimized
	MinimizeButton.Text = minimized and "+" or "−"
	for _, handle in pairs(ResizeHandles) do handle.Visible = not minimized end
	local rect = CopyRect(TargetRectangle)
	rect.H = minimized and HEADER_HEIGHT or ExpandedWindowSize.Y.Offset
	SetTargetRectangle(rect)
	FitWindowToViewport()
end

Connect(MinimizeButton.MouseButton1Click, function()
	SetMinimized(not IsMinimized)
end)

Connect(CloseButton.MouseButton1Click, function()
	StopWindowAction()
	Main.Visible = false
	WindowShadow.Visible = false
	ShowNotice('The interface is closed. Press "L" to open it again.')
end)

Connect(UserInputService.InputBegan, function(input, processed)
	if not alive or processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.N then
		SetMouseUnlocked(not MouseUnlocked)
	elseif input.KeyCode == Enum.KeyCode.L then
		Main.Visible = not Main.Visible
		WindowShadow.Visible = Main.Visible
		if Main.Visible then
			NoticeSerial += 1
			Notification.Visible = false
		end
	end
end)

local ResizeRegions = {
	NW = {UDim2.fromOffset(IsTouch and 28 or 21, IsTouch and 28 or 21), UDim2.fromOffset(0, 0)},
	N = {UDim2.new(1, -(IsTouch and 56 or 42), 0, IsTouch and 14 or 9), UDim2.fromOffset(IsTouch and 28 or 21, 0)},
	NE = {UDim2.fromOffset(IsTouch and 28 or 21, 5), UDim2.new(1, -(IsTouch and 28 or 21), 0, 0)},
	W = {UDim2.new(0, IsTouch and 14 or 9, 1, -(IsTouch and 56 or 42)), UDim2.fromOffset(0, IsTouch and 28 or 21)},
	E = {UDim2.new(0, IsTouch and 14 or 9, 1, -(IsTouch and 56 or 42)), UDim2.new(1, -(IsTouch and 14 or 9), 0, IsTouch and 28 or 21)},
	SW = {UDim2.fromOffset(IsTouch and 28 or 21, IsTouch and 28 or 21), UDim2.new(0, 0, 1, -(IsTouch and 28 or 21))},
	S = {UDim2.new(1, -(IsTouch and 56 or 42), 0, IsTouch and 14 or 9), UDim2.new(0, IsTouch and 28 or 21, 1, -(IsTouch and 14 or 9))},
	SE = {UDim2.fromOffset(IsTouch and 28 or 21, IsTouch and 28 or 21), UDim2.new(1, -(IsTouch and 28 or 21), 1, -(IsTouch and 28 or 21))}
}

local ResizeDecorations = {}
for _, edge in ipairs({"N", "S", "E", "W"}) do
	local horizontal = edge == "N" or edge == "S"
	local side = New("Frame", Main, {
		Name = "ResizeGlow_" .. edge,
		Size = horizontal and UDim2.new(1, -18, 0, 3) or UDim2.new(0, 3, 1, -18),
		Position = edge == "N" and UDim2.fromOffset(9, 0)
			or edge == "S" and UDim2.new(0, 9, 1, -3)
			or edge == "W" and UDim2.fromOffset(0, 9)
			or UDim2.new(1, -3, 0, 9),
		BackgroundColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 79
	})
	ResizeDecorations[edge] = side
end

local function SetResizeGlow(region)
	for edge, decoration in pairs(ResizeDecorations) do
		local show = region and string.find(region, edge, 1, true) ~= nil
		TweenService:Create(decoration, TweenInfo.new(0.16), {
			BackgroundTransparency = show and 0.08 or 1
		}):Play()
	end
end

local function BeginWindowAction(action, input)
	if not alive or not Main.Visible or ActiveWindowAction or (IsMinimized and action ~= "move") then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	if action == "move" then
		local timeNow = os.clock()
		if LastHeaderClickPosition and timeNow - LastHeaderClickTime <= 0.31 and (pos - LastHeaderClickPosition).Magnitude <= 18 then
			LastHeaderClickTime = 0
			LastHeaderClickPosition = nil
			ToggleMaximize()
			return
		end
		LastHeaderClickTime = timeNow
		LastHeaderClickPosition = pos
	end
	ActiveWindowAction = action
	ActivePointer = input
	PointerStart = pos
	RectangleStart = CopyRect(TargetRectangle)
	LastPointerPosition = pos
	LastPointerTime = os.clock()
	LastMoveVelocity = Vector2.zero
	ActiveHandle = ResizeHandles[action]
	SetMotionHighlight(true)
	SetResizeGlow(action == "move" and nil or action)
	ShowWindowStatus(action == "move" and "MOVE WINDOW" or string.format("%d × %d", math.floor(TargetRectangle.W), math.floor(TargetRectangle.H)))
end

for region, geometry in pairs(ResizeRegions) do
	local handle = New("TextButton", Main, {
		Name = "Resize_" .. region,
		Size = geometry[1],
		Position = geometry[2],
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = region == "SE" and "◢" or "",
		TextSize = IsTouch and 19 or 15,
		Font = Enum.Font.GothamBold,
		TextColor3 = Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 90
	})
	ResizeHandles[region] = handle
	Connect(handle.InputBegan, function(input) BeginWindowAction(region, input) end)
	Connect(handle.MouseEnter, function()
		if not ActiveWindowAction then SetResizeGlow(region) end
	end)
	Connect(handle.MouseLeave, function()
		if not ActiveWindowAction then SetResizeGlow(nil) end
	end)
end

local TopRightSideHandle = New("TextButton", Main, {
	Name = "Resize_NE_SideGrip",
	Size = UDim2.fromOffset(IsTouch and 14 or 9, IsTouch and 28 or 22),
	Position = UDim2.new(1, -(IsTouch and 14 or 9), 0, 38),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 90
})
ResizeHandles.NESideGrip = TopRightSideHandle
Connect(TopRightSideHandle.InputBegan, function(input)
	BeginWindowAction("NE", input)
end)
Connect(TopRightSideHandle.MouseEnter, function()
	if not ActiveWindowAction then SetResizeGlow("NE") end
end)
Connect(TopRightSideHandle.MouseLeave, function()
	if not ActiveWindowAction then SetResizeGlow(nil) end
end)

Connect(Header.InputBegan, function(input)
	if ActiveWindowAction then return end
	local relativeX = input.Position.X - Main.AbsolutePosition.X
	local relativeY = input.Position.Y - Main.AbsolutePosition.Y
	local controlsWidth = HeaderButtonSize * 2 + 28
	if relativeX < (IsTouch and 28 or 21) or relativeX >= Main.AbsoluteSize.X - controlsWidth or relativeY < (IsTouch and 15 or 10) then return end
	BeginWindowAction("move", input)
end)

local function SnapMovement(rect, viewport)
	local right = viewport.X - rect.W - WINDOW_MARGIN
	local bottom = viewport.Y - rect.H - WINDOW_MARGIN
	if math.abs(rect.X - WINDOW_MARGIN) < MAGNET_DISTANCE then rect.X = WINDOW_MARGIN end
	if math.abs(rect.Y - WINDOW_MARGIN) < MAGNET_DISTANCE then rect.Y = WINDOW_MARGIN end
	if math.abs(rect.X - right) < MAGNET_DISTANCE then rect.X = right end
	if math.abs(rect.Y - bottom) < MAGNET_DISTANCE then rect.Y = bottom end
	return rect
end

local function ApplyPointerMovement(input)
	if not ActiveWindowAction or not PointerStart or not RectangleStart then return end
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	local delta = pos - PointerStart
	local viewport = GetSafeViewport()
	local minWidth, minHeight, maxWidth, maxHeight = GetDimensions(viewport)
	local rect = CopyRect(RectangleStart)
	local action = ActiveWindowAction

	if action == "move" and IsMaximized and delta.Magnitude >= 8 then
		local relative = math.clamp((PointerStart.X - RectangleStart.X) / math.max(1, RectangleStart.W), 0.16, 0.84)
		local original = RestoreRectangle or {X = 50, Y = 50, W = math.min(550, maxWidth), H = math.min(420, maxHeight)}
		local restored = ClampRect({
			X = pos.X - original.W * relative,
			Y = math.max(WINDOW_MARGIN, pos.Y - 22),
			W = original.W,
			H = original.H
		}, viewport, minWidth, minHeight)
		IsMaximized = false
		RestoreRectangle = nil
		RectangleStart = CopyRect(restored)
		PointerStart = pos
		SetTargetRectangle(restored)
		return
	end

	if action == "move" then
		rect.X += delta.X
		rect.Y += delta.Y
		rect = SnapMovement(rect, viewport)
	else
		local oldRight = rect.X + rect.W
		local oldBottom = rect.Y + rect.H
		if string.find(action, "W", 1, true) then
			local left = math.clamp(rect.X + delta.X, WINDOW_MARGIN, oldRight - minWidth)
			rect.X = left
			rect.W = oldRight - left
		elseif string.find(action, "E", 1, true) then
			rect.W = math.clamp(rect.W + delta.X, minWidth, math.min(maxWidth, viewport.X - rect.X - WINDOW_MARGIN))
		end
		if string.find(action, "N", 1, true) then
			local top = math.clamp(rect.Y + delta.Y, WINDOW_MARGIN, oldBottom - minHeight)
			rect.Y = top
			rect.H = oldBottom - top
		elseif string.find(action, "S", 1, true) then
			rect.H = math.clamp(rect.H + delta.Y, minHeight, math.min(maxHeight, viewport.Y - rect.Y - WINDOW_MARGIN))
		end
		ShowWindowStatus(string.format("%d × %d", math.floor(rect.W + 0.5), math.floor(rect.H + 0.5)))
	end

	rect = ClampRect(rect, viewport, action == "move" and rect.W or minWidth, action == "move" and rect.H or minHeight)
	local now = os.clock()
	local elapsed = math.max(now - LastPointerTime, 0.001)
	LastMoveVelocity = (pos - LastPointerPosition) / elapsed
	LastPointerPosition = pos
	LastPointerTime = now
	SetTargetRectangle(rect)
end

Connect(UserInputService.InputChanged, function(input)
	if not ActiveWindowAction or not ActivePointer then return end
	if ActivePointer.UserInputType == Enum.UserInputType.Touch then
		if input ~= ActivePointer then return end
	elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	ApplyPointerMovement(input)
end)

Connect(UserInputService.InputEnded, function(input)
	if not ActiveWindowAction or not ActivePointer then return end
	if ActivePointer.UserInputType == Enum.UserInputType.Touch then
		if input ~= ActivePointer then return end
	elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	StopWindowAction()
	SetResizeGlow(nil)
end)

local viewport = GetSafeViewport()
local initialWidth = math.min(550, math.max(1, viewport.X - 16))
local initialHeight = math.min(420, math.max(1, viewport.Y - 16))
local initial = {
	X = math.floor((viewport.X - initialWidth) * 0.5),
	Y = math.floor((viewport.Y - initialHeight) * 0.5),
	W = initialWidth,
	H = initialHeight
}
SetTargetRectangle(initial, true)
ExpandedWindowSize = UDim2.fromOffset(initialWidth, initialHeight)
UpdateAdaptiveLayout(true)

Connect(RunService.RenderStepped, function(dt)
	if not alive then return end
	local speed = ActiveWindowAction and 35 or 18
	local alpha = 1 - math.exp(-math.min(dt, 0.1) * speed)
	local shown = DisplayRectangle
	local destination = TargetRectangle
	shown.X += (destination.X - shown.X) * alpha
	shown.Y += (destination.Y - shown.Y) * alpha
	shown.W += (destination.W - shown.W) * alpha
	shown.H += (destination.H - shown.H) * alpha
	for _, key in ipairs({"X", "Y", "W", "H"}) do
		if math.abs(shown[key] - destination[key]) < 0.07 then shown[key] = destination[key] end
	end
	Main.Position = UDim2.fromOffset(math.floor(shown.X + 0.5), math.floor(shown.Y + 0.5))
	Main.Size = UDim2.fromOffset(math.floor(shown.W + 0.5), math.floor(shown.H + 0.5))
	WindowShadow.Position = UDim2.fromOffset(math.floor(shown.X + 0.5), math.floor(shown.Y + 0.5))
	WindowShadow.Size = UDim2.fromOffset(math.floor(shown.W + 0.5), math.floor(shown.H + 0.5))
	UpdateAdaptiveLayout(false)
end)

local camera = workspace.CurrentCamera
if camera then Connect(camera:GetPropertyChangedSignal("ViewportSize"), FitWindowToViewport) end
Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	local currentCamera = workspace.CurrentCamera
	if currentCamera then
		Connect(currentCamera:GetPropertyChangedSignal("ViewportSize"), FitWindowToViewport)
	end
	FitWindowToViewport()
end)
Connect(RunService.Heartbeat, EnforceCharacterValues)
Connect(RunService.RenderStepped, EnforceCameraFieldOfView)
EnforceCameraFieldOfView()
Connect(LocalPlayer.CharacterAdded, function(character)
	BindHumanoid(character)
	if Settings.Invisibility then
		task.defer(function()
			if alive and LocalPlayer.Character == character and Settings.Invisibility then
				character:WaitForChild("HumanoidRootPart", 10)
				StartInvisibility()
			end
		end)
	end
end)

Connect(LocalPlayer.CharacterRemoving, function(character)
	if character == InvisCurrentCharacter then
		ReleaseInvisibility()
	end
end)

Connect(Players.PlayerAdded, BindESPPlayer)
Connect(Players.PlayerRemoving, function(player)
	RemoveESP(player)
end)

for _, otherPlayer in ipairs(Players:GetPlayers()) do BindESPPlayer(otherPlayer) end
if LocalPlayer.Character then task.defer(BindHumanoid, LocalPlayer.Character) end
RefreshTabs()
print("[Huss Valley] Aehmre's Huss Valley Hub loaded. Press L to toggle the interface.")
