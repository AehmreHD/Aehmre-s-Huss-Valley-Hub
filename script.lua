-- // AEHMRE'S HUSS VALLEY HUB - PREMIUM CONTROL CENTER //
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
	ESPOpacity = 35,
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
local VisibleTab = "Overview"
local IsMinimized = false
local NoticeSerial = 0

local Colors = {
	Main = Color3.fromRGB(8, 10, 16),
	Panel = Color3.fromRGB(14, 17, 25),
	Card = Color3.fromRGB(23, 26, 36),
	Hover = Color3.fromRGB(34, 39, 52),
	Input = Color3.fromRGB(40, 45, 59),
	Border = Color3.fromRGB(67, 74, 96),
	Accent = Color3.fromRGB(236, 65, 88),
	White = Color3.fromRGB(246, 247, 252),
	Muted = Color3.fromRGB(162, 169, 190),
	Green = Color3.fromRGB(72, 224, 157)
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
			FillTransparency = 1 - math.clamp(Settings.ESPOpacity, 0, 100) / 100,
			OutlineTransparency = 0
		})
		ESPHighlights[player] = highlight
	end
	local color = Settings.ShowGlobalESP and Colors.White or (player.Neutral and Colors.White or player.TeamColor.Color)
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 1 - math.clamp(Settings.ESPOpacity, 0, 100) / 100
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
	if key == "ShowGlobalESP" or key == "ShowTeamESP" or key == "ESPOpacity" then RefreshESP() end
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
if Existing then
	Existing:SetAttribute("HussValleyShuttingDown", true)
	if Existing.Parent then Existing:Destroy() end
end

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
	Size = UDim2.fromOffset(640, 490),
	Position = UDim2.new(0.5, -320, 0.5, -245),
	BackgroundColor3 = Colors.Main,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
	ZIndex = 2
})
Corner(Main, 12)
Stroke(Main, Colors.Accent, 1.3)
New("UIGradient", Main, {
	Rotation = 120,
	Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Colors.Main), ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 19, 27))})
})

local HeaderHeight = 56
local Header = New("Frame", Main, {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, HeaderHeight),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 5
})
New("UIGradient", Header, {
	Rotation = 0,
	Color = ColorSequence.new(Color3.fromRGB(26, 29, 39), Color3.fromRGB(16, 17, 23))
})

local BrandIcon = New("Frame", Header, {
	Name = "BrandIcon",
	Size = UDim2.fromOffset(34, 34),
	Position = UDim2.fromOffset(13, 11),
	BackgroundColor3 = Colors.Accent,
	BorderSizePixel = 0,
	ZIndex = 6
})
Corner(BrandIcon, 8)
New("UIGradient", BrandIcon, {
	Rotation = 45,
	Color = ColorSequence.new(Colors.Accent, Color3.fromRGB(137, 28, 54))
})
local Mark = Label(BrandIcon, "HV", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 13, Colors.White, Enum.Font.GothamBlack)
Mark.TextXAlignment = Enum.TextXAlignment.Center
Mark.ZIndex = 7

local MainTitle = Label(Header, "Aehmre's Huss Valley Hub", UDim2.new(0, 246, 0, 22), UDim2.fromOffset(57, 8), 13, Colors.White, Enum.Font.GothamBlack)
MainTitle.ZIndex = 6
local MainSubtitle = Label(Header, "PREMIUM CLIENT CONTROL CENTER  /  V2", UDim2.new(0, 220, 0, 16), UDim2.fromOffset(58, 30), 9, Colors.Muted, Enum.Font.GothamBold)
MainSubtitle.ZIndex = 6

local HeaderStatus = Label(Header, "●  CLIENT ACTIVE", UDim2.fromOffset(124, 24), UDim2.new(1, -221, 0.5, -12), 9, Colors.Green, Enum.Font.GothamBold)
HeaderStatus.TextXAlignment = Enum.TextXAlignment.Center
HeaderStatus.ZIndex = 6

local HeaderButtonSize = UserInputService.TouchEnabled and 32 or 27
local CloseButton = Button(Header, "X", UDim2.fromOffset(HeaderButtonSize, HeaderButtonSize), UDim2.new(1, -(HeaderButtonSize + 10), 0.5, -HeaderButtonSize / 2), Color3.fromRGB(65, 29, 41), 18)
local MinimizeButton = Button(Header, "−", UDim2.fromOffset(HeaderButtonSize, HeaderButtonSize), UDim2.new(1, -(HeaderButtonSize * 2 + 17), 0.5, -HeaderButtonSize / 2), Colors.Input, 18)
CloseButton.ZIndex = 8
MinimizeButton.ZIndex = 8

local Body = New("Frame", Main, {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -HeaderHeight),
	Position = UDim2.fromOffset(0, HeaderHeight),
	BackgroundTransparency = 1,
	ZIndex = 2
})

local Sidebar = New("ScrollingFrame", Body, {
	Name = "Sidebar",
	Size = UDim2.new(0, 184, 1, 0),
	CanvasSize = UDim2.new(0, 0, 0, 480),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Colors.Accent,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	ZIndex = 3
})
New("UIGradient", Sidebar, {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(16, 18, 26), Color3.fromRGB(10, 12, 18))
})
local SidebarRule = New("Frame", Sidebar, {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.fromOffset(12, 93),
	BackgroundColor3 = Colors.Border,
	BorderSizePixel = 0,
	ZIndex = 3
})
local SideTitle = Label(Sidebar, "HUSS VALLEY", UDim2.new(1, -24, 0, 29), UDim2.fromOffset(14, 15), 18, Colors.White, Enum.Font.GothamBlack)
SideTitle.ZIndex = 4
local SideSubtitle = Label(Sidebar, "DEVELOPER TOOLS  /  CLIENT", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(14, 48), 9, Colors.Muted, Enum.Font.GothamBold)
SideSubtitle.ZIndex = 4
local SideCaption = Label(Sidebar, "NAVIGATION", UDim2.new(1, -24, 0, 23), UDim2.fromOffset(14, 106), 9, Colors.Muted, Enum.Font.GothamBold)
SideCaption.ZIndex = 4

local SidebarFooter = New("Frame", Sidebar, {
	Name = "SidebarMonitor",
	Size = UDim2.new(1, -20, 0, 76),
	Position = UDim2.fromOffset(10, 390),
	BackgroundColor3 = Colors.Card,
	BorderSizePixel = 0,
	ZIndex = 4
})
Corner(SidebarFooter, 7)
Stroke(SidebarFooter, Colors.Border, 1)
local FooterHeading = Label(SidebarFooter, "LIVE TELEMETRY", UDim2.new(1, -16, 0, 17), UDim2.fromOffset(8, 7), 9, Colors.Muted, Enum.Font.GothamBold)
local FooterLine1 = Label(SidebarFooter, "SPEED   --", UDim2.new(1, -16, 0, 19), UDim2.fromOffset(8, 26), 10, Colors.White, Enum.Font.Code)
local FooterLine2 = Label(SidebarFooter, "ESP     --", UDim2.new(1, -16, 0, 19), UDim2.fromOffset(8, 45), 10, Colors.Green, Enum.Font.Code)

local Content = New("Frame", Body, {
	Name = "PageContainer",
	Position = UDim2.fromOffset(184, 0),
	Size = UDim2.new(1, -184, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 3
})

local Notification = New("Frame", ScreenGui, {
	Name = "InterfaceClosedNotification",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(355, 78),
	Position = UDim2.new(1, -16, 1, -16),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 101
})
Corner(Notification, 10)
Stroke(Notification, Colors.Green, 1.5)
local NoticeDot = Label(Notification, "●", UDim2.fromOffset(23, 23), UDim2.fromOffset(13, 19), 14, Colors.Green, Enum.Font.GothamBold)
NoticeDot.ZIndex = 102
local NoticeText = Label(Notification, 'HUB HIDDEN  /  Press L to reopen the interface.', UDim2.new(1, -81, 1, -14), UDim2.fromOffset(39, 7), 11, Colors.White, Enum.Font.GothamSemibold)
NoticeText.TextWrapped = true
NoticeText.TextTruncate = Enum.TextTruncate.None
NoticeText.ZIndex = 102
local NoticeClose = Button(Notification, "×", UDim2.fromOffset(26, 26), UDim2.new(1, -33, 0, 8), Colors.Input, 15)
NoticeClose.ZIndex = 104

InvisibilityWarning = New("TextLabel", ScreenGui, {
	Name = "AirInvisibilityWarning",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(310, 40),
	Position = UDim2.new(0.5, 0, 0.87, 0),
	BackgroundTransparency = 1,
	Text = "⚠️ YOU ARE VISIBLE ⚠️",
	TextColor3 = Color3.fromRGB(255, 225, 50),
	TextStrokeTransparency = 0.25,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	Visible = false
})

local ToastFrame = New("Frame", ScreenGui, {
	Name = "QuickToast",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(310, 42),
	Position = UDim2.new(0.5, 0, 1, -20),
	BackgroundColor3 = Colors.Panel,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	ZIndex = 110,
	Visible = false
})
Corner(ToastFrame, 9)
Stroke(ToastFrame, Colors.Accent, 1)
local ToastText = Label(ToastFrame, "", UDim2.new(1, -28, 1, 0), UDim2.fromOffset(14, 0), 10, Colors.White, Enum.Font.GothamSemibold)
ToastText.ZIndex = 111
local ToastSerial = 0
local function Toast(message, good)
	if not alive then return end
	ToastSerial += 1
	local token = ToastSerial
	ToastText.Text = tostring(message)
	local toastStroke = ToastFrame:FindFirstChildOfClass("UIStroke")
	if toastStroke then toastStroke.Color = good and Colors.Green or Colors.Accent end
	ToastFrame.Visible = true
	ToastFrame.Position = UDim2.new(0.5, 0, 1, 20)
	TweenService:Create(ToastFrame, TweenInfo.new(0.23, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -20)}):Play()
	task.delay(2.6, function()
		if not alive or token ~= ToastSerial then return end
		local tween = TweenService:Create(ToastFrame, TweenInfo.new(0.18), {Position = UDim2.new(0.5, 0, 1, 20)})
		tween:Play()
		tween.Completed:Wait()
		if alive and token == ToastSerial then ToastFrame.Visible = false end
	end)
end

local function ShowNotice(message)
	NoticeSerial += 1
	local token = NoticeSerial
	NoticeText.Text = message
	Notification.Visible = true
	Notification.Position = UDim2.new(1, 380, 1, -16)
	TweenService:Create(Notification, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -16, 1, -16)}):Play()
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
local TabIndicators = {}
local TabNames = {"Overview", "Character", "Visuals & ESP", "Camera", "More coming soon!", "SETTINGS"}
local TabIcons = {"⌂", "♟", "◈", "◉", "+", "⚙"}
local TabDescriptions = {
	Overview = "SYSTEM STATUS  /  SHORTCUTS  /  QUICK ACCESS",
	Character = "PLAYER MOVEMENT  /  REALTIME VALUE LOCK",
	["Visuals & ESP"] = "HIGHLIGHTS  /  INVISIBILITY  /  PLAYER TRACKING",
	Camera = "FIELD OF VIEW  /  CLIENT VIEW SETTINGS",
	["More coming soon!"] = "PROJECT ROADMAP  /  FUTURE EXPANSIONS",
	SETTINGS = "PRESETS  /  KEYBINDS  /  SYSTEM CONTROLS"
}
local SetActiveTab
local function RefreshTabs()
	for name, button in pairs(TabButtons) do
		local selected = VisibleTab == name
		local color = selected and Colors.Card or Colors.Panel
		TweenService:Create(button, TweenInfo.new(0.16), {BackgroundColor3 = color, TextColor3 = selected and Colors.White or Colors.Muted}):Play()
		local bar = TabIndicators[name]
		if bar then bar.BackgroundTransparency = selected and 0 or 1 end
	end
	for name, frame in pairs(PageFrames) do
		frame.Visible = VisibleTab == name
	end
end

SetActiveTab = function(name)
	if not PageFrames[name] then return end
	VisibleTab = name
	RefreshTabs()
	PageFrames[name].CanvasPosition = Vector2.zero
end

local function AddPage(name, index)
	local tab = Button(Sidebar, "   " .. name, UDim2.new(1, -20, 0, 39), UDim2.fromOffset(10, 132 + (index - 1) * 43), Colors.Panel, 10)
	tab.Name = "Tab_" .. name
	tab.TextXAlignment = Enum.TextXAlignment.Left
	tab.Font = Enum.Font.GothamSemibold
	if tab:FindFirstChildOfClass("UIStroke") then tab:FindFirstChildOfClass("UIStroke").Transparency = 0.7 end
	local activeBar = New("Frame", tab, {Size = UDim2.fromOffset(3, 23), Position = UDim2.new(0, 0, 0.5, -11), BackgroundColor3 = Colors.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5})
	Corner(activeBar, 2)
	TabButtons[name] = tab
	TabIndicators[name] = activeBar
	Connect(tab.MouseButton1Click, function() SetActiveTab(name) end)
	Connect(tab.MouseEnter, function()
		if VisibleTab ~= name then TweenService:Create(tab, TweenInfo.new(0.13), {BackgroundColor3 = Colors.Hover}):Play() end
	end)
	Connect(tab.MouseLeave, function()
		if VisibleTab ~= name then TweenService:Create(tab, TweenInfo.new(0.13), {BackgroundColor3 = Colors.Panel}):Play() end
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
		Visible = name == VisibleTab,
		ZIndex = 4
	})
	New("UIPadding", page, {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 13),
		PaddingRight = UDim.new(0, 13)
	})
	New("UIListLayout", page, {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
	PageFrames[name] = page

	local hero = New("Frame", page, {Name = "Hero", Size = UDim2.new(1, -5, 0, 93), BackgroundColor3 = Colors.Card, BorderSizePixel = 0})
	Corner(hero, 10)
	Stroke(hero, Colors.Border, 1)
	New("UIGradient", hero, {Rotation = 5, Color = ColorSequence.new(Color3.fromRGB(44, 29, 41), Colors.Card)})
	local stripe = New("Frame", hero, {Size = UDim2.fromOffset(4, 55), Position = UDim2.fromOffset(12, 19), BackgroundColor3 = Colors.Accent, BorderSizePixel = 0})
	Corner(stripe, 3)
	Label(hero, string.upper(name), UDim2.new(1, -33, 0, 34), UDim2.fromOffset(26, 13), 18, Colors.White, Enum.Font.GothamBlack)
	local desc = Label(hero, TabDescriptions[name] or "HUSS VALLEY INTERFACE", UDim2.new(1, -33, 0, 28), UDim2.fromOffset(27, 50), 9, Colors.Muted, Enum.Font.GothamSemibold)
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.None
	return page
end

local OverviewPage = AddPage(TabNames[1], 1)
local CharacterPage = AddPage(TabNames[2], 2)
local VisualsPage = AddPage(TabNames[3], 3)
local CameraPage = AddPage(TabNames[4], 4)
local ComingPage = AddPage(TabNames[5], 5)
local SettingsPage = AddPage(TabNames[6], 6)

local function Card(page, title, height)
	local card = New("Frame", page, {Name = title, Size = UDim2.new(1, -5, 0, height or 76), BackgroundColor3 = Colors.Card, BorderSizePixel = 0})
	Corner(card, 9)
	local stroke = Stroke(card, Colors.Border, 1)
	Connect(card.MouseEnter, function()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Hover}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.15), {Color = Colors.Accent}):Play()
	end)
	Connect(card.MouseLeave, function()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Card}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.15), {Color = Colors.Border}):Play()
	end)
	return card
end

local function AddSection(page, text)
	local section = New("Frame", page, {Name = "Section_" .. text, Size = UDim2.new(1, -5, 0, 25), BackgroundTransparency = 1})
	Label(section, text, UDim2.new(1, -10, 1, 0), UDim2.fromOffset(2, 0), 10, Colors.Accent, Enum.Font.GothamBold)
	return section
end

local function AddToggle(page, title, description, key)
	local card = Card(page, title, 78)
	local nameLabel = Label(card, title, UDim2.new(1, -110, 0, 24), UDim2.fromOffset(15, 12), 12, Colors.White, Enum.Font.GothamBold)
	local desc = Label(card, description, UDim2.new(1, -112, 0, 35), UDim2.fromOffset(15, 37), 9, Colors.Muted)
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.None
	local button = Button(card, "", UDim2.fromOffset(66, 30), UDim2.new(1, -82, 0.5, -15), Colors.Input, 11)
	local switchCorner = button:FindFirstChildOfClass("UICorner")
	if switchCorner then switchCorner.CornerRadius = UDim.new(0, 15) end
	local knob = New("Frame", button, {Name = "Knob", Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Colors.White, BorderSizePixel = 0})
	Corner(knob, 11)
	local previousEnabled = nil
	local function Refresh()
		local enabled = Settings[key] == true
		if previousEnabled == enabled then return end
		previousEnabled = enabled
		TweenService:Create(button, TweenInfo.new(0.17), {BackgroundColor3 = enabled and Colors.Green or Colors.Input}):Play()
		TweenService:Create(knob, TweenInfo.new(0.17, Enum.EasingStyle.Quint), {Position = enabled and UDim2.fromOffset(40, 4) or UDim2.fromOffset(4, 4)}):Play()
		button.Text = ""
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	Connect(button.MouseButton1Click, function()
		SetSetting(key, not Settings[key])
		Toast(title .. (Settings[key] and "  /  ENABLED" or "  /  DISABLED"), Settings[key])
	end)
	return card
end

local function AddSlider(page, title, description, key, minimum, sliderMaximum, absoluteMaximum)
	local card = Card(page, title, 123)
	local titleLabel = Label(card, title, UDim2.new(1, -96, 0, 23), UDim2.fromOffset(15, 9), 12, Colors.White, Enum.Font.GothamBold)
	local valueLabel = Label(card, "", UDim2.fromOffset(85, 23), UDim2.new(1, -100, 0, 9), 13, Colors.Accent, Enum.Font.GothamBold)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	local desc = Label(card, description, UDim2.new(1, -30, 0, 31), UDim2.fromOffset(15, 34), 9, Colors.Muted)
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.None
	local minLabel = Label(card, tostring(minimum), UDim2.new(0.4, 0, 0, 17), UDim2.fromOffset(16, 102), 9, Colors.Muted, Enum.Font.Code)
	local maxLabel = Label(card, tostring(sliderMaximum), UDim2.fromOffset(65, 17), UDim2.new(1, -174, 0, 102), 9, Colors.Muted, Enum.Font.Code)
	maxLabel.TextXAlignment = Enum.TextXAlignment.Right
	local track = New("Frame", card, {
		Name = "SliderTrack",
		Size = UDim2.new(1, -114, 0, 7),
		Position = UDim2.fromOffset(15, 87),
		BackgroundColor3 = Colors.Input,
		BorderSizePixel = 0,
		Active = true
	})
	Corner(track, 5)
	local fill = New("Frame", track, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Colors.Accent, BorderSizePixel = 0})
	Corner(fill, 5)
	New("UIGradient", fill, {Color = ColorSequence.new(Colors.Accent, Color3.fromRGB(255, 142, 124))})
	local knob = New("Frame", track, {Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, -8, 0.5, -8), BackgroundColor3 = Colors.White, BorderSizePixel = 0})
	Corner(knob, 8)
	Stroke(knob, Colors.Accent, 2)
	local textbox = New("TextBox", card, {
		Name = "FixedValueInput",
		Size = UDim2.new(1, -114, 0, 31),
		Position = UDim2.fromOffset(15, 75),
		BackgroundColor3 = Colors.Input,
		BorderSizePixel = 0,
		TextColor3 = Colors.White,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Visible = false,
		PlaceholderText = "Enter value and press Enter"
	})
	Corner(textbox, 5)
	Stroke(textbox, Colors.Border, 1)
	New("UIPadding", textbox, {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 8)})
	local modeSize = UserInputService.TouchEnabled and 33 or 27
	local setButton = Button(card, "S", UDim2.fromOffset(modeSize, modeSize), UDim2.new(1, -(modeSize * 2 + 21), 0, 77), Colors.Hover, 12, true)
	local textButton = Button(card, "T", UDim2.fromOffset(modeSize, modeSize), UDim2.new(1, -(modeSize + 19), 0, 77), Colors.Input, 12, true)
	local setStroke = setButton:FindFirstChildOfClass("UIStroke")
	local textStroke = textButton:FindFirstChildOfClass("UIStroke")
	setStroke.Color = Colors.White
	textStroke.Color = Colors.White
	local mode = "S"
	local dragging = false
	local activeTouch = nil
	local function Format(value)
		if math.abs(value - math.floor(value + 0.5)) < 0.00001 then return tostring(math.floor(value + 0.5)) end
		return string.format("%.2f", value)
	end
	local function Refresh()
		local value = tonumber(Settings[key]) or minimum
		valueLabel.Text = Format(value)
		local alpha = math.clamp((value - minimum) / math.max(sliderMaximum - minimum, 1), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -8, 0.5, -8)
		if not textbox:IsFocused() then textbox.Text = Format(value) end
		track.Visible = mode == "S"
		textbox.Visible = mode == "T"
		setButton.BackgroundColor3 = mode == "S" and Colors.Accent or Colors.Input
		textButton.BackgroundColor3 = mode == "T" and Colors.Accent or Colors.Input
		setStroke.Thickness = mode == "S" and 2 or 1
		textStroke.Thickness = mode == "T" and 2 or 1
		minLabel.Visible = mode == "S"
		maxLabel.Visible = mode == "S"
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	local function Drag(input)
		if mode ~= "S" or track.AbsoluteSize.X <= 0 then return end
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		SetSetting(key, math.floor(minimum + (sliderMaximum - minimum) * alpha + 0.5))
	end
	Connect(track.InputBegan, function(input)
		if mode ~= "S" then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
			Drag(input)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and input == activeTouch)) then Drag(input) end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == activeTouch) then dragging = false activeTouch = nil end
	end)
	Connect(setButton.MouseButton1Click, function() mode = "S" Refresh() end)
	Connect(textButton.MouseButton1Click, function() mode = "T" Refresh() textbox:CaptureFocus() end)
	Connect(textbox.FocusLost, function()
		local number = tonumber(textbox.Text)
		if number and number == number and number ~= math.huge and number ~= -math.huge then
			SetSetting(key, math.clamp(number, minimum, absoluteMaximum))
			Toast(title .. "  /  " .. Format(Settings[key]), true)
		else
			Toast("INVALID INPUT  /  " .. title, false)
		end
		Refresh()
	end)
	return card
end

local function AddModeSelector(page)
	local card = Card(page, "Invisibility Mode", 83)
	Label(card, "Invisibility Mode", UDim2.new(1, -26, 0, 21), UDim2.fromOffset(15, 8), 12, Colors.White, Enum.Font.GothamBold)
	Label(card, "Choose local visibility behavior", UDim2.new(1, -26, 0, 18), UDim2.fromOffset(15, 29), 9, Colors.Muted)
	local airButton = Button(card, "AIR  /  R6", UDim2.new(0.5, -22, 0, 27), UDim2.fromOffset(15, 51), Colors.Input, 10)
	local bottomButton = Button(card, "BOTTOM", UDim2.new(0.5, -22, 0, 27), UDim2.new(0.5, 7, 0, 51), Colors.Input, 10)
	local function Refresh()
		airButton.BackgroundColor3 = Settings.InvisibilityMode == "Air" and Colors.Accent or Colors.Input
		bottomButton.BackgroundColor3 = Settings.InvisibilityMode == "Bottom" and Colors.Accent or Colors.Input
	end
	table.insert(UIRefreshers, Refresh)
	Refresh()
	Connect(airButton.MouseButton1Click, function() SetSetting("InvisibilityMode", "Air") Toast("INVISIBILITY MODE  /  AIR", true) end)
	Connect(bottomButton.MouseButton1Click, function() SetSetting("InvisibilityMode", "Bottom") Toast("INVISIBILITY MODE  /  BOTTOM", true) end)
end

AddSection(OverviewPage, "SYSTEM OVERVIEW")
local SystemCard = Card(OverviewPage, "SystemTelemetry", 126)
local SystemBadge = Label(SystemCard, "●  ALL SYSTEMS OPERATIONAL", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(15, 10), 10, Colors.Green, Enum.Font.GothamBold)
local OverviewSpeed = Label(SystemCard, "SPEED    --", UDim2.new(1, -25, 0, 22), UDim2.fromOffset(15, 39), 12, Colors.White, Enum.Font.Code)
local OverviewJump = Label(SystemCard, "JUMP     --", UDim2.new(1, -25, 0, 22), UDim2.fromOffset(15, 62), 12, Colors.White, Enum.Font.Code)
local OverviewFOV = Label(SystemCard, "FOV      --", UDim2.new(1, -25, 0, 22), UDim2.fromOffset(15, 85), 12, Colors.White, Enum.Font.Code)

AddSection(OverviewPage, "QUICK NAVIGATION")
local QuickCard = Card(OverviewPage, "QuickActions", 113)
Label(QuickCard, "JUMP TO A MODULE", UDim2.new(1, -25, 0, 22), UDim2.fromOffset(15, 9), 10, Colors.Muted, Enum.Font.GothamBold)
local QuickCharacter = Button(QuickCard, "CHARACTER", UDim2.new(0.5, -22, 0, 34), UDim2.fromOffset(15, 40), Colors.Input, 10)
local QuickVisuals = Button(QuickCard, "VISUALS / ESP", UDim2.new(0.5, -22, 0, 34), UDim2.new(0.5, 7, 0, 40), Colors.Input, 10)
Connect(QuickCharacter.MouseButton1Click, function() SetActiveTab("Character") end)
Connect(QuickVisuals.MouseButton1Click, function() SetActiveTab("Visuals & ESP") end)
Label(QuickCard, "L / GUI   ·   N / MOUSE   ·   DRAG / RESIZE", UDim2.new(1, -25, 0, 22), UDim2.fromOffset(15, 83), 9, Colors.Muted, Enum.Font.Gotham)

AddSection(OverviewPage, "KEYBINDS & CONTROLS")
local Shortcuts = Card(OverviewPage, "ControlGuide", 105)
Label(Shortcuts, "L   Toggle interface      N   Mouse unlock / lock", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(15, 12), 10, Colors.White, Enum.Font.Code)
Label(Shortcuts, "Double-click header   Maximize / Restore", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(15, 41), 10, Colors.Muted, Enum.Font.Code)
Label(Shortcuts, "8 resize zones       Mouse + touch supported", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(15, 70), 10, Colors.Muted, Enum.Font.Code)

AddSection(CharacterPage, "MOVEMENT  /  LIVE OVERRIDES")
AddToggle(CharacterPage, "Apply Speed", "Enable a continuous local WalkSpeed lock", "ApplySpeed")
AddSlider(CharacterPage, "Speed", "S = slider 0–500  |  T = numeric 0–1,000,000", "Speed", 0, 500, 1000000)
AddToggle(CharacterPage, "Apply JumpPower", "Enable a continuous local JumpPower lock", "ApplyJumpPower")
AddSlider(CharacterPage, "JumpPower", "S = slider 0–500  |  T = numeric 0–1,000,000", "JumpPower", 0, 500, 1000000)
local CharacterInfo = Card(CharacterPage, "CharacterInfo", 63)
local CharacterStatusText = Label(CharacterInfo, "Speed and JumpPower are client-only adjustments.", UDim2.new(1, -26, 1, -10), UDim2.fromOffset(15, 5), 10, Colors.Muted, Enum.Font.Gotham)
CharacterStatusText.TextWrapped = true
CharacterStatusText.TextTruncate = Enum.TextTruncate.None

AddSection(VisualsPage, "PLAYER HIGHLIGHTS")
AddToggle(VisualsPage, "Show Global ESP", "White outline and fill for all other players", "ShowGlobalESP")
AddToggle(VisualsPage, "Show Team ESP", "Use each player's team color for their highlight", "ShowTeamESP")
AddSlider(VisualsPage, "ESP Opacity", "Adjust highlight fill transparency (outline remains)", "ESPOpacity", 0, 100, 100)
AddSection(VisualsPage, "LOCAL INVISIBILITY")
AddToggle(VisualsPage, "Invisibility", "Local Air / Bottom test mode — not server invisibility", "Invisibility")
AddModeSelector(VisualsPage)
AddSlider(VisualsPage, "Invisibility Speed", "Movement speed during the active visibility mode", "InvisSpeed", 1, 100, 200)
local ESPNote = Card(VisualsPage, "ESPNote", 70)
local ESPNoteText = Label(ESPNote, "GLOBAL ESP TAKES PRIORITY\nESP refreshes on spawn and team changes.", UDim2.new(1, -24, 1, -14), UDim2.fromOffset(12, 7), 10, Colors.Muted, Enum.Font.GothamSemibold)
ESPNoteText.TextWrapped = true
ESPNoteText.TextTruncate = Enum.TextTruncate.None

AddSection(CameraPage, "VIEWPORT CONTROL")
AddSlider(CameraPage, "Field Of View", "Slider supports 10–300; Roblox applies 10–120°", "FieldOfView", 10, 300, 300)
local FOVNote = Card(CameraPage, "CameraInformation", 87)
Label(FOVNote, "ENGINE LIMITATION", UDim2.new(1, -25, 0, 23), UDim2.fromOffset(14, 11), 10, Colors.Accent, Enum.Font.GothamBold)
local FOVInfo = Label(FOVNote, "The interface accepts up to 300, but Roblox camera FOV is capped at 120 degrees. The original FOV is restored when you wipe the UI.", UDim2.new(1, -27, 0, 55), UDim2.fromOffset(14, 32), 10, Colors.Muted)
FOVInfo.TextWrapped = true
FOVInfo.TextTruncate = Enum.TextTruncate.None

AddSection(ComingPage, "EXPANSION ROADMAP")
for _, data in ipairs({
	{"MODULE 01", "Interface customization", "PLANNED"},
	{"MODULE 02", "Additional camera tools", "PLANNED"},
	{"MODULE 03", "More diagnostic widgets", "PLANNED"}
}) do
	local card = Card(ComingPage, data[1], 75)
	Label(card, data[1], UDim2.new(1, -22, 0, 20), UDim2.fromOffset(14, 10), 9, Colors.Accent, Enum.Font.GothamBold)
	Label(card, data[2], UDim2.new(1, -92, 0, 29), UDim2.fromOffset(14, 31), 12, Colors.White, Enum.Font.GothamSemibold)
	local tag = Label(card, data[3], UDim2.fromOffset(77, 25), UDim2.new(1, -87, 0.5, -12), 9, Colors.Muted, Enum.Font.GothamBold)
	tag.TextXAlignment = Enum.TextXAlignment.Center
end

AddSection(SettingsPage, "CONFIGURATION  /  IMPORT & EXPORT")
local PresetsCard = Card(SettingsPage, "Configuration Presets", 221)
local SaveButton = Button(PresetsCard, "EXPORT CURRENT PRESET", UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 11), Colors.Input, 10)
local PresetText = New("TextBox", PresetsCard, {
	Name = "PresetText",
	Size = UDim2.new(1, -28, 0, 91),
	Position = UDim2.fromOffset(14, 54),
	BackgroundColor3 = Colors.Input,
	BorderSizePixel = 0,
	TextColor3 = Colors.White,
	TextSize = 10,
	Font = Enum.Font.Code,
	Text = "",
	PlaceholderText = "Save to generate JSON or paste a preset here",
	ClearTextOnFocus = false,
	TextWrapped = true,
	MultiLine = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top
})
Corner(PresetText, 5)
Stroke(PresetText, Colors.Border)
New("UIPadding", PresetText, {PaddingTop = UDim.new(0, 7), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7)})
local LoadButton = Button(PresetsCard, "IMPORT PRESET", UDim2.new(1, -28, 0, 31), UDim2.fromOffset(14, 154), Colors.Input, 10)
local PresetStatus = Label(PresetsCard, "Manual JSON import/export (client only)", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 190), 9, Colors.Muted)

Connect(SaveButton.MouseButton1Click, function()
	local ok, result = pcall(function() return HttpService:JSONEncode(Settings) end)
	if ok then
		PresetText.Text = result
		PresetStatus.Text = "Preset ready. Copy the JSON for later."
		PresetStatus.TextColor3 = Colors.Green
		Toast("PRESET EXPORTED", true)
	else
		PresetStatus.Text = "Cannot export preset."
		PresetStatus.TextColor3 = Colors.Accent
	end
end)

Connect(LoadButton.MouseButton1Click, function()
	local ok, decoded = pcall(function() return HttpService:JSONDecode(PresetText.Text) end)
	if not ok or type(decoded) ~= "table" then
		PresetStatus.Text = "Invalid JSON preset."
		PresetStatus.TextColor3 = Colors.Accent
		Toast("INVALID PRESET", false)
		return
	end
	if decoded.InvisibilityMode == "Air" or decoded.InvisibilityMode == "Bottom" then SetSetting("InvisibilityMode", decoded.InvisibilityMode) end
	for _, key in ipairs({"Speed", "JumpPower", "InvisSpeed", "FieldOfView", "ESPOpacity"}) do
		local number = decoded[key]
		if type(number) == "number" and number == number and number ~= math.huge and number ~= -math.huge then
			local minimum = key == "InvisSpeed" and 1 or key == "FieldOfView" and 10 or 0
			local maximum = key == "InvisSpeed" and 200 or key == "FieldOfView" and 300 or key == "ESPOpacity" and 100 or 1000000
			SetSetting(key, math.clamp(number, minimum, maximum))
		end
	end
	for _, key in ipairs({"ApplySpeed", "ApplyJumpPower", "ShowGlobalESP", "ShowTeamESP", "Invisibility"}) do
		if type(decoded[key]) == "boolean" then SetSetting(key, decoded[key]) end
	end
	PresetStatus.Text = "Configuration loaded."
	PresetStatus.TextColor3 = Colors.Green
	Toast("PRESET LOADED", true)
end)

AddSection(SettingsPage, "HOTKEY REFERENCE")
local HotkeyCard = Card(SettingsPage, "Hotkeys", 91)
Label(HotkeyCard, "[ L ]   Open / hide interface", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(15, 9), 10, Colors.White, Enum.Font.Code)
Label(HotkeyCard, "[ N ]   Lock / unlock cursor", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(15, 34), 10, Colors.White, Enum.Font.Code)
Label(HotkeyCard, "[ S / T ]   Slider / textbox mode", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(15, 59), 10, Colors.Muted, Enum.Font.Code)

AddSection(SettingsPage, "DANGER ZONE")
local DestroyCard = Card(SettingsPage, "Destroy Matrix", 112)
Label(DestroyCard, "Completely shuts down all hub connections and UI.", UDim2.new(1, -30, 0, 30), UDim2.fromOffset(15, 12), 10, Colors.Muted)
local DestroyButton = Button(DestroyCard, "DESTROY MATRIX & WIPE GUI", UDim2.new(1, -30, 0, 39), UDim2.fromOffset(15, 59), Color3.fromRGB(83, 27, 37), 11)
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

Connect(ScreenGui:GetAttributeChangedSignal("HussValleyShuttingDown"), function()
	if ScreenGui:GetAttribute("HussValleyShuttingDown") then WipeHub() end
end)

Connect(DestroyButton.MouseButton1Click, function()
	if not ConfirmationActive then
		ConfirmationActive = true
		DestroyButton.Text = "CLICK AGAIN TO CONFIRM"
		Toast("WIPE REQUESTED  /  CONFIRM AGAIN", false)
		task.delay(4, function()
			if alive then ConfirmationActive = false DestroyButton.Text = "DESTROY MATRIX & WIPE GUI" end
		end)
	else
		WipeHub()
	end
end)

local LiveUpdateAccumulator = 0
Connect(RunService.Heartbeat, function(dt)
	if not alive then return end
	LiveUpdateAccumulator += dt
	if LiveUpdateAccumulator < 0.4 then return end
	LiveUpdateAccumulator = 0
	local humanoid = GetCharacter() and GetCharacter():FindFirstChildOfClass("Humanoid")
	local actualSpeed = humanoid and humanoid.WalkSpeed or 0
	local actualJump = humanoid and humanoid.JumpPower or 0
	local fov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
	local espMode = Settings.ShowGlobalESP and "GLOBAL" or Settings.ShowTeamESP and "TEAM" or "OFF"
	FooterLine1.Text = string.format("SPEED  %.0f", actualSpeed)
	FooterLine2.Text = "ESP    " .. espMode
	OverviewSpeed.Text = string.format("WALKSPEED    %d   [%s]", math.floor(actualSpeed), Settings.ApplySpeed and "LOCK" or "FREE")
	OverviewJump.Text = string.format("JUMPPOWER    %d   [%s]", math.floor(actualJump), Settings.ApplyJumpPower and "LOCK" or "FREE")
	OverviewFOV.Text = string.format("CAMERA FOV   %.0f", fov)
	HeaderStatus.Text = "●  CLIENT ACTIVE"
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
local DisplayRectangle = {X = 0, Y = 0, W = 640, H = 490}
local TargetRectangle = {X = 0, Y = 0, W = 640, H = 490}
local HideStatusToken = 0
local HEADER_HEIGHT = HeaderHeight
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
	local sidebarWidth = width < 390 and 99 or width < 520 and 132 or 184
	Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
	Content.Position = UDim2.fromOffset(sidebarWidth, 0)
	Content.Size = UDim2.new(1, -sidebarWidth, 1, 0)
	for name, button in pairs(TabButtons) do
		button.TextWrapped = width < 520
		button.TextSize = width < 390 and 8 or width < 520 and 9 or 10
		button.Text = width < 390 and name or "   " .. name
	end
	MainTitle.Text = width < 485 and "HUSS VALLEY" or "Aehmre's Huss Valley Hub"
	MainTitle.TextSize = width < 485 and 13 or 13
	SideTitle.TextSize = width < 390 and 11 or width < 520 and 14 or 18
	SideSubtitle.TextSize = width < 390 and 7 or 9
	FooterHeading.TextSize = width < 390 and 7 or 9
	FooterLine1.TextSize = width < 390 and 8 or 10
	FooterLine2.TextSize = width < 390 and 8 or 10
	HeaderStatus.Visible = width >= 590
	MainSubtitle.Visible = width >= 460
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
	Position = UDim2.new(1, -(IsTouch and 14 or 9), 0, HeaderHeight - 5),
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
		local original = RestoreRectangle or {X = 50, Y = 50, W = math.min(640, maxWidth), H = math.min(490, maxHeight)}
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
local initialWidth = math.min(640, math.max(1, viewport.X - 16))
local initialHeight = math.min(490, math.max(1, viewport.Y - 16))
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
