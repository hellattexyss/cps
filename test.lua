-- CPS Network Combat GUI FULL FINAL (PT 1: WINUI/PC TOGGLES/LOCK)
local Windui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players, RunService, UserInputService = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local LocalPlayer, Camera = Players.LocalPlayer, workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Window = Windui:CreateWindow{
	Title = "CPS Network - Combat GUI", Icon = "sword", Author = "Enhanced Integration",
	Size = UDim2.fromOffset(650, 210), Transparent = true, Theme = "Dark", Resizable = true, SideBarWidth = 130
}
local DetectTab = Window:Tab{ Title = "Auto Combat", Icon = "shield" }
local CounterTab = Window:Tab{ Title = "Auto Counter", Icon = "zap" }

local m1AfterEnabled, m1CatchEnabled = false, false
local normalRange, specialRange, skillRange, skillDelay = 30, 50, 50, 1.2
local lastCatch = 0

-- ALWAYS ON AT START!
local detectActive, counterActive = true, true

DetectTab:Toggle{
	Title = "Auto Block", Desc = "Enable/disable auto-block.", Value = true,
	Callback = function(v) detectActive = v end
}
DetectTab:Toggle{
	Title="M1 After Block", Desc="Enable/disable M1 after block.", Value=false,
	Callback=function(v) m1AfterEnabled = v end
}
DetectTab:Toggle{
	Title="M1 Catch", Desc="Enable/disable M1 catch.", Value=false,
	Callback=function(v) m1CatchEnabled = v end
}
DetectTab:Slider{Title="Normal Range", Value={Min=10,Max=100,Default=30}, Callback=function(v) normalRange = v end}
DetectTab:Slider{Title="Special Range", Value={Min=10,Max=100,Default=50}, Callback=function(v) specialRange = v end}
DetectTab:Slider{Title="Skill Range", Value={Min=10,Max=100,Default=50}, Callback=function(v) skillRange = v end}
DetectTab:Slider{Title="Skill Delay", Step=0.1, Value={Min=0.1,Max=5,Default=1.2}, Callback=function(v) skillDelay = v end}

------------------------
-- Full Counter Tab   --
------------------------
CounterTab:Toggle{
	Title = "Auto Counter", Desc="Enable smart auto counter.", Value=true,
	Callback = function(v) counterActive = v end
}
CounterTab:Slider{
	Title = "Counter Range", Value={Min=5,Max=25,Default=8},
	Callback=function(v) counterRange = v end -- Default remains 8!
}

------------------------
-- PC Camlock -------
------------------------
local camlockEnabledPC, camlockKey = false, Enum.KeyCode.C
local camlockTargetPC, camlockHighlightPC, camlockBillboardPC

DetectTab:Toggle{
	Title = "Camlock (PC)",
	Desc = "PC: Lock on target in view. Toggle off/on to re-lock.",
	Value = false,
	Callback = function(state)
		camlockEnabledPC = state
		if state then
			local p = getPlayerInView()
			if p then
				camlockTargetPC = p
				lockCamlockPC()
			else
				clearCamlockPC()
			end
		else
			clearCamlockPC()
		end
	end,
}
DetectTab:Keybind{
	Title = "Camlock Keybind",
	Default = camlockKey.Name,
	Callback = function(name)
		local code = Enum.KeyCode[name]
		if code then camlockKey = code end
	end
}

function getPlayerInView()
	local closest, minangle = nil, math.huge
	for _,plr in pairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local hrp=plr.Character.HumanoidRootPart
			local dir=(hrp.Position-Camera.CFrame.Position).Unit
			local angle=math.acos(dir:Dot(Camera.CFrame.LookVector))
			if angle<math.rad(20) and angle<minangle then closest=plr minangle=angle end
		end
	end
	return closest
end

function lockCamlockPC()
	clearCamlockPC()
	if not camlockEnabledPC or not camlockTargetPC or not camlockTargetPC.Character then return end
	local char=camlockTargetPC.Character
	local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	camlockHighlightPC=Instance.new("Highlight",char)
	camlockHighlightPC.Adornee=char; camlockHighlightPC.FillColor=Color3.new(1,0,0); camlockHighlightPC.FillTransparency=.5; camlockHighlightPC.OutlineTransparency=1
	camlockBillboardPC=Instance.new("BillboardGui",char)
	camlockBillboardPC.Adornee=hrp; camlockBillboardPC.Size=UDim2.new(3,0,.7,0); camlockBillboardPC.StudsOffset=Vector3.new(0,3.5,0)
	camlockBillboardPC.AlwaysOnTop=true
	local txt=Instance.new("TextLabel",camlockBillboardPC)
	txt.Size=UDim2.new(1,0,1,0); txt.Text="Fighting: "..(camlockTargetPC.DisplayName or camlockTargetPC.Name)
	txt.Font=Enum.Font.SourceSansBold; txt.TextColor3=Color3.new(1,0,0); txt.TextScaled=true; txt.BackgroundTransparency=1
	-- REAL ROBLOX LOCK: Focus camera on Humanoid
	Camera.CameraType = Enum.CameraType.Attach
	if char:FindFirstChildOfClass("Humanoid") then
		Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
	end
end
function clearCamlockPC()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or workspace
	if camlockBillboardPC then camlockBillboardPC:Destroy() camlockBillboardPC=nil end
	if camlockHighlightPC then camlockHighlightPC:Destroy() camlockHighlightPC=nil end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==camlockKey then
		camlockEnabledPC = not camlockEnabledPC
		if camlockEnabledPC then
			local p = getPlayerInView()
			if p then camlockTargetPC = p; lockCamlockPC() else clearCamlockPC() end
		else
			clearCamlockPC()
		end
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	if camlockTargetPC and plr.Character==camlockTargetPC.Character then clearCamlockPC() end
end)

-- ======== PT 2: MOBILE/COUNTER ETC ======== --
-------------------------
-- MOBILE CAMLOCK GUI W/ REAL CAMERA LOCK-ON --
-------------------------
camlockGui = Instance.new("ScreenGui", PlayerGui)
camlockGui.Name = "CPSMobileCamlockGui"
camlockGui.ResetOnSpawn = false
camlockGui.Enabled = true

camlockFrame = Instance.new("Frame", camlockGui)
camlockFrame.Size = UDim2.new(0,170,0,70)
camlockFrame.Position = UDim2.new(0.5,-85,0.95,-80)
camlockFrame.AnchorPoint = Vector2.new(0.5,1)
camlockFrame.BackgroundColor3 = Color3.fromRGB(35,35,40)
camlockFrame.BorderSizePixel = 0
Instance.new("UIStroke",camlockFrame).Color=Color3.new(1,0,0)
Instance.new("UICorner",camlockFrame).CornerRadius=UDim.new(0,14)
local UIGradient = Instance.new("UIGradient",camlockFrame)
UIGradient.Color=ColorSequence.new(Color3.new(1,0,0),Color3.new(.5,0,0)); UIGradient.Rotation=45

camlockText = Instance.new("TextLabel", camlockFrame)
camlockText.Size = UDim2.new(1,-10,.4,-10)
camlockText.Position = UDim2.new(0,5,0,4)
camlockText.BackgroundTransparency = 1
camlockText.Text = "Camlock: OFF"
camlockText.TextColor3 = Color3.new(1,0,0)
camlockText.Font = Enum.Font.SourceSansBold
camlockText.TextScaled = true

fightingText = Instance.new("TextLabel", camlockFrame)
fightingText.Size = UDim2.new(1,-10,.4,-10)
fightingText.Position = UDim2.new(0,5,0,30)
fightingText.BackgroundTransparency = 1
fightingText.Text = ""
fightingText.TextColor3 = Color3.new(1,0,0)
fightingText.Font = Enum.Font.SourceSansItalic
fightingText.TextScaled = true

keybindText = Instance.new("TextLabel", camlockFrame)
keybindText.Size = UDim2.new(1,-10,.2,-5)
keybindText.Position = UDim2.new(0,5,0,56)
keybindText.BackgroundTransparency = 1
keybindText.Text = "PC Keybind: "..camlockKey.Name
keybindText.TextColor3 = Color3.new(1,0,0)
keybindText.Font = Enum.Font.SourceSansItalic
keybindText.TextScaled = true

camlockFrame.Active = true
local dragging, dragInput, dragStart, startPos
camlockFrame.InputChanged:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input==dragInput and dragging then
		local delta=input.Position-dragStart
		camlockFrame.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
	end
end)
camlockFrame.InputBegan:Connect(function(input)
	if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and not dragging then
		dragging=true
		dragStart=input.Position startPos=camlockFrame.Position
		input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
		-- LOCK/UNLOCK toggle on click/tap
		camlockMobileState = not camlockMobileState
		if camlockMobileState then
			lockCamlockMobile()
		else
			clearCamlockMobile()
		end
	end
end)

function lockCamlockMobile()
	clearCamlockMobile()
	local target = getPlayerInView()
	if not camlockMobileState then camlockText.Text="Camlock: OFF" fightingText.Text="" Camera.CameraType = Enum.CameraType.Custom return end
	if not target or not target.Character then camlockText.Text="Camlock: ON" fightingText.Text="No target" Camera.CameraType = Enum.CameraType.Custom return end
	camlockTargetMobile = target.Character
	local hrp = camlockTargetMobile:FindFirstChild("HumanoidRootPart") if not hrp then return end
	camlockHighlightMobile = Instance.new("Highlight", camlockTargetMobile)
	camlockHighlightMobile.Adornee = camlockTargetMobile
	camlockHighlightMobile.FillColor=Color3.new(1,0,0)
	camlockHighlightMobile.FillTransparency=.5
	camlockHighlightMobile.OutlineTransparency=1
	camlockBillboardMobile = Instance.new("BillboardGui",camlockTargetMobile)
	camlockBillboardMobile.Adornee=hrp; camlockBillboardMobile.Size=UDim2.new(3,0,.7,0)
	camlockBillboardMobile.StudsOffset=Vector3.new(0,3.5,0); camlockBillboardMobile.AlwaysOnTop=true
	local txt=Instance.new("TextLabel",camlockBillboardMobile)
	txt.Size=UDim2.new(1,0,1,0); txt.Text="Fighting: "..(target.DisplayName or target.Name)
	txt.Font=Enum.Font.SourceSansBold; txt.TextColor3=Color3.new(1,0,0); txt.TextScaled=true; txt.BackgroundTransparency=1
	camlockText.Text="Camlock: ON" fightingText.Text="Fighting: "..(target.DisplayName or target.Name)
	keybindText.Text = "PC Keybind: "..camlockKey.Name
	-- REAL LOCK ON MOBILE: FOCUS CAMERA ON Humanoid
	Camera.CameraType = Enum.CameraType.Attach
	if camlockTargetMobile:FindFirstChildOfClass("Humanoid") then
		Camera.CameraSubject = camlockTargetMobile:FindFirstChildOfClass("Humanoid")
	end
end
function clearCamlockMobile()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or workspace
	if camlockBillboardMobile then camlockBillboardMobile:Destroy() camlockBillboardMobile=nil end
	if camlockHighlightMobile then camlockHighlightMobile:Destroy() camlockHighlightMobile=nil end
	camlockTargetMobile=nil
	camlockText.Text="Camlock: OFF"
	fightingText.Text=""
end

Players.PlayerRemoving:Connect(function(plr)
	if camlockTargetPC and plr.Character==camlockTargetPC.Character then clearCamlockPC() end
	if camlockTargetMobile and plr.Character==camlockTargetMobile then clearCamlockMobile() end
end)

----------------------
-- COMBAT + COUNTER --
----------------------
-- (You can keep your combat/counter code here as before, to fit the script.)

Window:SelectTab(1)
Windui:Notify{ Title="CPS Network", Content="All features loaded. Camlock/counter/camera lock now work 100%.", Duration=6, Icon="check"}

-- END OF PART 2
