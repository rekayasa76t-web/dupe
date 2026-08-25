-- NXROT DUPE ONLY
-- Single-session guard:
-- This script creates several long-lived Roblox connections. Running the same
-- script repeatedly without disconnecting the old session accumulates those
-- connections and eventually hits the executor's connection limit.
local __NXROTEnv = (type(getgenv)=="function" and getgenv()) or _G
if __NXROTEnv.__NXROTMineMountainActive then
	return
end
__NXROTEnv.__NXROTMineMountainActive=true

-- NXROT: DUPE ONLY
-- ============================================================
-- [1] SERVICES
local S = {
	Players = game:GetService("Players"),
	CoreGui = game:GetService("CoreGui"),
	HttpService = game:GetService("HttpService"),
	TeleportService = game:GetService("TeleportService"),
	GuiService = game:GetService("GuiService"),
	UserInputService  = game:GetService("UserInputService"),
	TweenService      = game:GetService("TweenService"),
}
local LocalPlayer = S.Players.LocalPlayer

-- ============================================================
-- STARTUP KEY GATE
-- DEV_MODE = true  -> bypass key validation for testing
-- DEV_MODE = false -> valid getgenv().key is required
-- ============================================================
local DEV_MODE = (rawget(_G, "__dhub_dev") ~= nil) or false

-- [2] CONFIG LOAD
local CONFIG_PATH = "NXROT/MineAMountainV4.json"
pcall(function() if isfolder and not isfolder("NXROT") then makefolder("NXROT") end end)
local LoadedCfg   = {}
pcall(function()
	local content = readfile(CONFIG_PATH)
	if type(content) == "string" and content ~= "" then
		LoadedCfg = S.HttpService:JSONDecode(content)
	end
end)
if type(LoadedCfg) ~= "table" then LoadedCfg = {} end


-- [4] GUI ROOT
function resolveGuiRoot()
	local ok, h = pcall(function() return gethui() end)
	if ok and typeof(h) == "Instance" then return h end
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	return LocalPlayer:WaitForChild("PlayerGui", 10) or S.CoreGui
end
local GuiRoot = resolveGuiRoot()
for _, container in ipairs({GuiRoot, S.CoreGui}) do
		pcall(function()
			local e = container:FindFirstChild(name)
			if e then e:Destroy() end
		end)
	end


-- [10] NOTIFY
function Notify(text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{
			Title="NXROT", Text=tostring(text), Duration=duration or 3
		})
	end)
end

-- Startup key validation
function validateStartupKey()
    if DEV_MODE == true then return true end
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local key = nil
    pcall(function() key = env.key end)
    if key == nil then pcall(function() key = _G.key end) end
    key = tostring(key or ""):match("^%s*(.-)%s*$") or ""
    return key == "NXROT"
end

-- ============================================================
-- STARTUP LICENSE GATE
-- No UI/farming features are initialized until the key is valid.
-- ============================================================
if not validateStartupKey() then
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{
			Title="NXROT", Text="Wrong Key", Duration=2
		})
	end)
	task.wait(1)
	pcall(function() LocalPlayer:Kick("NXROT | Wrong Key") end)
	return
end

function UIH_Corner(UI,p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6) end

function UIH_Stroke(UI,p,col,th) local s=Instance.new("UIStroke",p); s.Color=col or UI.C.BORDER; s.Thickness=th or 1; return s end

function UIH_MakeDraggable(UI,frame,handle)
		local drag,ds,sp
		handle.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
				drag=true; ds=inp.Position; sp=frame.Position
				inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
			end
		end)
		S.UserInputService.InputChanged:Connect(function(inp)
			if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
				local d=inp.Position-ds
				frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
			end
		end)
	end

function UIH_BuatPage(UI,name)
		local Page=Instance.new("ScrollingFrame",UI.ContentArea)
		Page.Name=name; Page.Size=UDim2.new(1,0,1,0); Page.BackgroundTransparency=1
		Page.BorderSizePixel=0; Page.ScrollBarThickness=4; Page.ScrollBarImageColor3=UI.C.DIVIDER; Page.Visible=false
		local Layout=Instance.new("UIListLayout",Page)
		Layout.Padding=UDim.new(0,8); Layout.SortOrder=Enum.SortOrder.LayoutOrder
		local Pad=Instance.new("UIPadding",Page)
		Pad.PaddingTop=UDim.new(0,15); Pad.PaddingBottom=UDim.new(0,15)
		Pad.PaddingLeft=UDim.new(0,15); Pad.PaddingRight=UDim.new(0,15)
		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize=UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+30)
		end)
		UI.Pages[name]=Page; return Page
	end

function UIH_SwitchTab(UI,targetName)
		for name,page in pairs(UI.Pages) do page.Visible=(name==targetName) end
		for name,btnData in pairs(UI.NavButtons) do
			local isActive=(name==targetName)
			S.TweenService:Create(btnData.Indicator,TweenInfo.new(0.2),{BackgroundTransparency=isActive and 0 or 1}):Play()
			S.TweenService:Create(btnData.Label,TweenInfo.new(0.2),{TextColor3=isActive and UI.C.TEXT_1 or UI.C.TEXT_2}):Play()
			S.TweenService:Create(btnData.Btn,TweenInfo.new(0.2),{BackgroundColor3=isActive and UI.C.ELEVATED or UI.C.SURFACE}):Play()
		end
	end

function UIH_BuatNavButton(UI,name)
		local Btn=Instance.new("TextButton",UI.TabContainer)
		Btn.Size=UDim2.new(1,-16,0,36); Btn.BackgroundColor3=UI.C.SURFACE
		Btn.BorderSizePixel=0; Btn.Text=""; Btn.AutoButtonColor=false; UIH_Corner(UI,Btn,6)
		local Indicator=Instance.new("Frame",Btn)
		Indicator.Size=UDim2.new(0,3,0,18); Indicator.Position=UDim2.new(0,0,0.5,-9)
		Indicator.BackgroundColor3=UI.C.ACCENT; Indicator.BorderSizePixel=0; Indicator.BackgroundTransparency=1; UIH_Corner(UI,Indicator,2)
		local Label=Instance.new("TextLabel",Btn)
		Label.Size=UDim2.new(1,-16,1,0); Label.Position=UDim2.new(0,12,0,0)
		Label.BackgroundTransparency=1; Label.Text=name; Label.TextColor3=UI.C.TEXT_2
		Label.Font=Enum.Font.GothamMedium; Label.TextSize=12; Label.TextXAlignment=Enum.TextXAlignment.Left
		Btn.MouseButton1Click:Connect(function() UIH_SwitchTab(UI,name) end)
		UI.NavButtons[name]={Btn=Btn,Indicator=Indicator,Label=Label}
	end

function UIH_BuatSection(UI,parent,text)
		local Lbl=Instance.new("TextLabel",parent)
		Lbl.Size=UDim2.new(1,0,0,20); Lbl.BackgroundTransparency=1
		Lbl.Font=Enum.Font.GothamBold; Lbl.TextColor3=UI.C.TEXT_2
		Lbl.Text=text:upper(); Lbl.TextSize=11; Lbl.TextXAlignment=Enum.TextXAlignment.Left
	end

function UIH_BuatToggle(UI,parent,label,sublabel,defaultState,accentColor)
	local Row=Instance.new("Frame",parent)
	Row.Size=UDim2.new(1,0,0,42); Row.BackgroundColor3=UI.C.SURFACE; UIH_Corner(UI,Row,6)
	local RowStroke=UIH_Stroke(UI,Row,UI.C.BORDER)
	local LeftAccent=Instance.new("Frame",Row)
	LeftAccent.Size=UDim2.new(0,2,0,18); LeftAccent.Position=UDim2.new(0,0,0.5,-9)
	LeftAccent.BackgroundColor3=UI.C.BORDER; UIH_Corner(UI,LeftAccent,1)
	local LabelTxt=Instance.new("TextLabel",Row)
	LabelTxt.Size=UDim2.new(1,-70,1,0); LabelTxt.Position=UDim2.new(0,14,0,0)
	LabelTxt.BackgroundTransparency=1; LabelTxt.Text=label
	LabelTxt.TextColor3=UI.C.TEXT_2; LabelTxt.Font=Enum.Font.GothamMedium; LabelTxt.TextSize=12; LabelTxt.TextXAlignment=Enum.TextXAlignment.Left
	local Pill=Instance.new("Frame",Row)
	Pill.Size=UDim2.new(0,38,0,20); Pill.Position=UDim2.new(1,-50,0.5,-10); Pill.BackgroundColor3=UI.C.DIVIDER; UIH_Corner(UI,Pill,10)
	local PillDot=Instance.new("Frame",Pill)
	PillDot.Size=UDim2.new(0,14,0,14); PillDot.Position=UDim2.new(0,3,0.5,-7); PillDot.BackgroundColor3=UI.C.TEXT_3; UIH_Corner(UI,PillDot,7)
	local Btn=Instance.new("TextButton",Row)
	Btn.Size=UDim2.new(1,0,1,0); Btn.BackgroundTransparency=1; Btn.Text=""
	local accent=accentColor or UI.C.ACCENT
	local accentD=accentColor and accentColor:lerp(Color3.new(0,0,0),0.25) or UI.C.ACCENT_D
	local function SetInstant(on)
		Row.BackgroundColor3=on and UI.C.ELEVATED or UI.C.SURFACE
		RowStroke.Color=on and accentD or UI.C.BORDER
		LabelTxt.TextColor3=on and UI.C.TEXT_1 or UI.C.TEXT_2
		LeftAccent.BackgroundColor3=on and accent or UI.C.BORDER
		Pill.BackgroundColor3=on and accentD or UI.C.DIVIDER
		PillDot.Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
		PillDot.BackgroundColor3=on and accent or UI.C.TEXT_3
	end
	local function SetTween(on)
		S.TweenService:Create(Row,TweenInfo.new(0.2),{BackgroundColor3=on and UI.C.ELEVATED or UI.C.SURFACE}):Play()
		RowStroke.Color=on and accentD or UI.C.BORDER
		LabelTxt.TextColor3=on and UI.C.TEXT_1 or UI.C.TEXT_2
		LeftAccent.BackgroundColor3=on and accent or UI.C.BORDER
		S.TweenService:Create(Pill,TweenInfo.new(0.2),{BackgroundColor3=on and accentD or UI.C.DIVIDER}):Play()
		S.TweenService:Create(PillDot,TweenInfo.new(0.2),{
			Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
			BackgroundColor3=on and accent or UI.C.TEXT_3,
		}):Play()
	end
	SetInstant(defaultState==true)
	return Btn,SetTween
end

function UIH_BuatButton(UI,parent,label,sublabel,bgColor)
	local Row=Instance.new("TextButton",parent)
	Row.Size=UDim2.new(1,0,0,36); Row.BackgroundColor3=bgColor or UI.C.SURFACE
	Row.Text=""; Row.AutoButtonColor=false; UIH_Corner(UI,Row,6); UIH_Stroke(UI,Row,UI.C.BORDER)
	local LeftAccent=Instance.new("Frame",Row)
	LeftAccent.Size=UDim2.new(0,2,0,18); LeftAccent.Position=UDim2.new(0,0,0.5,-9)
	LeftAccent.BackgroundColor3=UI.C.BORDER; UIH_Corner(UI,LeftAccent,1)
	local LabelTxt=Instance.new("TextLabel",Row)
	LabelTxt.Size=UDim2.new(1,-20,1,0); LabelTxt.Position=UDim2.new(0,14,0,0)
	LabelTxt.BackgroundTransparency=1; LabelTxt.Text=label
	LabelTxt.TextColor3=UI.C.TEXT_1; LabelTxt.Font=Enum.Font.GothamMedium; LabelTxt.TextSize=12; LabelTxt.TextXAlignment=Enum.TextXAlignment.Left
	return Row
end

function UIH_BuatSlider(UI,parent,label,min,max,default,callback)
		local Row=Instance.new("Frame",parent)
		Row.Size=UDim2.new(1,0,0,50); Row.BackgroundColor3=UI.C.SURFACE; UIH_Corner(UI,Row,6); UIH_Stroke(UI,Row,UI.C.BORDER)
		local LabelTxt=Instance.new("TextLabel",Row)
		LabelTxt.Size=UDim2.new(0.7,0,0,20); LabelTxt.Position=UDim2.new(0,14,0,5)
		LabelTxt.BackgroundTransparency=1; LabelTxt.Text=label..": "..tostring(default)
		LabelTxt.TextColor3=UI.C.TEXT_1; LabelTxt.Font=Enum.Font.GothamMedium; LabelTxt.TextSize=11; LabelTxt.TextXAlignment=Enum.TextXAlignment.Left
		local Track=Instance.new("Frame",Row)
		Track.Size=UDim2.new(1,-28,0,4); Track.Position=UDim2.new(0,14,1,-12); Track.BackgroundColor3=UI.C.DIVIDER; UIH_Corner(UI,Track,2)
		local Progress=Instance.new("Frame",Track); Progress.Size=UDim2.new(0,0,1,0); Progress.BackgroundColor3=UI.C.ACCENT; UIH_Corner(UI,Progress,2)
		local Thumb=Instance.new("Frame",Track)
		Thumb.Size=UDim2.new(0,12,0,12); Thumb.Position=UDim2.new(0,-6,0.5,-6); Thumb.BackgroundColor3=UI.C.TEXT_1; UIH_Corner(UI,Thumb,6)
		local Dragger=Instance.new("TextButton",Track)
		Dragger.Size=UDim2.new(1,0,3,0); Dragger.Position=UDim2.new(0,0,-1,0); Dragger.BackgroundTransparency=1; Dragger.Text=""
		local function UpdateSlider(value)
			local pct=math.clamp((value-min)/(max-min),0,1)
			Progress.Size=UDim2.new(pct,0,1,0); Thumb.Position=UDim2.new(pct,-6,0.5,-6)
			LabelTxt.Text=label..": "..string.format("%d",value); callback(math.floor(value))
		end
		UpdateSlider(default)
		local dragging=false
		Dragger.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
		end)
		Dragger.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
		end)
		S.UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
				local relX=i.Position.X-Track.AbsolutePosition.X
				local pct=math.clamp(relX/Track.AbsoluteSize.X,0,1)
				UpdateSlider(min+(max-min)*pct)
			end
		end)
		return Row
	end

function UIH_BuatInput(UI,parent,label,placeholder,default,callback)
		local Row=Instance.new("Frame",parent)
		Row.Size=UDim2.new(1,0,0,42); Row.BackgroundColor3=UI.C.SURFACE; UIH_Corner(UI,Row,6); UIH_Stroke(UI,Row,UI.C.BORDER)
		local LabelTxt=Instance.new("TextLabel",Row)
		LabelTxt.Size=UDim2.new(0.5,-20,1,0); LabelTxt.Position=UDim2.new(0,14,0,0)
		LabelTxt.BackgroundTransparency=1; LabelTxt.Text=label
		LabelTxt.TextColor3=UI.C.TEXT_1; LabelTxt.Font=Enum.Font.GothamMedium; LabelTxt.TextSize=12; LabelTxt.TextXAlignment=Enum.TextXAlignment.Left
		local InputBox=Instance.new("TextBox",Row)
		InputBox.Size=UDim2.new(0.4,0,0,24); InputBox.Position=UDim2.new(0.6,-14,0.5,-12)
		InputBox.BackgroundColor3=UI.C.ELEVATED; UIH_Corner(UI,InputBox,4); UIH_Stroke(UI,InputBox,UI.C.DIVIDER)
		InputBox.Text=default or ""; InputBox.PlaceholderText=placeholder or ""
		InputBox.TextColor3=UI.C.TEXT_1; InputBox.Font=Enum.Font.Gotham; InputBox.TextSize=11
		InputBox.FocusLost:Connect(function() callback(InputBox.Text) end)
		return Row
	end

function UIH_BuatDropdown(UI,parent, label, options, isMulti, defaultSelected, callback)
		local selected = isMulti and {} or ""
		if isMulti and type(defaultSelected)=="table" then
			for _,v in ipairs(defaultSelected) do
				if type(v)=="string" and v~="Default" and v~="" then selected[v]=true end
			end
		elseif not isMulti and type(defaultSelected)=="string" then
			selected=(defaultSelected=="Default") and "" or defaultSelected
		end
		local function displayText()
			if isMulti then
				local keys={}; for k in pairs(selected) do keys[#keys+1]=k end
				if #keys==0 then return "[Default]" end
				table.sort(keys)
				if #keys==1 then return keys[1] end
				return keys[1].." +"..tostring(#keys-1)
			else
				return selected=="" and "[Default]" or selected
			end
		end
		local Row=Instance.new("Frame",parent)
		Row.Size=UDim2.new(1,0,0,42); Row.BackgroundColor3=UI.C.SURFACE; UIH_Corner(UI,Row,6); UIH_Stroke(UI,Row,UI.C.BORDER)
		local LabelTxt=Instance.new("TextLabel",Row)
		LabelTxt.Size=UDim2.new(0.42,0,1,0); LabelTxt.Position=UDim2.new(0,14,0,0)
		LabelTxt.BackgroundTransparency=1; LabelTxt.Text=label
		LabelTxt.TextColor3=UI.C.TEXT_2; LabelTxt.Font=Enum.Font.GothamMedium; LabelTxt.TextSize=11; LabelTxt.TextXAlignment=Enum.TextXAlignment.Left
		local DropBtn=Instance.new("TextButton",Row)
		DropBtn.Size=UDim2.new(0.55,0,0,28); DropBtn.Position=UDim2.new(0.44,0,0.5,-14)
		DropBtn.BackgroundColor3=UI.C.ELEVATED; UIH_Corner(UI,DropBtn,4); UIH_Stroke(UI,DropBtn,UI.C.DIVIDER)
		DropBtn.Text=displayText(); DropBtn.TextColor3=UI.C.TEXT_1
		DropBtn.Font=Enum.Font.GothamMedium; DropBtn.TextSize=11
		DropBtn.AutoButtonColor=false
		local Panel=Instance.new("Frame",UI.MainSG)
		Panel.Size=UDim2.new(0,220,0,math.min(#options*28+8,180))
		Panel.BackgroundColor3=UI.C.ELEVATED; UIH_Corner(UI,Panel,6); UIH_Stroke(UI,Panel,UI.C.BORDER)
		Panel.Visible=false; Panel.ZIndex=20
		local PanelScroll=Instance.new("ScrollingFrame",Panel)
		PanelScroll.Size=UDim2.new(1,-4,1,-4); PanelScroll.Position=UDim2.new(0,2,0,2)
		PanelScroll.BackgroundTransparency=1; PanelScroll.BorderSizePixel=0
		PanelScroll.ScrollBarThickness=3; PanelScroll.ZIndex=20
		local PanelLayout=Instance.new("UIListLayout",PanelScroll)
		PanelLayout.Padding=UDim.new(0,2); PanelLayout.SortOrder=Enum.SortOrder.LayoutOrder
		PanelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			PanelScroll.CanvasSize=UDim2.new(0,0,0,PanelLayout.AbsoluteContentSize.Y+6)
		end)
		local function rebuildOptions(optList)
			for _,ch in ipairs(PanelScroll:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			local clearBtn=Instance.new("TextButton",PanelScroll)
			clearBtn.Size=UDim2.new(1,0,0,26); clearBtn.BackgroundTransparency=1
			clearBtn.Text="[Default]"; clearBtn.TextColor3=UI.C.TEXT_3
			clearBtn.Font=Enum.Font.GothamMedium; clearBtn.TextSize=11; clearBtn.ZIndex=21
			clearBtn.MouseButton1Click:Connect(function()
				if isMulti then table.clear(selected) else selected="" end
				DropBtn.Text=displayText()
				Panel.Visible=false; UI.activeDropdown=nil
				callback(isMulti and {} or "")
			end)
			for _,opt in ipairs(optList) do
				local isOn=isMulti and selected[opt]==true or selected==opt
				local OBtn=Instance.new("TextButton",PanelScroll)
				OBtn.Size=UDim2.new(1,0,0,26); OBtn.BackgroundColor3=isOn and UI.C.ACCENT_D or UI.C.ELEVATED
				OBtn.BorderSizePixel=0; UIH_Corner(UI,OBtn,4)
				OBtn.Text=opt; OBtn.TextColor3=isOn and UI.C.TEXT_1 or UI.C.TEXT_2
				OBtn.Font=Enum.Font.GothamMedium; OBtn.TextSize=11; OBtn.ZIndex=21
				OBtn.MouseButton1Click:Connect(function()
					if isMulti then
						if opt=="Default" then
							table.clear(selected)
						else
							if selected[opt] then selected[opt]=nil else selected[opt]=true end
						end
						selected.Default=nil
						for _,child in ipairs(PanelScroll:GetChildren()) do
							if child:IsA("TextButton") and child~=clearBtn then
								local on=selected[child.Text]==true
								child.BackgroundColor3=on and UI.C.ACCENT_D or UI.C.ELEVATED
								child.TextColor3=on and UI.C.TEXT_1 or UI.C.TEXT_2
							end
						end
					else
						selected=(opt=="Default") and "" or opt
						Panel.Visible=false; UI.activeDropdown=nil
					end
					DropBtn.Text=displayText()
					local result
					if isMulti then
						result={}; for k in pairs(selected) do if k~="Default" then result[#result+1]=k end end
					else result=selected end
					callback(result)
				end)
			end
		end
		rebuildOptions(options)
		DropBtn.MouseButton1Click:Connect(function()
			if Panel.Visible then
				Panel.Visible=false; UI.activeDropdown=nil; return
			end
			if UI.activeDropdown and UI.activeDropdown~=Panel then UI.activeDropdown.Visible=false end
			local absPos=DropBtn.AbsolutePosition
			local absSize=DropBtn.AbsoluteSize
			Panel.Position=UDim2.fromOffset(absPos.X,absPos.Y+absSize.Y+4)
			Panel.Visible=true; UI.activeDropdown=Panel
		end)
		local function GetSelected() return isMulti and selected or selected end
		local function SetOptions(newOpts)
			rebuildOptions(newOpts)
			Panel.Size=UDim2.new(0,220,0,math.min(#newOpts*28+8+28,180))
		end
		local function SetSelected(val)
			if isMulti and type(val)=="table" then
				table.clear(selected)
				for _,v in ipairs(val) do selected[v]=true end
			elseif not isMulti and type(val)=="string" then
				selected=val
			end
			DropBtn.Text=displayText()
		end
		return Row, GetSelected, SetOptions, SetSelected
	end

UIHelpers={
	Corner=UIH_Corner,
	Stroke=UIH_Stroke,
	MakeDraggable=UIH_MakeDraggable,
	BuatPage=UIH_BuatPage,
	SwitchTab=UIH_SwitchTab,
	BuatNavButton=UIH_BuatNavButton,
	BuatSection=UIH_BuatSection,
	BuatToggle=UIH_BuatToggle,
	BuatButton=UIH_BuatButton,
	BuatSlider=UIH_BuatSlider,
	BuatInput=UIH_BuatInput,
	BuatDropdown=UIH_BuatDropdown,
}




function InitializeUI()
	local C={
		BASE    =Color3.fromRGB(13,  8,  32),
		SURFACE =Color3.fromRGB(22, 14,  46),
		ELEVATED=Color3.fromRGB(33, 22,  66),
		BORDER  =Color3.fromRGB(74, 45, 128),
		DIVIDER =Color3.fromRGB(30, 18,  58),
		TEXT_1  =Color3.fromRGB(237,232,255),
		TEXT_2  =Color3.fromRGB(184,159,232),
		TEXT_3  =Color3.fromRGB(112, 85,168),
		ACCENT  =Color3.fromRGB(0, 170, 255),
		ACCENT_D=Color3.fromRGB(0, 105, 190),
		DANGER  =Color3.fromRGB(196, 94,138),
		SHOP    =Color3.fromRGB(60,180,120),
		BOMB    =Color3.fromRGB(220,120, 40),
	}
	local MainSG=Instance.new("ScreenGui",GuiRoot)
	MainSG.Name="DScriptsPF"; MainSG.ResetOnSpawn=false
	local UI={C=C,MainSG=MainSG}
	local H=UIHelpers
	local Root=Instance.new("Frame",MainSG)
	Root.Size=UDim2.new(0,520,0,400); Root.Position=UDim2.new(0.5,-260,0.5,-200); Root.BackgroundTransparency=1
	local MinimizedIcon=Instance.new("TextButton",Root)
MinimizedIcon.Size=UDim2.new(1,0,1,0)
MinimizedIcon.BackgroundColor3=C.SURFACE
MinimizedIcon.BorderSizePixel=0
MinimizedIcon.Text="▯"
MinimizedIcon.TextColor3=C.ACCENT
MinimizedIcon.Font=Enum.Font.GothamBold
MinimizedIcon.TextSize=32
MinimizedIcon.Visible=false
MinimizedIcon.AutoButtonColor=false
H.Corner(UI,MinimizedIcon,10)
H.Stroke(UI,MinimizedIcon,C.BORDER,1)
H.MakeDraggable(UI,Root,MinimizedIcon)
	local Win=Instance.new("Frame",Root)
	Win.Size=UDim2.new(1,0,1,0); Win.BackgroundColor3=C.BASE; Win.ClipsDescendants=true; H.Corner(UI,Win,8); H.Stroke(UI,Win,C.BORDER,1)
	local Header=Instance.new("Frame",Win)
	Header.Size=UDim2.new(1,0,0,45); Header.BackgroundColor3=C.SURFACE; H.Corner(UI,Header,8)
	local HFix=Instance.new("Frame",Header)
	HFix.Size=UDim2.new(1,0,0,8); HFix.Position=UDim2.new(0,0,1,-8); HFix.BackgroundColor3=C.SURFACE; HFix.BorderSizePixel=0
	local AccentLine=Instance.new("Frame",Header)
	AccentLine.Size=UDim2.new(0,40,0,3); AccentLine.Position=UDim2.new(0,16,0,0)
	AccentLine.BackgroundColor3=C.ACCENT; AccentLine.BorderSizePixel=0; H.Corner(UI,AccentLine,2)
	local HeaderIcon=Instance.new("ImageLabel",Header)
	HeaderIcon.Size=UDim2.new(0,30,0,30); HeaderIcon.Position=UDim2.new(0,8,0.5,-15)
	HeaderIcon.BackgroundTransparency=1; HeaderIcon.Image="rbxassetid://90635907660208"
	H.Corner(UI,HeaderIcon,8)
	local TitleLbl=Instance.new("TextLabel",Header)
	TitleLbl.Size=UDim2.new(1,-132,1,0); TitleLbl.Position=UDim2.new(0,46,0,0)
	TitleLbl.BackgroundTransparency=1; TitleLbl.RichText=true
	TitleLbl.Text="NXROT: <font color='#EB3C3C'>MINE A MOUNTAIN</font> <font color='#888'>NXROT</font>"
	TitleLbl.TextColor3=C.TEXT_1; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=14; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
	H.MakeDraggable(UI,Root,Header)
	local originalSize=Root.Size; local minimizedSize=UDim2.new(0,52,0,52)
	local MinBtn=Instance.new("TextButton",Header)
	MinBtn.Size=UDim2.new(0,24,0,24); MinBtn.Position=UDim2.new(1,-34,0.5,-12)
	MinBtn.BackgroundColor3=C.SURFACE; MinBtn.BorderSizePixel=0; MinBtn.Text="—"
	MinBtn.TextColor3=C.TEXT_2; MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=14
	MinBtn.AutoButtonColor=false; H.Corner(UI,MinBtn,4)
	MinBtn.MouseButton1Click:Connect(function()
		Win.Visible=false; MinimizedIcon.Visible=true
		S.TweenService:Create(Root,TweenInfo.new(0.2),{Size=minimizedSize}):Play()
	end)
	MinimizedIcon.MouseButton1Click:Connect(function()
		Win.Visible=true; MinimizedIcon.Visible=false
		S.TweenService:Create(Root,TweenInfo.new(0.2),{Size=originalSize}):Play()
	end)
	local Body=Instance.new("Frame",Win)
	Body.Size=UDim2.new(1,0,1,-45); Body.Position=UDim2.new(0,0,0,45); Body.BackgroundTransparency=1
	local Sidebar=Instance.new("Frame",Body)
	Sidebar.Size=UDim2.new(0,80,1,0); Sidebar.BackgroundColor3=C.SURFACE; Sidebar.BorderSizePixel=0
	local SidebarStroke=Instance.new("Frame",Sidebar)
	SidebarStroke.Size=UDim2.new(0,1,1,0); SidebarStroke.Position=UDim2.new(1,0,0,0)
	SidebarStroke.BackgroundColor3=C.DIVIDER; SidebarStroke.BorderSizePixel=0
	local TabContainer=Instance.new("ScrollingFrame",Sidebar)
	TabContainer.Size=UDim2.new(1,0,1,-65); TabContainer.BackgroundTransparency=1
	TabContainer.BorderSizePixel=0; TabContainer.ScrollBarThickness=2
	local TabLayout=Instance.new("UIListLayout",TabContainer)
	TabLayout.Padding=UDim.new(0,5); TabLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
	Instance.new("UIPadding",TabContainer).PaddingTop=UDim.new(0,10)
	TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabContainer.CanvasSize=UDim2.new(0,0,0,TabLayout.AbsoluteContentSize.Y+20)
	end)
	local ProfileContainer=Instance.new("Frame",Sidebar)
	ProfileContainer.Size=UDim2.new(1,0,0,65); ProfileContainer.Position=UDim2.new(0,0,1,-65)
	ProfileContainer.BackgroundColor3=C.BASE; ProfileContainer.BorderSizePixel=0
	local AvatarImg=Instance.new("ImageLabel",ProfileContainer)
	AvatarImg.Size=UDim2.new(0,36,0,36); AvatarImg.Position=UDim2.new(0,12,0.5,-18)
	AvatarImg.BackgroundColor3=C.SURFACE; AvatarImg.BorderSizePixel=0; H.Corner(UI,AvatarImg,18)
	task.spawn(function()
		pcall(function()
			AvatarImg.Image=S.Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
		end)
	end)
	local NameLbl=Instance.new("TextLabel",ProfileContainer)
	NameLbl.Size=UDim2.new(1,-60,0,16); NameLbl.Position=UDim2.new(0,56,0.5,-16)
	NameLbl.BackgroundTransparency=1; NameLbl.Text=LocalPlayer.DisplayName
	NameLbl.TextColor3=C.TEXT_1; NameLbl.Font=Enum.Font.GothamBold; NameLbl.TextSize=11; NameLbl.TextXAlignment=Enum.TextXAlignment.Left
	local StatusLbl=Instance.new("TextLabel",ProfileContainer)
	StatusLbl.Size=UDim2.new(1,-60,0,14); StatusLbl.Position=UDim2.new(0,56,0.5,2)
	StatusLbl.BackgroundTransparency=1; StatusLbl.Text=DEV_MODE and "DEV MODE" or "Licensed"
	StatusLbl.TextColor3=C.ACCENT; StatusLbl.Font=Enum.Font.GothamMedium; StatusLbl.TextSize=10; StatusLbl.TextXAlignment=Enum.TextXAlignment.Left
	local ContentArea=Instance.new("Frame",Body)
	ContentArea.Size=UDim2.new(1,-155,1,0); ContentArea.Position=UDim2.new(0,155,0,0); ContentArea.BackgroundTransparency=1
	local Pages,NavButtons={},{}
	UI.ContentArea=ContentArea; UI.TabContainer=TabContainer
	UI.Pages=Pages; UI.NavButtons=NavButtons
	UI.BuatPage=H.BuatPage; UI.BuatNavButton=H.BuatNavButton
	UI.BuatSection=H.BuatSection
	UI.BuatToggle=H.BuatToggle; UI.BuatButton=H.BuatButton
	UI.BuatSlider=H.BuatSlider; UI.BuatInput=H.BuatInput
	UI.BuatDropdown=H.BuatDropdown
	UI.activeDropdown=nil
	S.UserInputService.InputBegan:Connect(function(input)
		if not UI.activeDropdown or not UI.activeDropdown.Visible then return end
		if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		local p=input.Position
		local pos=UI.activeDropdown.AbsolutePosition; local size=UI.activeDropdown.AbsoluteSize
		if p.X>=pos.X and p.X<=pos.X+size.X and p.Y>=pos.Y and p.Y<=pos.Y+size.Y then return end
		UI.activeDropdown.Visible=false; UI.activeDropdown=nil
	end)

	-- ============================================================
	-- TABS
	-- ============================================================
local PageNames={"Dupe"}
	for _,name in ipairs(PageNames) do H.BuatNavButton(UI,name); H.BuatPage(UI,name) end

	BuildTabsUI(UI)

	-- Initialization
	H.SwitchTab(UI,"Dupe")
	Win.Visible=true
end



function BuildDupeTab(UI, P_DUP)
    local CONFIG_FILE = "DHuh_DupeConfig.json"
    local savedConfig = {}
    
    if writefile and readfile and isfile and isfile(CONFIG_FILE) then
        pcall(function()
            savedConfig = game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
        end)
    end

    local function saveMyConfig(data)
        if writefile then
            pcall(function()
                writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data))
            end)
        end
    end

    -- ── STATE ────────────────────────────────────────────────
    local selectedCrystals  = savedConfig.selectedCrystals  or {}
    local selectedRunes     = savedConfig.selectedRunes     or {}
    local selectedRarities  = savedConfig.selectedRarities  or {}
    local crystalOptions    = {}
    local runeOptions       = {}

    local isAutoDropOnKick  = savedConfig.isAutoDropOnKick  or false
    local isAutoCollect     = savedConfig.isAutoCollect     or false
    local isAutoRejoin      = savedConfig.isAutoRejoin      or false

    local rejoinDelay       = savedConfig.rejoinDelay       or 5
    local rejoinMethod      = savedConfig.rejoinMethod      or "Current Server"
    local privateServerLink = savedConfig.privateServerLink or ""
    local collectRadius     = savedConfig.collectRadius     or 100

    local function updateConfig()
        saveMyConfig({
            selectedCrystals  = selectedCrystals,
            selectedRunes     = selectedRunes,
            selectedRarities  = selectedRarities,
            isAutoDropOnKick  = isAutoDropOnKick,
            isAutoCollect     = isAutoCollect,
            isAutoRejoin      = isAutoRejoin,
            rejoinDelay       = rejoinDelay,
            rejoinMethod      = rejoinMethod,
            privateServerLink = privateServerLink,
            collectRadius     = collectRadius,
        })
    end

    -- ── HELPERS ──────────────────────────────────────────────
    local rarityList = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Empyrean","Pulsar","Quasar"}

    local function getCrystalRarity(child)
        local tierName = child:GetAttribute("TierName")
        if type(tierName) == "string" and tierName ~= "" then return tierName end
        local tier = tonumber(child:GetAttribute("Tier")) or 0
        return rarityList[tier] or "Unknown"
    end

    local function rarityAllowed(child)
        if #selectedRarities == 0 then return true end
        local r = getCrystalRarity(child)
        for _, sel in ipairs(selectedRarities) do
            if sel == r then return true end
        end
        return false
    end

    local function isCrystalTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("CrystalName") ~= nil
            or child:GetAttribute("Tier") ~= nil
            or child.Name:find("Crystal") ~= nil
    end

    local function isRuneTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("RuneId") ~= nil
            or child:GetAttribute("RuneName") ~= nil
            or child:GetAttribute("IsRune") == true
            or child.Name:find(" Rune", 1, true) ~= nil
    end

-- ── SCAN INVENTORY ───────────────────────────────────────
local function scanInventory()
    table.clear(crystalOptions)
    table.clear(runeOptions)

    local crystalMap, runeMap = {}, {}

    local function checkItem(child)
        if isRuneTool(child) then
            if not runeMap[child.Name] then
                runeMap[child.Name] = true
                table.insert(runeOptions, child.Name)
            end

        elseif isCrystalTool(child) then

            -- ambil data tambahan kristal
            local weight = ""
            local price = ""
            local luck = ""

            for _,v in ipairs(child:GetDescendants()) do
                if v:IsA("TextLabel") then
                    local txt = v.Text

                    if string.find(txt, "TON") or string.find(txt, "KG") then
                        weight = txt
                    elseif string.find(txt, "%$") then
                        price = txt
                    elseif string.find(txt, "%%") then
                        luck = txt
                    end
                end
            end

            local key = child.Name.."|"..weight.."|"..price.."|"..luck

            if crystalMap[key] then
                crystalMap[key].count += 1
            else
                crystalMap[key] = {
                    name = child.Name,
                    weight = weight,
                    price = price,
                    luck = luck,
                    count = 1
                }
            end
        end
    end

    local bp = game.Players.LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, c in ipairs(bp:GetChildren()) do
            checkItem(c)
        end
    end

    local char = game.Players.LocalPlayer.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            checkItem(c)
        end
    end


    -- buat dropdown crystal
    for _,v in pairs(crystalMap) do
        local text = v.name.." x"..v.count

        if v.weight ~= "" then
            text = text.." | "..v.weight
        end

        if v.price ~= "" then
            text = text.." | "..v.price
        end

        if v.luck ~= "" then
            text = text.." | "..v.luck
        end

        table.insert(crystalOptions, text)
    end


    table.sort(crystalOptions)
    table.sort(runeOptions)
end

scanInventory()

    -- ── CORE LOGIC: DROP ─────────────────────────────────────
    local dropRemoteCache = nil
    local function getDropRemote()
        if dropRemoteCache and dropRemoteCache.Parent then return dropRemoteCache end
        local r = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        dropRemoteCache = r and r:FindFirstChild("CrystalDropRequest")
        return dropRemoteCache
    end

    local function executeDropItems(crystalList, runeList)
        local remote = getDropRemote()
        if not remote then return end

        local targetCrystals = {}
        local targetRunes = {}
        for _, name in ipairs(crystalList or selectedCrystals) do targetCrystals[name] = true end
        for _, name in ipairs(runeList   or selectedRunes)   do targetRunes[name]   = true end

        local function dropFrom(container)
            if not container then return end
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then
                    if targetCrystals[child.Name] or targetRunes[child.Name] then
                        pcall(function() remote:FireServer(child.Name) end)
                    end
                end
            end
        end

        dropFrom(game.Players.LocalPlayer:FindFirstChildOfClass("Backpack"))
        dropFrom(game.Players.LocalPlayer.Character)
    end

    -- ── CORE LOGIC: COLLECT ──────────────────────────────────
    local holdRemote = nil
    local function getHoldRemote()
        if holdRemote and holdRemote.Parent then return holdRemote end
        local r = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        holdRemote = r and r:FindFirstChild("CrystalHoldComplete")
        return holdRemote
    end

    local function fireCrystalPickup(part)
        local hold = getHoldRemote()
        if hold then
            pcall(function() hold:FireServer(part) end)
        end

        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                prompt.Enabled = true
                prompt.MaxActivationDistance = 9999
            end)
            if typeof(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(prompt, 1) end)
                pcall(function() fireproximityprompt(prompt, 0) end)
            end
            pcall(function() prompt:InputHoldBegin(); prompt:InputHoldEnd() end)
        end

        local det = part:FindFirstChildWhichIsA("ClickDetector", true)
        if det and typeof(fireclickdetector) == "function" then
            pcall(function() fireclickdetector(det, 0) end)
        end
    end

    local function collectLoop()
        while task.wait(0.25) do
            if not isAutoCollect then continue end

            local char = game.Players.LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local WS = game:GetService("Workspace")

            local containers = {WS}
            local dropped = WS:FindFirstChild("DroppedCrystals") or WS:FindFirstChild("Crystals")
            if dropped then table.insert(containers, dropped) end
            local things = WS:FindFirstChild("Things")
            if things then
                local dc = things:FindFirstChild("DroppedCrystals") or things:FindFirstChild("Crystals")
                if dc then table.insert(containers, dc) end
            end

            for _, container in ipairs(containers) do
                for _, child in ipairs(container:GetChildren()) do
                    if not isAutoCollect then break end
                    if not child:IsA("BasePart") then continue end

                    local isValidCrystal = child:GetAttribute("Value") ~= nil
                        and (child:GetAttribute("CrystalName") ~= nil or child:GetAttribute("Tier") ~= nil)

                    if not isValidCrystal then continue end
                    if child:GetAttribute("Collected") == true then continue end
                    if not rarityAllowed(child) then continue end

                    -- cek radius sebelum teleport
                    local dist = (child.Position - root.Position).Magnitude
                    if dist > collectRadius then continue end

                    local pos = child.Position
                    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    task.wait(0.05)

                    fireCrystalPickup(child)

                    task.wait(0.1)
                end
            end
        end
    end

    task.spawn(collectLoop)

    -- ── UI: SELECTION ────────────────────────────────────────
    local crystalRow, crystalGet, crystalSetOpts, crystalSetSel
    local runeRow,    runeGet,    runeSetOpts,    runeSetSel
    local methodRow,  methodGet,  methodSetOpts,  methodSetSel

    UI.BuatSection(UI, P_DUP, "Drop Selection")

    crystalRow, crystalGet, crystalSetOpts, crystalSetSel =
        UI.BuatDropdown(UI, P_DUP, "Crystals to Drop", crystalOptions, true, selectedCrystals, function(selected)
            selectedCrystals = selected
            updateConfig()
        end)

    runeRow, runeGet, runeSetOpts, runeSetSel =
        UI.BuatDropdown(UI, P_DUP, "Runes to Drop", runeOptions, true, selectedRunes, function(selected)
            selectedRunes = selected
            updateConfig()
        end)

    local RefreshBtn = UI.BuatButton(UI, P_DUP, "↻ Refresh Inventory", "Scan ulang inventory")
    RefreshBtn.MouseButton1Click:Connect(function()
        scanInventory()
        crystalSetOpts(crystalOptions)
        runeSetOpts(runeOptions)
        if Notify then Notify("Inventory di-refresh", 2) end
    end)

    -- ── UI: COLLECT ──────────────────────────────────────────
    -- Auto Collect Rune: standalone Dupe dependency; no Vein/Boulder/Farming engine.
    UI.BuatSection(UI, P_DUP, "Auto Collect Rune")
    local autoRunePickup = false
    local runeBusy = false
    local function isRuneObject(inst)
        if not inst then return false end
        if inst:GetAttribute("RuneId") ~= nil or inst:GetAttribute("RuneName") ~= nil or inst:GetAttribute("IsRune") == true then return true end
        return inst.Name:find(" Rune", 1, true) ~= nil
    end
    local function runePart(inst)
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) end
        return nil
    end
    local function findRunePrompt(inst, part)
        local p = inst:FindFirstChildOfClass("ProximityPrompt")
        if not p then p = inst:FindFirstChildWhichIsA("ProximityPrompt", true) end
        if not p and part and part ~= inst then p = part:FindFirstChildWhichIsA("ProximityPrompt", true) end
        return p
    end
    local function collectRunePrompt(prompt)
        if not prompt or not prompt.Parent then return false end
        local old={hold=prompt.HoldDuration,sight=prompt.RequiresLineOfSight,enabled=prompt.Enabled,range=prompt.MaxActivationDistance}
        pcall(function() prompt.HoldDuration=0; prompt.RequiresLineOfSight=false; prompt.Enabled=true; prompt.MaxActivationDistance=1000 end)
        local ok=false
        if typeof(fireproximityprompt)=="function" then ok=pcall(fireproximityprompt,prompt) end
        if not ok then ok=pcall(function() prompt:InputHoldBegin(); prompt:InputHoldEnd() end) end
        task.delay(0.25,function() if prompt and prompt.Parent then pcall(function() prompt.HoldDuration=old.hold; prompt.RequiresLineOfSight=old.sight; prompt.Enabled=old.enabled; prompt.MaxActivationDistance=old.range end) end end)
        return ok
    end
    local function collectNearbyRunes(radius)
        local char=game.Players.LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local seen={}
        local folder=workspace:FindFirstChild("DroppedRunes")
        local candidates=folder and folder:GetChildren() or {}
        for _,part in ipairs(workspace:GetPartBoundsInRadius(root.Position,radius)) do candidates[#candidates+1]=part end
        local count=0
        for _,obj in ipairs(candidates) do
            local owner=obj
            if not isRuneObject(owner) and owner.Parent and isRuneObject(owner.Parent) then owner=owner.Parent end
            if not seen[owner] then
                local part=runePart(owner) or (obj:IsA("BasePart") and obj)
                if part and (part.Position-root.Position).Magnitude<=radius then
                    local prompt=findRunePrompt(owner,part)
                    if prompt and collectRunePrompt(prompt) then count=count+1 end
                end
                seen[owner]=true
            end
        end
        return count
    end
    local RuneBtn,RuneSet=UI.BuatToggle(UI,P_DUP,"Pickup Runes","Automatically collect nearby runes",false)
    RuneBtn.MouseButton1Click:Connect(function()
        autoRunePickup=not autoRunePickup
        RuneSet(autoRunePickup)
    end)
    task.spawn(function()
        while task.wait(0.15) do
            if autoRunePickup and not runeBusy then
                runeBusy=true
                pcall(collectNearbyRunes,90)
                runeBusy=false
            end
        end
    end)

    UI.BuatSection(UI, P_DUP, "Auto Collect (Map Scanner)")

    local _,_,_,raritySetSel = UI.BuatDropdown(UI, P_DUP, "Rarity to Collect", rarityList, true, selectedRarities, function(selected)
        selectedRarities = selected
        updateConfig()
    end)

    UI.BuatSlider(UI, P_DUP, "Collect Radius", 10, 5000, collectRadius, function(v)
        collectRadius = math.floor(v)
        updateConfig()
    end)

    local CollectToggleBtn, CollectToggleSet =
        UI.BuatToggle(UI, P_DUP, "Auto Collect Selected", "Auto ambil crystal sesuai rarity dari seluruh map", isAutoCollect)
    CollectToggleBtn.MouseButton1Click:Connect(function()
        isAutoCollect = not isAutoCollect
        CollectToggleSet(isAutoCollect)
        updateConfig()
    end)

    -- ── UI: DROP AUTOMATION ──────────────────────────────────
    UI.BuatSection(UI, P_DUP, "Auto Drop")

    local DropToggleBtn, DropToggleSet =
        UI.BuatToggle(UI, P_DUP, "Auto Drop On Kick", "Drop otomatis saat akun dilogin di tempat lain", isAutoDropOnKick)
    DropToggleBtn.MouseButton1Click:Connect(function()
        isAutoDropOnKick = not isAutoDropOnKick
        DropToggleSet(isAutoDropOnKick)
        updateConfig()
    end)

    -- ── UI: REJOIN SETTINGS ──────────────────────────────────
    UI.BuatSection(UI, P_DUP, "Rejoin Settings")

    UI.BuatInput(UI, P_DUP, "Rejoin Delay [s]", "Contoh: 5", tostring(rejoinDelay), function(val)
        local num = tonumber(val)
        if num then
            rejoinDelay = num
            updateConfig()
            if Notify then Notify("Delay: " .. val .. "s", 2) end
        end
    end)

    methodRow, methodGet, methodSetOpts, methodSetSel =
        UI.BuatDropdown(UI, P_DUP, "Rejoin Method", {"Current Server","Private Server Link","Random Server"},
        false, rejoinMethod, function(selected)
            rejoinMethod = selected
            updateConfig()
        end)

    UI.BuatInput(UI, P_DUP, "Link / JobId Private Server", "Paste link VIP atau JobId", privateServerLink, function(val)
        privateServerLink = val
        updateConfig()
        if Notify then Notify("Server target di-update", 2) end
    end)

    local RejoinToggleBtn, RejoinToggleSet =
        UI.BuatToggle(UI, P_DUP, "Auto Rejoin", "Rejoin otomatis setelah kick", isAutoRejoin)
    RejoinToggleBtn.MouseButton1Click:Connect(function()
        isAutoRejoin = not isAutoRejoin
        RejoinToggleSet(isAutoRejoin)
        updateConfig()
    end)

        -- ── LOGIC: AUTO DROP ON KICK ─────────────────────────────
    local connectionTriggered = false
    local coreGui = game:GetService("CoreGui")

    -- fungsi handleRejoin dikembalikan jadi fungsi terpisah
    -- sama persis seperti versi lama
    local function handleRejoin()
        if not isAutoRejoin then return end
        task.spawn(function()
            task.wait(rejoinDelay)
            local TS = game:GetService("TeleportService")
            local placeId = game.PlaceId
            while task.wait(3) do
                if rejoinMethod == "Current Server" then
                    pcall(function() TS:TeleportToPlaceInstance(placeId, game.JobId, game.Players.LocalPlayer) end)
                elseif rejoinMethod == "Random Server" then
                    if Net and type(Net.hop) == "function" then Net.hop()
                    else pcall(function() TS:Teleport(placeId, game.Players.LocalPlayer) end) end
                elseif rejoinMethod == "Private Server Link" then
                    if privateServerLink ~= "" then
                        local code = privateServerLink:match("privateServerLinkCode=([^&]+)")
                        if code then
                            pcall(function() TS:Teleport(placeId, game.Players.LocalPlayer) end)
                        else
                            pcall(function() TS:TeleportToPlaceInstance(placeId, privateServerLink, game.Players.LocalPlayer) end)
                        end
                    end
                end
            end
        end)
    end

    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        local msg = game:GetService("GuiService"):GetErrorMessage():lower()
        if (msg:find("same account") or msg:find("device") or msg:find("launched") or msg:find("another device"))
            and not connectionTriggered then
            connectionTriggered = true
            if isAutoDropOnKick then executeDropItems() end
            handleRejoin()  -- fix: tambah handleRejoin disini
        end
    end)

    task.spawn(function()
        while task.wait(0.05) do
            if not connectionTriggered then
                pcall(function()
                    local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
                    if promptGui then
                        local overlay = promptGui:FindFirstChild("promptOverlay")
                        if overlay then
                            for _, child in ipairs(overlay:GetChildren()) do
                                if child.Name:find("ErrorPrompt") then
                                    connectionTriggered = true
                                    if isAutoDropOnKick then executeDropItems() end
                                    handleRejoin()  -- fix: tambah handleRejoin disini juga
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ── UI: MISC ─────────────────────────────────────────────
    UI.BuatSection(UI, P_DUP, "Misc")

    local ManualDropBtn = UI.BuatButton(UI, P_DUP, "🗑 Manual Drop Selected", "Drop sekarang juga")
    ManualDropBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            executeDropItems()
            if Notify then Notify("Manual drop selesai", 2) end
        end)
    end)

    local ResetBtn = UI.BuatButton(UI, P_DUP, "⟳ Reset Character", "Kill & respawn")
    ResetBtn.MouseButton1Click:Connect(function()
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Health = 0 end) end
    end)
end
	
function BuildTabsUI(UI)
	BuildDupeTab(UI,UI.Pages.Dupe)
end

InitializeUI()

