local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficerOrganizeSlot"
local Version = 1

local SLOTBUTTON_HIGHLIGHTTEXTURE = [[INTERFACE\BUTTONS\ButtonHilight-Square]]
local SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]

--[[ Locals ]]
-- Menus
local function GetEasyMenu(widget)
	local slotInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][widget:GetUserData(
			"slotID"
		)]
	local isEmpty = not slotInfo or not slotInfo.itemID

	if isEmpty then
		return {
			{
				text = L["Edit Slot"],
				func = function()
					widget:EditSlot()
				end,
			},
		}
	else
		return {
			{ text = (GetItemInfo(slotInfo.itemID)), isTitle = true, notCheckable = true },
			{
				text = L["Edit Slot"],
				func = function()
					widget:EditSlot()
				end,
			},
			{
				text = L["Duplicate Slot"],
				func = function()
					widget:PickupItem()
				end,
			},
			{
				text = L["Clear Slot"],
				func = function()
					widget:ClearSlot()
				end,
			},
		}
	end
end

--[[ Script handlers ]]
local function frame_onClick(frame, mouseButton)
	local widget = frame.obj
	local slotInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][widget:GetUserData(
			"slotID"
		)]
	local isEmpty = not slotInfo or not slotInfo.itemID

	if mouseButton == "LeftButton" then
		local cursorType, itemID = GetCursorInfo()
		if private.status.organize.editMode == "clear" then
			widget:ClearSlot()
		elseif cursorType == "item" then
			if private.status.organize.originSlot then
				if isEmpty then
					private.status.organize.originSlot:ClearSlot()
				else
					print("Swap")
					private.status.organize.originSlot:UpdateSlotInfo(slotInfo)
				end
			end
			widget:LoadCursorItem(itemID)
		elseif not isEmpty then
			widget:PickupItem()
		end
	elseif mouseButton == "RightButton" then
		if not isEmpty then
			private:CacheItem(slotInfo.itemID)
		end
		EasyMenu(GetEasyMenu(widget), private.organizeContextMenu, widget.frame, 0, 0, "MENU")
	end
end

--[[ Methods ]]
local methods = {
	OnAcquire = function(widget)
		widget.label:SetFont([[Fonts\ARIALN.TTF]], 14, "OUTLINE, MONOCHROME")
		widget.label:SetJustifyH("RIGHT")

		local padding = widget.frame:GetWidth() * 0.1
		widget.label:SetPoint("LEFT", padding, 0)
		widget.label:SetPoint("RIGHT", -padding, 0)
		widget.label:SetPoint("BOTTOM", 0, padding)
	end,

	OnWidthSet = function(widget, width)
		if widget.frame:GetHeight() ~= width then
			widget:SetHeight(width)

			widget.label:SetFont([[Fonts\ARIALN.TTF]], width * 0.35, "OUTLINE, MONOCHROME")

			local padding = width * 0.1
			widget.label:SetPoint("LEFT", padding, 0)
			widget.label:SetPoint("RIGHT", -padding, 0)
			widget.label:SetPoint("BOTTOM", 0, padding)
		end
	end,

	ClearSlot = function(widget)
		local slotID = widget:GetUserData("slotID")
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID] = nil
		private.status.organize.originSlot = nil
		widget:LoadSlot()
	end,

	EditSlot = function(widget)
		print("Edit slot")
	end,

	LoadCursorItem = function(widget, itemID)
		local cursorInfo = private.status.organize.cursorInfo

		if cursorInfo then
			widget:UpdateSlotInfo(cursorInfo)
			private.status.organize.cursorInfo = nil
		else
			private:CacheItem(itemID)
			local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)

			if bindType and bindType ~= 1 then
				widget:UpdateSlotInfo({ itemID = itemID, stack = private.stack })
			end
		end

		if private.status.organize.editMode ~= "duplicate" then
			ClearCursor()
		end

		widget:LoadSlot()
	end,

	LoadSlot = function(widget)
		local slotInfo =
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][widget:GetUserData(
				"slotID"
			)]
		local isEmpty = not slotInfo or not slotInfo.itemID

		-- Set icon
		widget.frame:SetNormalTexture(
			isEmpty and (private.media .. [[UI-SLOT-BACKGROUND]]) or GetItemIcon(slotInfo.itemID)
		)

		-- Set stack
		if not isEmpty then
			local func = loadstring("return " .. slotInfo.stack)
			if type(func) == "function" then
				local success, userFunc = pcall(func)
				widget.frame:SetText(success and type(userFunc) == "function" and userFunc())
			end
		else
			widget.frame:SetText(" ")
		end
	end,

	PickupItem = function(widget, duplicate)
		local slotInfo =
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][widget:GetUserData(
				"slotID"
			)]
		local isEmpty = not slotInfo or not slotInfo.itemID

		if isEmpty then
			return
		end

		PickupItem(slotInfo.itemID)
		private.status.organize.cursorInfo = slotInfo

		local isDuplicate = private.status.organize.editMode == "duplicate" or duplicate
		widget.image:SetDesaturated(not isDuplicate)
		private.status.organize.originSlot = not isDuplicate and widget
	end,

	UpdateSlotInfo = function(widget, info)
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][widget:GetUserData(
			"slotID"
		)] =
			BankOfficer.CloneTable(
				info
			)
		widget:LoadSlot()
	end,
}

--[[ Constructor ]]
local function Constructor()
	local frame = CreateFrame("Button", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetText(" ")
	frame:SetPushedTextOffset(0, 0)
	frame:SetScript("OnClick", frame_onClick)
	--frame:SetScript("OnEnter", frame_OnEnter)
	--frame:SetScript("OnLeave", frame_OnLeave)

	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	--frame:SetScript("OnDragStart", frame_OnDragStart)

	frame:SetNormalTexture(SLOTBUTTON_TEXTURE)
	frame:SetHighlightTexture(SLOTBUTTON_HIGHLIGHTTEXTURE)

	if not BankOfficer:IsHooked("ClearCursor") then
		BankOfficer:SecureHook("ClearCursor", function()
			local numSlots = AceGUI:GetWidgetCount(Type)
			for i = 1, numSlots do
				local button = _G[Type .. i]
				if button then
					button.obj.image:SetDesaturated(false)
				end
				--_G[Type .. i]:SetDesaturated(false)
			end
		end)
	end

	local contextMenu = CreateFrame(
		"Frame",
		Type .. AceGUI:GetNextWidgetNum(Type) .. "ContextMenu",
		frame,
		"UIDropDownMenuTemplate"
	)

	local widget = {
		frame = frame,
		image = frame:GetNormalTexture(),
		label = frame:GetFontString(),
		contextMenu = contextMenu,
		type = Type,
	}

	frame.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	AceGUI:RegisterAsWidget(widget)

	return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
