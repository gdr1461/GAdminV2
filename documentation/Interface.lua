--[=[
	@class Interface
	@client
	@tag UI
	Main logic controller for GAdmin UI.
	
	Location: `GAdminV2.MainModule.Client.Services.Framework.Interface`
]=]

--[=[
	@interface Interface
	@field __type string
	@field UI ScreenGui
	@field __Hovered CurrentlyHovered
	@field __Tweens InterfaceTweens
	@field PlaceData table
	@field Popup Popup
	@field Listeners table
	@field Hovers table
	@field Location Location
	@field ScreenSize Vector2
	@field Icon TopBarPlus
	@field Load () -> ()
	@field Open (On: string?, FromIcon: boolean?, NoSound: boolean?) -> ()
	@field Close (FromIcon: boolean?) -> ()
	@field SetGuiCoreEnabled (Name: string, State: boolean) -> ()
	@field OnLocationChange (Function: (Location: Location) -> ()) -> ()
	@field TriggerDataMethod (Place: string, Method: string, ...: any) -> unknown
	@field GetData (Place: string?) -> table
	@field GetFixedPosition (Frame: GuiObject, Position: UDim2) -> UDim2
	@field LoadHovering () -> ()
	@field SetHover (Object: GuiObject, RawInfo: string | () -> string) -> ()
	@field SetHoverConfig (Object: GuiObject, Follow: (Object: GuiObject) -> UDim2) -> ()
	@field ConfigBlock (Button: GuiObject, CategoryName: string, Key: string) -> ()
	@field Block (Button: GuiObject, RankLike: RankLike) -> ()
	@field UnBlock (Button: GuiObject) -> ()
	@field Check () -> ()
	@field SetLocation (Location: string, Page: number?, OpenOnClosed: boolean?) -> ()
	@field Refresh (Data: ArgumentiveLocation?) -> ()
	@field Reload (Data: ArgumentiveLocation?) -> ()
	@field GetLocation () -> string
	@field GetPage () -> number
	@field SetPage (Page: number) -> ()
	@within Interface
]=]

--[=[
	@interface CurrentlyHovered
	@field Object GuiObject -- The object that is currently hovered.
	@field Content string -- The content of the hovered object.
	@field IsHovered boolean -- Whether the object is hovered or not.
	@within Interface
]=]

--[=[
	@interface InterfaceTweens
	@field Open Tween -- Tween for opening the interface.
	@field Close Tween -- Tween for closing the interface.
	@within Interface
]=]

--[=[
	@interface Location
	@field Place string -- The current place.
	@field Data table -- The data of the current place.
	@field Frame GuiObject -- The frame of the current place.
	@field Back table | (Location: Location) -> () -- The back function.
	@field Previous table -- The previous location.
	@field Page number -- The current page.
	@field MaxPages number -- The maximum pages.
	@within Interface
]=]

--[=[
	@interface ArgumentiveLocation
	@field Place string? -- The place to show.
	@field Page number? -- The page to show.
	@field MaxPages number? -- The maximum pages to show.
	@field Arguments any? -- The arguments to pass.
	@within Interface
]=]

--[=[
	@type TriggerData any | "ENUM.DEFAULT_ARGS" | "ENUM.PAGE_ARGS"
	@within Interface
]=]

--== << Services >>
local StarterGui = game:GetService("StarterGui")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Main = script:FindFirstAncestor("GAdminShared")
local UI = require(Main.Client.Services.UI)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local TopBarPlus = require(Main.Client.Services.TopBarPlus)
local Remote = require(Main.Shared.Services.Remote)

local Sound = require(Main.Shared.Services.Sound)
local Settings = require(Main.Settings.Main)

local CmdBar = require(Main.Client.Services.Framework.CmdBar)
local Executor = require(Main.Client.Services.Framework.Executor)
local Configuration = require(Main.Settings.Interface)

local Rank = require(Main.Shared.Services.Rank)
local Cache = require(script.Parent.Cache)

local Restrictions = require(Main.Settings.Restrictions)
local RCmdBar = Rank:Find(Restrictions.CmdBarAccess)

local FancyHover = require(Main.Client.Services.Framework.FancyHover)
local Builder = require(Main.Client.Services.UI.Builder)

local Tween = TweenInfo.new(Configuration.OpenAnimation.Configuration.Time, Configuration.OpenAnimation.Configuration.Style, Configuration.OpenAnimation.Configuration.Direction)
--==

local Proxy = newproxy(true)
local Interface = getmetatable(Proxy)

Interface.__type = "GAdmin Interface"
Interface.__metatable = "[GAdmin Interface]: Metatable methods are restricted."

--[=[
	ScreenGui of admin panel.

	@prop UI ScreenGui
	@within Interface
]=]
Interface.UI = UI.Gui

--[=[
	Currently hovered object in the panel.

	@private
	@prop __Hovered CurrentlyHovered
	@within Interface
]=]
Interface.__Hovered = {
	Object = nil,
	Content = nil,
	IsHovered = false,
}

--[=[
	Tweens cache.

	@private
	@prop __Tweens InterfaceTweens
	@within Interface
]=]
Interface.__Tweens = {
	Open = TweenService:Create(Interface.UI.MainFrame.Ratio, Tween, {AspectRatio = 2}),
	Close = TweenService:Create(Interface.UI.MainFrame.Ratio, Tween, {AspectRatio = 10})
}

--[=[
	Data of all loaded places.

	@prop PlaceData table
	@within Interface
]=]
Interface.PlaceData = {}

--[=[
	@prop Popup Popup
	@within Interface
]=]
Interface.Popup = require(Main.Shared.Services.Popup)

--[=[
	OnLocationChange listeners.
	
	@private
	@prop Listeners table
	@within Interface
]=]
Interface.Listeners = {}

--[=[
	Loaded hover data of objects.

	@private
	@prop Hovers table
	@within Interface
]=]
Interface.Hovers = {}

--[=[
	Current location of the interface that the user is on.

	@readonly
	@prop Location Location
	@within Interface
]=]
Interface.Location = {
	Place = "Main",
	Data = nil,
	Frame = nil,
	
	Back = nil,
	Previous = nil,
	
	Page = 1,
	MaxPages = 1,
}

Builder:Load(Interface)
for i, Module in ipairs(Main.Client.Places:GetChildren()) do
	if not Module:IsA("ModuleScript") then
		continue
	end

	Builder:LoadPlace(Module)
end

function Interface:__tostring()
	return self.__type
end

function Interface:__index(Key)
	return Interface[Key]
end

function Interface:__newindex(Key, Value)
	Interface[Key] = Value
end

--[=[
	Loads the interface.
	
	@private
	@within Interface
	@return nil
]=]
function Interface:Load()
	local IsStudio = RunService:IsStudio()
	self:SetLocation("Main")
	local Default = Remote:Fire("GetDefault")
	
	Cache.AssetId = Default.AssetId
	Cache.CreatorId = Default.CreatorId
	
	Cache.DonationIds = Default.Donations
	Cache.Addons = Default.Addons
	
	Cache.Version = Default.Version
	Cache.VersionLog = Default.VersionLog
	
	Cache.MainExecutor = Executor.new()
	Cache.Icon = Default.Icon
	
	Remote:Connect("Interface", function(Method, ...)
		self[Method](self, ...)
	end)
	
	self:LoadHovering()
	if Settings.Sandbox and (IsStudio or Settings.__GAdmin_TestingPlace_Sandbox_Everywhere) and not _G.GAdmin.Modified then
		local SandboxRank = Rank:Find(Settings.SandboxRank)
		self.UI.MainFrame.Bottom.Title.Text = `GAdmin <font color="#ff6f0f">SANDBOX</font>`
		self:SetHover(self.UI.MainFrame.Bottom.Title, `Every player in the studio has a '<font color="#ffbfaa">{SandboxRank.Name}</font>' rank.`)
	end

	local Split = Cache.Version:split("-")
	local Version = #Split > 1 and Split[2] or Split[1]
	
	local Prefix = #Split > 1 and Split[1] or nil
	local PrefixData = Prefix and Cache.Prefixes[Prefix] or {}

	Cache.Version = {
		Full = Cache.Version,
		Prefix = Prefix,
		Version = Version,
		PrefixData = PrefixData,
	}
	
	if Prefix and PrefixData.Description then
		self:SetHover(self.UI.MainFrame.Bottom.Version, PrefixData.Description)
	end

	self.UI.MainFrame.Bottom.Version.Text = `{Prefix and `<font color="#{PrefixData.Color}">{Prefix}</font> ` or ""}{Version}`
	self:Check()
	
	if Cache.Session.Rank >= RCmdBar.Rank then
		local Gui = GuiAssets.GACmdBar:Clone()
		Gui.MainFrame.Position = UDim2.fromScale(0, -1)
		Gui.MainFrame.Size = IsStudio and UDim2.fromScale(1, .2) or UDim2.fromScale(1, .1)
		
		Gui.Parent = game.Players.LocalPlayer.PlayerGui
		Cache.CmdBar = CmdBar.new(Gui)
	end
	
	for Name, PlaceData in pairs(self.PlaceData) do
		if not PlaceData.Load or Name == "_TEMPLATE" then
			continue
		end
		
		local Frame = self.UI.MainFrame.Places:FindFirstChild(Name)
		if not Frame then
			warn(`[{self.__type}]: Location '{Name}' has no valid UI frame.`)
			return
		end

		PlaceData:Load(self.UI, Frame, self)
	end
	
	local Clicks = 0
	local Passed = tick()
	local InRender = false
	
	_G.GAdmin.Render(function()
		if tick() - Passed < .5 and not InRender then
			return
		end
		
		Clicks = 0
	end)
	
	local SecretHover = FancyHover.new(self.UI.MainFrame, "Blue")
	SecretHover.Hover.Thickness = 3
	
	local TweenIn = TweenService:Create(SecretHover.Hover, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0})
	local TweenOut = TweenService:Create(SecretHover.Hover, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 1})
	
	self.UI.MainFrame.Bottom.Secret.Activated:Connect(function()
		Passed = tick()
		Clicks += 1
		
		if Clicks == 2 and not InRender then
			InRender = true
			SecretHover.Hover.Transparency = 1
			SecretHover:Enable()
			
			TweenIn:Play()
			TweenIn.Completed:Wait()
			
			task.wait(1)
			TweenOut:Play()
			TweenOut.Completed:Wait()
			
			SecretHover:Disable()
			InRender = false
		end
	end)
	
	self.UI.MainFrame.Top.Close.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.UI.MainFrame.Top.Close.Activated:Connect(function()
		self:Close()
	end)
	
	self.UI.MainFrame.Top.Back.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.UI.MainFrame.Top.Back.Activated:Connect(function()
		if not self.Location.Back then
			return
		end
		
		local Back = self.Location.Back
		if typeof(Back) == "function" then
			Back = Back(self.Location)
		end
		
		Sound:Play("Buttons", "Click1")
		self:SetLocation(Back.Place, Back.Page)
	end)
	
	self.UI.MainFrame.Bottom.Page.Next.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.UI.MainFrame.Bottom.Page.Next.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:SetPage(self.Location.Page + 1)
	end)
	
	self.UI.MainFrame.Bottom.Page.Previous.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.UI.MainFrame.Bottom.Page.Previous.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:SetPage(self.Location.Page - 1)
	end)
	
	self.UI.MainFrame.Bottom.Page.Interact.Activated:Connect(function()
		self.UI.MainFrame.Bottom.Page.Interact.Visible = false
		self.UI.MainFrame.Bottom.Page.Count.Visible = false
		self.UI.MainFrame.Bottom.Page.Input.Visible = true
		self.UI.MainFrame.Bottom.Page.Input:CaptureFocus()
	end)
	
	self.UI.MainFrame.Bottom.Page.Input.FocusLost:Connect(function(EnterPressed)
		self.UI.MainFrame.Bottom.Page.Interact.Visible = true
		self.UI.MainFrame.Bottom.Page.Count.Visible = true
		self.UI.MainFrame.Bottom.Page.Input.Visible = false
		
		local Input = tonumber(self.UI.MainFrame.Bottom.Page.Input.Text, 10)
		if not EnterPressed or not Input then
			return
		end
		
		self:SetPage(Input)
	end)
end

--[=[
	Relocates the interface to the screen center.
	@private
	
	@within Interface
	@return nil
]=]
function Interface:Relocate()
	self.UI.MainFrame.Position = UDim2.fromScale(.5, .5)
end

--[=[
	Opens the interface.
	
	@param On string? -- The location to open the interface on.
	@param FromIcon boolean? -- Whether the interface is opened from the icon.
	@param NoSound boolean? -- Whether to play the sound or not.
	
	@within Interface
	@return nil
]=]
function Interface:Open(On, FromIcon, NoSound)
	if self.UI.MainFrame.Visible then
		return
	end

	if On then
		self:SetLocation(On)
	end

	self.UI.MainFrame.Visible = true
	if Configuration.OpenAnimation.Enabled then
		warn(`[{self.__type}]: OpenAnimation is work in progress.`)
		--self.__Tweens.Close:Pause()
		--self.UI.MainFrame.Ratio.AspectRatio = 10
		--self.__Tweens.Open:Play()
	end

	if not NoSound then
		Sound:Play("Buttons", "Click1")
	end

	if FromIcon or not self.Icon then
		return
	end

	self.Icon:select()
end

--[=[
	Closes the interface.
	
	@param FromIcon boolean? -- Whether the interface is closed from the icon.
	
	@within Interface
	@return nil
]=]
function Interface:Close(FromIcon)
	if not self.UI.MainFrame.Visible then
		return
	end

	Sound:Play("Buttons", "Click1")
	if Configuration.OpenAnimation.Enabled then
		warn(`[{self.__type}]: OpenAnimation is work in progress.`)
		--self.__Tweens.Open:Pause()
		--self.UI.MainFrame.Ratio.AspectRatio = 10
		
		--self.__Tweens.Close:Play()
		--self.__Tweens.Close.Completed:Wait()
	end

	self.UI.MainFrame.Visible = false
	if FromIcon or not self.Icon then
		return
	end
	
	self.Icon:deselect()
end

--[=[
	Sets the state of specified CoreGui.

	@param Name string -- The name of the CoreGui.
	@param State boolean -- The state of the CoreGui.
	@within Interface
	@return nil
]=]
function Interface:SetGuiCoreEnabled(Name, State)
	local EnumInfo = Enum.CoreGuiType:FromName(Name)
	if not EnumInfo then
		warn(`[{self.__type}]: Gui Core with name '{Name}' is invalid.`)
		return
	end
	
	StarterGui:SetCoreGuiEnabled(EnumInfo, State)
end

--[=[
	Sets the listener for when location changes.

	@param Function (Location: Location) -> () -- The function to set.
	@within Interface
	@return nil
]=]
function Interface:OnLocationChange(Function)
	table.insert(self.Listeners, Function)
end

--[=[
	Triggers a method of a UI Place.

	```lua
	Interface:TriggerDataMethod("Main", "RefreshHistory", "ENUM.PAGE_ARGS", 2)
	```

	```lua
	Interface:TriggerDataMethod("Ranks", "RefreshRanks", "ENUM.DEFAULT_ARGS")
	```

	@param Place string -- The place to trigger the method.
	@param Method string -- The method to trigger.
	@param ... TriggerData -- The arguments to pass.
	
	@within Interface
	@return unknown
]=]
function Interface:TriggerDataMethod(Place, Method, ...)
	local Data = self:GetData(Place)
	if not Data then
		warn(`[{self.__type}]: Place '{Place}' is invalid.`)
		return
	end
	
	if not Data[Method] then
		warn(`[{self.__type}]: Method '{Method}' of place '{Place}' is invalid`)
		return
	end
	
	local Arguments = {...}
	if Arguments[1] == "ENUM.DEFAULT_ARGS" then
		Arguments = {self.UI, self.UI.MainFrame.Places:FindFirstChild(Place), self}
	elseif Arguments[1] == "ENUM.PAGE_ARGS" then
		Arguments = {self.UI.MainFrame.Places:FindFirstChild(Place).Pages[Arguments[2]], self}
	end
	
	return Data[Method](Data, unpack(Arguments))
end

--[=[
	Returns data of given place.

	@param Place string? -- The place to get the data from.
	@within Interface
	@return table
]=]
function Interface:GetData(Place)
	Place = Place or self.Location.Place
	return self.PlaceData[Place]
end

--[=[
	Returns position that fits into the screen size.
	@private
	@param Frame GuiObject -- The frame to get the position from.
	@param Position UDim2 -- The position to get the fixed position from.
	@within Interface
	@return UDim2
]=]
function Interface:GetFixedPosition(Frame, Position)
	local OffsetX, OffsetY = self.ScreenSize.X * .005, self.ScreenSize.Y * .01
	local Size = Frame.AbsoluteSize
	
	Position = UDim2.fromOffset(Position.X.Offset + OffsetX, Position.Y.Offset + OffsetY)
	local FramePosition = Vector2.new(Position.X.Offset + Size.X, Position.Y.Offset + Size.Y)
	
	-- Adjust X Offset
	if FramePosition.X > self.ScreenSize.X then
		Position = UDim2.fromOffset(Position.X.Offset - Size.X, Position.Y.Offset)
	end

	-- Adjust Y Offset
	if FramePosition.Y > self.ScreenSize.Y then
		Position = UDim2.fromOffset(Position.X.Offset, Position.Y.Offset - Size.Y)
	end

	local AdjustedPosition = UDim2.fromOffset(math.clamp(Position.X.Offset, 0, self.ScreenSize.X - Size.X), math.clamp(Position.Y.Offset, 0, self.ScreenSize.Y - Size.Y))
	return AdjustedPosition
end

--[=[
	Loads hovering.
	@private
	@within Interface
	@return nil
]=]
function Interface:LoadHovering()
	local LastText
	local LastSize

	_G.GAdmin.Render(function()
		self.ScreenSize = workspace.CurrentCamera.ViewportSize
		local RawPosition = UserInputService:GetMouseLocation()
		local Position = UDim2.fromOffset(RawPosition.X, RawPosition.Y)

		-- On hover.
		self.UI.Hover.Visible = self.__Hovered.IsHovered
		if self.__Hovered.IsHovered then
			self.UI.Hover.Text = self.__Hovered.Content
			local TextBounds = TextService:GetTextSize(self.UI.Hover.Text, self.UI.Hover.TextSize, self.UI.Hover.Font, Vector2.new(self.UI.AbsoluteSize.X / 3.5, self.UI.AbsoluteSize.Y))
			local FrameSize = UDim2.fromOffset(TextBounds.X, TextBounds.Y)

			self.UI.Hover.Size = FrameSize
			self.UI.Hover.TextScaled = not self.UI.Hover.TextFits
			
			local AdjustedPosition = self:GetFixedPosition(self.UI.Hover, Position)
			self.UI.Hover.Position = AdjustedPosition
		end
		
		for Object, Follow in pairs(self.Hovers) do
			if not Object.Visible and not Object:GetAttribute("GA_ForceDrag") then
				continue
			end
			
			local Position = Follow(Object)
			local AdjustedPosition = self:GetFixedPosition(Object, Position)
			Object.Position = AdjustedPosition
		end
	end)
end

--[=[
	Sets the hover for an object.

	```lua
	Interface:SetHover(Button, "Click to open the settings.")
	```
	
	@param Object GuiObject -- The object to set the hover for.
	@param RawInfo string | () -> string -- The content of the hover.
	
	@within Interface
	@return nil
]=]
function Interface:SetHover(Object, RawInfo)
	Object.MouseEnter:Connect(function()
		local Info = RawInfo
		if type(Info) == "function" then
			Info = RawInfo()
		end
		
		self.__Hovered = {
			Object = Object,
			Content = Info,
			IsHovered = true
		}
	end)
	
	Object.MouseLeave:Connect(function()
		if self.__Hovered.Object ~= Object then
			return
		end
		
		self.__Hovered = {
			Object = nil,
			Content = nil,
			IsHovered = false
		}
	end)
end

--[=[
	Sets the hover for an object.

	```lua
	Interface:SetHoverConfig(Button, function(Object)
		return Object.Position
	end)
	```
	
	@param Object GuiObject -- The object to set the hover for.
	@param Follow (Object: GuiObject) -> UDim2 -- The function to get current object's position from.
	
	@within Interface
	@return nil
]=]
function Interface:SetHoverConfig(Object, Follow)
	if self.Hovers[Object] then
		warn(`[{self.__type}]: Object '{Object}' hover config already exist.`)
		return
	end
	
	self.Hovers[Object] = Follow
	Object.Destroying:Once(function()
		self.Hovers[Object] = nil
	end)
end

--[=[
	Sets rank requirment from Restrictions module in the Settings instance to access GuiObject.
	```lua
	Interface:ConfigBlock(Button, "Main", "Settings")
	```

	@param Button GuiObject -- The button to set the rank requirement for.
	@param CategoryName string -- The category name of the rank requirement.
	@param Key string -- The key of the rank requirement.
	@within Interface
	@return nil
]=]
function Interface:ConfigBlock(Button, CategoryName, Key)
	local Category = Restrictions[CategoryName]
	if not Category then
		return
	end
	
	local RankLike = Category[Key]
	if not RankLike then
		return
	end
	
	return self:Block(Button, RankLike)
end

--[=[
	Blocks the button for the rank requirement.

	Same as ConfigBlock, but gives more freedom of a required rank.
	```lua
	Interface:Block(Button, 4)
	Interface:Block(Button, "Manager")
	```

	@param Button GuiObject -- The button to block.
	@param RankLike RankLike -- The minimum rank to access button.
	@within Interface
	@return nil
]=]
function Interface:Block(Button, RankLike)
	local RankData = Rank:Find(RankLike)
	if not RankData then
		warn(`[{self.__type}]: Rank '{RankLike}' is invalid.`)
		return
	end
	
	if Button:FindFirstChild("ITEM_BLOCKED") then
		warn(`[{self.__type}]: UI button '{Button.Name}' is already blocked.`)
		return
	end
	
	Button:SetAttribute("BLOCK_CHECK", true)
	if Cache.Session.Rank >= RankData.Rank then
		return
	end
	
	local Block = GuiAssets.Blocked:Clone()
	Block.Name = "ITEM_BLOCKED"
	Block.Title.Text = `Rank <font color="#ffbfaa">{RankData.Name}+</font> required.`
	Block.Parent = Button
	
	Button.Active = false
	Button.AutoButtonColor = false
	Button.Interactable = false
	
	local Thread = task.defer(function()
		repeat
			local RankData = Rank:Find(RankLike)
			Block.Title.Text = `Rank <font color="#ffbfaa">{RankData.Name}+</font> required.`
			task.wait(Configuration.BlockRefresh)
		until not Button or not Button.Parent
	end)
	
	Button.Destroying:Once(function()
		coroutine.close(Thread)
	end)
end

--[=[
	Removes rank requirements from specified button.
	@param Button GuiObject -- The button to unblock.
	@within Interface
	@return nil
]=]
function Interface:UnBlock(Button)
	if not Button:GetAttribute("BLOCK_CHECK") then
		warn(`[{self.__type}]: UI button '{Button.Name}' is not blocked.`)
		return
	end
	
	local Block = Button:FindFirstChild("ITEM_BLOCKED")
	Button:SetAttribute("BLOCK_CHECK", nil)
	
	if not Block then
		return
	end
	
	Block:Destroy()
	Button.Active = true
	Button.AutoButtonColor = true
	Button.Interactable = true
end

--[=[
	Reloads top bar icon of the interface.
	@private
	@within Interface
	@return nil
]=]
function Interface:Check()
	if Cache.Session.Rank < Restrictions.ButtonAccess and self.Icon then
		self.Icon:destroy()
	end
	
	self.UI.MainFrame.Places.Server.Pages["1"].Executor.Interact.Interactable = Settings.ExecutorEnabled
	self.UI.MainFrame.Places.Server.Pages["1"].Executor.Disabled.Visible = not Settings.ExecutorEnabled
	
	if Cache.Session.Rank >= Restrictions.ButtonAccess and not self.Icon and Cache.Icon then
		self.Icon = TopBarPlus.new()
		self.Icon
			:setName("GAdmin")
			:setOrder(0)
			:setImageScale(.8, "deselected")
			:setImageScale(.7, "selected")
			:setImage(Cache.Icon)
			:align("left")
			:autoDeselect(false)

			:bindEvent("selected", function()
				self:Open(Configuration.MainOnOpen and "Main" or nil, true)
			end)

			:bindEvent("deselected", function()
				self:Close(true)
			end)

		if Configuration.ShowTitle then
			self.Icon:setLabel("GAdmin", "Viewing")
		else
			self.Icon:setCaption("GAdmin")
		end
	end
end

--[=[
	Works the same as `:SetLocation()`, but for Places that have a `:Set()` method.

	```lua
	Interface:Refresh({
		Place = "_Logs",
		Page = 1,
		MaxPages = 1,
		Arguments = {
			Type = "Chat"
		}
	})
	```

	@param Data ArgumentiveLocation? -- The location to show.
	@within Interface
	@return nil
]=]
function Interface:Refresh(Data)
	local Location = Data or self.Location
	local Frame = self.UI.MainFrame.Places:FindFirstChild(Location.Place)
	
	self:Check()
	if not Frame then
		warn(`[{self.__type}]: Location '{Location.Place}' has no valid UI frame.`)
		self.Location.Place = "Main"
		self.Location.Page = 1
		self:Refresh()
		return
	end
	
	for i, Place in ipairs(self.UI.MainFrame.Places:GetChildren()) do
		if not Place:IsA("Frame") then
			continue
		end
		
		Place.Visible = false
	end
	
	local Page = Frame.Pages:FindFirstChild(Location.Page)
	if not Page then
		warn(`[{self.__type}]: Location '{Location.Place}' has no valid UI frame representation of page #{Location.Page}.`)
		return
	end
	
	for i, Page in ipairs(Frame.Pages:GetChildren()) do
		Page.Visible = false
	end
	
	Page.Visible = true
	local PlaceData = self.PlaceData[Location.Place]
	if not PlaceData then
		warn(`[{self.__type}]: Location '{Location.Place}' has no valid module.`)
		self:SetLocation("Main")
		return
	end
	
	self.Location.Place = Location.Place
	self.Location.Data = PlaceData
	self.Location.Frame = Frame
	self.Location.Back = PlaceData.Previous
	
	self.UI.MainFrame.Top.Title.Text = PlaceData.Name
	self.UI.MainFrame.Top.Back.Visible = self.Location.Back ~= nil
	
	self.UI.MainFrame.Bottom.Page.Count.Text = `{Location.Page}/{Location.MaxPages}`
	self.UI.MainFrame.Bottom.Page.Visible = Location.MaxPages > 1
	
	self:Reload(Data)
	Frame.Visible = true
end

--[=[
	Reloads the interface location.
	@private
	@param Data ArgumentiveLocation? -- The data to reload.
	@within Interface
	@return nil
]=]
function Interface:Reload(Data)
	Data = Data or {}
	Data.Arguments = Data.Arguments or {}
	
	Data.Place = Data.Place or self.Location.Place
	Data.Page = Data.Page or self.Location.Page
	Data.MaxPages = Data.MaxPages or self.Location.MaxPages
	
	local PlaceData = self.PlaceData[Data.Place]
	local Frame = self.UI.MainFrame.Places:FindFirstChild(Data.Place)
	
	local Page = Frame.Pages:FindFirstChild(Data.Page)
	if not PlaceData then
		return
	end
	
	for i, Listener in ipairs(self.Listeners) do
		Listener(self.Location)
	end
	
	self.PlaceData[Data.Place].Page = Data.Page
	self.PlaceData[Data.Place].MaxPages = Data.MaxPages
	
	if PlaceData.Set then
		PlaceData:Set(self.UI, Frame, Page, Data.Arguments, self)
		return
	end
	
	if not PlaceData.Reload then
		return
	end
	
	PlaceData:Reload(Page, self)
end

--[=[
	Returns the current Place the user is in.
	@within Interface
	@return string
]=]
function Interface:GetLocation()
	return self.Location.Place
end

--[=[
	Sets the current interface location to specified one.
	@param Location string -- The location to set.
	@param Page number? -- The page to set.
	@param OpenOnClosed boolean? -- Open panel if it is closed.
	@within Interface
	@return nil
]=]
function Interface:SetLocation(Location, Page, OpenOnClosed)
	local Frame = self.UI.MainFrame.Places:FindFirstChild(Location)
	self.Location.Previous = {
		Place = self.Location.Place,
		Page = self.Location.Page
	}
	
	if not Frame then
		warn(`[{self.__type}]: Location '{Location}' has no valid UI frame.`)
		self.Location.Place = "Main"
		self:Refresh()
		
		return
	end
	
	if OpenOnClosed and not self.UI.MainFrame.Visible then
		self:Open(nil, nil, true)
	end

	self.Location.Place = Location
	self.Location.MaxPages = #Frame.Pages:GetChildren()
	self.Location.Page = Page and math.min(Page, self.Location.MaxPages) or 1
	
	self:Refresh()
end

--[=[
	Returns current page of the location.
	@within Interface
	@return number
]=]
function Interface:GetPage()
	return self.Location.Page
end

--[=[
	Sets the page of the location.

	:::note
	The page is limited to the maximum number of pages in the location.
	:::

	@param Page number -- The page to set.
	@within Interface
	@return nil
]=]
function Interface:SetPage(Page)
	self.Location.Page = math.max(math.min(Page, self.Location.MaxPages), 1)
	self:Refresh()
end

return Proxy