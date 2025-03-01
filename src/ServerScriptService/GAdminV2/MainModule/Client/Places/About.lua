--== << Services >>
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Cache = require(Main.Client.Services.Framework.Cache)
local FancyHover = require(Main.Client.Services.Framework.FancyHover)
local Remote = require(Main.Shared.Services.Remote)

local RankService = require(Main.Shared.Services.Rank)
local Restrictions = require(Main.Settings.Restrictions)
local RAddonAccess = RankService:Find(Restrictions.About.AddonAccess)
--==

local Place = {}
Place.Name = "About"
Place.Previous = {
	Place = "Main",
	Page = 1,
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Pages = {
		["1"] = function(UI, Page, Interface)
			UI.MainFrame.Top.Title.Text = "About"
		end,
		
		["2"] = function(UI, Page, Interface)
			UI.MainFrame.Top.Title.Text = "Updates"
		end,
		
		["3"] = function(UI, Page, Interface)
			UI.MainFrame.Top.Title.Text = "Addons"
		end,
	}
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	self:RefreshUpdates(UI, Frame.Pages["2"], Interface)
	self:RefreshAddons(UI, Frame.Pages["3"], Interface)
	
	FancyHover.new(Page.Asset.Interact, "Rainbow"):Apply()
	Page.Asset.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Asset.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		MarketplaceService:PromptPurchase(player, Cache.AssetId)
	end)
	
	local Hover = FancyHover.new(Page.Donation, "Colorful")
	Hover:Apply()
	Hover.Speed = .5

	for i, DonationId in ipairs(Cache.DonationIds) do
		local Success, Product = pcall(function()
			return MarketplaceService:GetProductInfo(DonationId, Enum.InfoType.Product)
		end)

		if not Success then
			warn(`[GAdmin Interface]: About :: {Product}`)
			continue
		end

		local Donation = GuiAssets.Donation:Clone()
		Donation.Name = Product.Name
		Donation.Amount.Text = Product.PriceInRobux

		Donation.LayoutOrder = i
		Donation.Parent = Page.Donation.List

		Donation.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)

		Donation.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			MarketplaceService:PromptPurchase(player, DonationId)
		end)
	end
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Pages[Page.Name](UI, Page, Interface)
end

function Place:RefreshUpdates(UI, Page, Interface)
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	for i, Update in ipairs(Cache.VersionLog.Logs) do
		local Date = DateTime.fromUnixTimestamp(tonumber(Update.Release)):FormatLocalTime("DD/MM/YYYY", "en-us")
		local UpdateFrame = GuiAssets.Update:Clone()
		
		UpdateFrame.Name = Update.Name
		UpdateFrame.Scrollable.Update.Text = `<font size="22" color="#416fb4">{Update.Version}</font> {Update.Name} <font size="17" color="#a9a9a9"> {Date}</font>`
		
		UpdateFrame.LayoutOrder = #Page.List:GetChildren() + 1
		UpdateFrame.Parent = Page.List
		
		for i, Log in ipairs(Update.Changes) do
			local LogFrame = GuiAssets.UpdateLog:Clone()
			LogFrame.Name = `{Update.Name}-{i}`
			LogFrame.Scrollable.Log.Text = Log
			
			LogFrame.LayoutOrder = #Page.List:GetChildren() + 1
			LogFrame.Parent = Page.List
		end
	end
end

function Place:RefreshAddons(UI, Page, Interface)
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end
	
	if RAddonAccess.Rank > Cache.Session.Rank then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Rank <font color="#ffbfaa">{RAddonAccess.Name}+</font> required.`
		return
	end
	
	if not Cache.Addons then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Page hasn't been loaded.`
		return
	end
	
	if #Cache.Addons <= 0 then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `No addons were found.`
		return
	end
	
	Page.Error.Visible = false
	for i, Addon in ipairs(Cache.Addons) do
		local Template = GuiAssets.Addon:Clone()
		Template.Name = `{i}-{Addon.Name}`
		Template.Title.Scrollable.Title.Text = Addon.Name
		Template.Author.Scrollable.Author.Text = Addon.Author
		
		Template.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)
		
		Template.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			Interface:Refresh({
				Place = "_Addon",
				Page = 1,
				MaxPages = 1,
				Arguments = {
					Addon = Addon,
				},
			})
		end)
		
		Template.LayoutOrder = i
		Template.Parent = Page.List
	end
end

return Place