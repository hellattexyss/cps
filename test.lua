-- CPS Network Combat GUI - FINAL EVERYTHING FIXED (PT 1/2)
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
local detectActive, counterActive = true, true -- Always on on script-load!
local counterRange = 8

DetectTab:Toggle{Title = "Auto Block", Desc = "Enable/disable auto-block.", Value = true, Callback = function(v) detectActive = v end}
DetectTab:Toggle{Title="M1 After Block", Desc="Enable/disable M1 after block.", Value=false, Callback=function(v) m1AfterEnabled = v end}
DetectTab:Toggle{Title="M1 Catch", Desc="Enable/disable M1 catch.", Value=false, Callback=function(v) m1CatchEnabled = v end}
DetectTab:Slider{Title="Normal Range", Value={Min=10,Max=100,Default=30}, Callback=function(v) normalRange = v end}
DetectTab:Slider{Title="Special Range", Value={Min=10,Max=100,Default=50}, Callback=function(v) specialRange = v end}
DetectTab:Slider{Title="Skill Range", Value={Min=10,Max=100,Default=50}, Callback=function(v) skillRange = v end}
DetectTab:Slider{Title="Skill Delay", Step=0.1, Value={Min=0.1,Max=5,Default=1.2}, Callback=function(v) skillDelay = v end}

CounterTab:Toggle{Title = "Auto Counter", Desc="Enable smart auto counter.", Value=true, Callback=function(v) counterActive = v end}
CounterTab:Slider{Title = "Counter Range", Value={Min=5,Max=25,Default=8}, Callback=function(v) counterRange = v end}

-----------------------------------------------------------
-- True player get (only alive, in camera, not props/air)
-----------------------------------------------------------
function getPlayerInView()
	local camPos, camLook = Camera.CFrame.Position, Camera.CFrame.LookVector
	local closest, minDot = nil, math.cos(math.rad(25)) -- "25 degrees" arc, feel free to tighten.
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum.Health > 0 and not hum:GetStateEnabled(Enum.HumanoidStateType.Dead) and plr.Character.HumanoidRootPart:IsDescendantOf(workspace) then
				local dir = (plr.Character.HumanoidRootPart.Position - camPos).Unit
				local dot = dir:Dot(camLook)
				if dot > minDot then
					minDot, closest = dot, plr
				end
			end
		end
	end
	return closest
end

---------------------------------------------------
-- PC Camlock: Hard camera look, true focus logic
---------------------------------------------------
local camlockEnabledPC, camlockKey = false, Enum.KeyCode.C
local camlockTargetPC, camlockHighlightPC, camlockBillboardPC

DetectTab:Toggle{
	Title = "Camlock (PC)",
	Desc = "PC: Hard aim at real player in camera. Toggle off/on to re-lock.",
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

function lockCamlockPC()
	clearCamlockPC()
	if not camlockEnabledPC or not camlockTargetPC or not camlockTargetPC.Character then return end
	local char=camlockTargetPC.Character
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then clearCamlockPC() return end
	camlockHighlightPC=Instance.new("Highlight",char)
	camlockHighlightPC.Adornee=char; camlockHighlightPC.FillColor=Color3.new(1,0,0); camlockHighlightPC.FillTransparency=.5; camlockHighlightPC.OutlineTransparency=1
	camlockBillboardPC=Instance.new("BillboardGui",char)
	camlockBillboardPC.Adornee=hrp; camlockBillboardPC.Size=UDim2.new(3,0,.7,0); camlockBillboardPC.StudsOffset=Vector3.new(0,3.5,0)
	camlockBillboardPC.AlwaysOnTop=true
	local txt=Instance.new("TextLabel",camlockBillboardPC)
	txt.Size=UDim2.new(1,0,1,0); txt.Text="Fighting: "..(camlockTargetPC.DisplayName or camlockTargetPC.Name)
	txt.Font=Enum.Font.SourceSansBold; txt.TextColor3=Color3.new(1,0,0); txt.TextScaled=true; txt.BackgroundTransparency=1
	RunService:UnbindFromRenderStep("PC_CamlockLook")
	RunService:BindToRenderStep("PC_CamlockLook", Enum.RenderPriority.Camera.Value+5, function()
		if camlockEnabledPC and camlockTargetPC and camlockTargetPC.Character and camlockTargetPC.Character:FindFirstChild("HumanoidRootPart")
			and camlockTargetPC.Character:FindFirstChildOfClass("Humanoid") and camlockTargetPC.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			local root = camlockTargetPC.Character.HumanoidRootPart
			local myPos = Camera.CFrame.Position
			Camera.CFrame = CFrame.new(myPos, root.Position)
		else
			clearCamlockPC()
		end
	end)
end
function clearCamlockPC()
	RunService:UnbindFromRenderStep("PC_CamlockLook")
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
	if camlockTargetPC and plr==camlockTargetPC then clearCamlockPC() end
end)

-- PART 2 immediately below! --
-------------------------
-- MOBILE CAMLOCK GUI, REAL CAM LOOK (LIVE ONLY)
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
local camlockMobileState, camlockTargetMobile, camlockHighlightMobile, camlockBillboardMobile = false
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
		camlockMobileState = not camlockMobileState
		if camlockMobileState then lockCamlockMobile() else clearCamlockMobile() end
	end
end)

function lockCamlockMobile()
	clearCamlockMobile()
	local target = getPlayerInView()
	if not camlockMobileState then camlockText.Text="Camlock: OFF" fightingText.Text=""
		RunService:UnbindFromRenderStep("Mobile_CamlockLook") return end
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart")
		or not target.Character:FindFirstChildOfClass("Humanoid")
		or target.Character:FindFirstChildOfClass("Humanoid").Health <= 0
		then
		camlockText.Text="Camlock: ON" fightingText.Text="No valid target"
		RunService:UnbindFromRenderStep("Mobile_CamlockLook")
		return
	end
	camlockTargetMobile = target.Character
	local hum = camlockTargetMobile:FindFirstChildOfClass("Humanoid")
	local hrp = camlockTargetMobile:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then camlockText.Text="Camlock: ON" fightingText.Text="No valid target"
		RunService:UnbindFromRenderStep("Mobile_CamlockLook") return end

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

	RunService:UnbindFromRenderStep("Mobile_CamlockLook")
	RunService:BindToRenderStep("Mobile_CamlockLook", Enum.RenderPriority.Camera.Value+5, function()
		if camlockMobileState and camlockTargetMobile and camlockTargetMobile:FindFirstChild("HumanoidRootPart") then
			local root = camlockTargetMobile:FindFirstChild("HumanoidRootPart")
			local myPos = Camera.CFrame.Position
			Camera.CFrame = CFrame.new(myPos, root.Position)
		else
			clearCamlockMobile()
		end
	end)
end
function clearCamlockMobile()
	RunService:UnbindFromRenderStep("Mobile_CamlockLook")
	if camlockBillboardMobile then camlockBillboardMobile:Destroy() camlockBillboardMobile=nil end
	if camlockHighlightMobile then camlockHighlightMobile:Destroy() camlockHighlightMobile=nil end
	camlockTargetMobile=nil
	camlockText.Text="Camlock: OFF"
	fightingText.Text=""
end
Players.PlayerRemoving:Connect(function(plr)
	if camlockTargetPC and plr==camlockTargetPC then clearCamlockPC() end
	if camlockTargetMobile and plr.Character==camlockTargetMobile then clearCamlockMobile() end
end)

-----------------------------------------------------------
-- AUTO-COMBAT + COUNTER (leave your normal logic below)
-----------------------------------------------------------
-- ... Insert your unchanged combat/counter logic below here ...

Window:SelectTab(1)
Windui:Notify{ Title="CPS Network", Content="All features loaded. Camlock now perfect.", Duration=6, Icon="check"}
