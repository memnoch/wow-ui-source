local desaturateSupported = IsDesaturateSupported();

UIPanelWindows["AchievementFrame"] = { area = "doublewide", pushable = 0, width = 700, xoffset = 80 };

ACHIEVEMENTUI_CATEGORIES = {};

ACHIEVEMENTUI_GOLDBORDER_R = 1;
ACHIEVEMENTUI_GOLDBORDER_G = 0.675;
ACHIEVEMENTUI_GOLDBORDER_B = 0.125;
ACHIEVEMENTUI_GOLDBORDER_A = 1;

ACHIEVEMENTUI_REDBORDER_R = 0.7;
ACHIEVEMENTUI_REDBORDER_G = 0.15;
ACHIEVEMENTUI_REDBORDER_B = 0.05;
ACHIEVEMENTUI_REDBORDER_A = 1;

ACHIEVEMENTUI_CATEGORIESWIDTH = 175;

ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS = 5;

ACHIEVEMENTUI_MAXCONTENTWIDTH = 330;

-- Temporary access method

SlashCmdList["ACHIEVEMENTUI"] = function() if ( AchievementFrame:IsShown() ) then HideUIPanel(AchievementFrame) else ShowUIPanel(AchievementFrame) end end;
SLASH_ACHIEVEMENTUI1 = "/ach";
SLASH_ACHIEVEMENTUI2 = "/achieve";
SLASH_ACHIEVEMENTUI3 = "/achievement";
SLASH_ACHIEVEMENTUI4 = "/achievements";

-- [[ AchievementFrame ]] --

function ToggleAchievementFrame()
	if ( AchievementFrame:IsShown() ) then
		HideUIPanel(AchievementFrame);
	else
		ShowUIPanel(AchievementFrame);
	end
end

function AchievementFrame_OnLoad (self)
	PanelTemplates_SetNumTabs(self, 2);
	self.selectedTab = 1;
	PanelTemplates_UpdateTabs(self);
end

function AchievementFrame_OnShow (self)
	PlaySound("igCharacterInfoOpen");
	AchievementFrameHeaderPoints:SetText(GetTotalAchievementPoints());
	if ( not AchievementFrame.wasShown ) then
		AchievementFrame.wasShown = true;
		AchievementCategoryButton_OnClick(AchievementFrameCategoriesContainerButton1);
	end
end

function AchievementFrame_OnHide (self)
	PlaySound("igCharacterInfoClose");
end

function AchievementFrameTab_OnClick (tab)
	local id = tab:GetID();
	
	if ( id == 1 ) then
		achievementFunctions = ACHIEVEMENT_FUNCTIONS;
		if ( achievementFunctions.selectedCategory == "summary" ) then
			AchievementFrame_ShowSummary();
		else
			AchievementFrameAchievements:Show();
			AchievementFrameStats:Hide();
			AchievementFrameSummary:Hide();
		end
		AchievementFrameWaterMark:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementWatermark");
	else
		achievementFunctions = STAT_FUNCTIONS;
		if ( achievementFunctions.selectedCategory == "summary" ) then
			AchievementFrame_ShowSummary();
		else
			AchievementFrameAchievements:Hide();
			AchievementFrameStats:Show();
			AchievementFrameSummary:Hide();
		end
		AchievementFrameWaterMark:SetTexture("Interface\\AchievementFrame\\UI-Achievement-StatWatermark");
	end
	
	AchievementFrameCategories_GetCategoryList(ACHIEVEMENTUI_CATEGORIES);
	AchievementFrameCategories_Update();
end

function AchievementFrame_ShowSummary()
	AchievementFrameSummary:Show();
	AchievementFrameAchievements:Hide();
	AchievementFrameStats:Hide();
end

-- [[ AchievementFrameCategories ]] --

function AchievementFrameCategories_OnLoad (self)
	self:SetBackdropBorderColor(ACHIEVEMENTUI_GOLDBORDER_R, ACHIEVEMENTUI_GOLDBORDER_G, ACHIEVEMENTUI_GOLDBORDER_B, ACHIEVEMENTUI_GOLDBORDER_A);
	self.buttons = {};
	self:RegisterEvent("ADDON_LOADED");
	self:SetScript("OnEvent", AchievementFrameCategories_OnEvent);
end

function AchievementFrameCategories_OnEvent (self, event, ...)
	if ( event == "ADDON_LOADED" ) then
		local addonName = ...;
		if ( addonName and addonName ~= "Blizzard_AchievementUI" ) then
			return;
		end
		
		AchievementFrameCategories_GetCategoryList(ACHIEVEMENTUI_CATEGORIES);
		
		AchievementFrameCategoriesContainerScrollBar.Show = 
			function (self)
				ACHIEVEMENTUI_CATEGORIESWIDTH = 175;
				AchievementFrameCategories:SetWidth(175);
				AchievementFrameCategoriesContainer:GetScrollChild():SetWidth(175);
				AchievementFrameAchievements:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 22, 0);
				AchievementFrameStats:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 22, 0);
				AchievementFrameWaterMark:SetWidth(145);
				AchievementFrameWaterMark:SetTexCoord(0, 145/256, 0, 1);
				for _, button in next, AchievementFrameCategoriesContainer.buttons do
					AchievementFrameCategories_DisplayButton(button, button.element)
				end
				getmetatable(self).__index.Show(self);
			end
			
		AchievementFrameCategoriesContainerScrollBar.Hide = 
			function (self)
				ACHIEVEMENTUI_CATEGORIESWIDTH = 197;
				AchievementFrameCategories:SetWidth(197);
				AchievementFrameCategoriesContainer:GetScrollChild():SetWidth(197);
				AchievementFrameAchievements:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", -2, 0);
				AchievementFrameStats:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", -2, 0);
				AchievementFrameWaterMark:SetWidth(167);
				AchievementFrameWaterMark:SetTexCoord(0, 167/256, 0, 1);
				for _, button in next, AchievementFrameCategoriesContainer.buttons do
					AchievementFrameCategories_DisplayButton(button, button.element);
				end
				getmetatable(self).__index.Hide(self);
			end
			
		AchievementFrameCategoriesContainerScrollBarBG:Show();
		AchievementFrameCategoriesContainer.update = AchievementFrameCategories_Update;
		HybridScrollFrame_CreateButtons(AchievementFrameCategoriesContainer, "AchievementCategoryTemplate", 0, 0, "TOP", "TOP", 0, 0, "TOP", "BOTTOM");
		AchievementFrameCategories_Update();
		self:UnregisterEvent(event)		
	end
end

function AchievementFrameCategories_OnShow (self)
	AchievementFrameCategories_Update();
end

function AchievementFrameCategories_GetCategoryList (categories)
	local cats = achievementFunctions.categoryAccessor();
	
	for i in next, categories do
		categories[i] = nil;
	end
	-- Insert the fake Summary category
	tinsert(categories, { ["id"] = "summary" });

	for i, id in next, cats do
		local _, parent = GetCategoryInfo(id);
		if ( parent == -1 ) then
			tinsert(categories, { ["id"] = id });
		end
	end
	
	local _, parent;
	for i = #cats, 1, -1 do 
		_, parent = GetCategoryInfo(cats[i]);
		for j, category in next, categories do
			if ( category.id == parent ) then
				category.parent = true;
				category.collapsed = true;
				tinsert(categories, j+1, { ["id"] = cats[i], ["parent"] = category.id, ["hidden"] = true});
			end
		end
	end
end

local displayCategories = {};
function AchievementFrameCategories_Update ()
	local scrollFrame = AchievementFrameCategoriesContainer
	
	local categories = ACHIEVEMENTUI_CATEGORIES;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;	
	
	local displayCategories = displayCategories;
	
	for i in next, displayCategories do
		displayCategories[i] = nil;
	end
	
	for i, category in next, categories do
		if ( not category.hidden ) then
			tinsert(displayCategories, category);
		end
	end
	
	local numCategories = #displayCategories;
	local numButtons = #buttons;
	
	local totalHeight = numCategories * buttons[1]:GetHeight();
	local displayedHeight = 0;
	
	local selection = achievementFunctions.selectedCategory;
	
	local element
	for i = 1, numButtons do
		element = displayCategories[i + offset];
		displayedHeight = displayedHeight + buttons[i]:GetHeight();
		if ( element ) then
			AchievementFrameCategories_DisplayButton(buttons[i], element);
			if ( selection and element.id == selection ) then
				buttons[i]:LockHighlight();
			else
				buttons[i]:UnlockHighlight();
			end
			buttons[i]:Show();
		else
			buttons[i].element = nil;
			buttons[i]:Hide();
		end
	end
	
	HybridScrollFrame_Update(scrollFrame, numCategories, totalHeight, displayedHeight);
	
	if ( selection ) then
		achievementFunctions.selectedCategory = selection;
	end
	
	return displayCategories;
end

function AchievementFrameCategories_DisplayButton (button, element)
	if ( not element ) then
		button.element = nil;
		button:Hide();
		return;
	end
	
	button:Show();
	if ( type(element.parent) == "number" ) then
		button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 25);
		button.label:SetFontObject("GameFontHighlight");
		button.parentID = element.parent;
		button.background:SetVertexColor(0.6, 0.6, 0.6);
	else
		button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 10);
		button.label:SetFontObject("GameFontNormal");
		button.parentID = element.parent;
		button.background:SetVertexColor(1, 1, 1);
	end
	
	local categoryName, parentID, flags;
	-- kind of janky
	if ( element.id == "summary" ) then
		categoryName = ACHIEVEMENT_SUMMARY_CATEGORY;
	else
		categoryName, parentID, flags = GetCategoryInfo(element.id);
	end
	button.label:SetText(categoryName);
	button.categoryID = element.id;
	button.flags = flags;
	button.element = element;
end

function AchievementFrameCategories_SelectButton (button)
	local action;
	if ( type(button.element.parent) ~= "number" ) then
		-- Is top level category (can expand/contract)
		if ( button.isSelected and button.element.collapsed == false ) then
			button.element.collapsed = true;
			for i, category in next, ACHIEVEMENTUI_CATEGORIES do
				if ( category.parent == button.element.id ) then
					category.hidden = true;
				end
			end
		else
			for i, category in next, ACHIEVEMENTUI_CATEGORIES do
				if ( category.parent == button.element.id ) then
					category.hidden = false;
				elseif ( category.parent == true ) then
					category.collapsed = true;
				elseif ( category.parent ) then
					category.hidden = true;
				end
			end
			button.element.collapsed = false;
		end
		
		local buttons = AchievementFrameCategoriesContainer.buttons;
		for _, button in next, buttons do
			button.isSelected = nil;
		end
	end
	
	button.isSelected = true;
	--Intercept "summary" category
	if ( button.categoryID == "summary" ) then
		AchievementFrameAchievements:Hide();
		AchievementFrameStats:Hide();
		AchievementFrameSummary:Show();
		achievementFunctions.selectedCategory = button.categoryID;
		return;
	else
		if ( achievementFunctions == STAT_FUNCTIONS ) then
			AchievementFrameAchievements:Hide();
			AchievementFrameStats:Show();
		else
			AchievementFrameAchievements:Show();
			AchievementFrameStats:Hide();
		end
		AchievementFrameSummary:Hide();
	end
	
	achievementFunctions.selectedCategory = button.categoryID;
	if ( achievementFunctions.clearFunc ) then
		achievementFunctions.clearFunc();
	end
	achievementFunctions.updateFunc();
	
	AchievementFrameAchievementsContainerScrollBar:SetValue(0);
end

function AchievementFrameCategories_ClearSelection ()
	local buttons = AchievementFrameCategoriesContainer.buttons;
	for _, button in next, buttons do
		button.isSelected = nil;
		button:UnlockHighlight();
	end
	
	for i, category in next, ACHIEVEMENTUI_CATEGORIES do	
		if ( category.parent == true ) then
			category.collapsed = true;
		elseif ( category.parent ) then
			category.hidden = true;
		end
	end
end

-- [[ AchievementCategoryButton ]] --

ACHIEVEMENT_CATEGORY_NORMAL_R = 0;
ACHIEVEMENT_CATEGORY_NORMAL_G = 0;
ACHIEVEMENT_CATEGORY_NORMAL_B = 0;
ACHIEVEMENT_CATEGORY_NORMAL_A = .9;

ACHIEVEMENT_CATEGORY_HIGHLIGHT_R = 0;
ACHIEVEMENT_CATEGORY_HIGHLIGHT_G = .6;
ACHIEVEMENT_CATEGORY_HIGHLIGHT_B = 0;
ACHIEVEMENT_CATEGORY_HIGHLIGHT_A = .65;

function AchievementCategoryButton_OnLoad (button)
	button:EnableMouse(true);
	button:EnableMouseWheel(true);
	
	local buttonName = button:GetName();
	
	button.label = getglobal(buttonName .. "Label");
	button.background = getglobal(buttonName.."Background");
end

-- These functions simulate button behaviors for our frames.
function AchievementCategoryButton_OnClick (button)
	AchievementFrameCategories_SelectButton(button);
	AchievementFrameCategories_Update();
end

-- [[ AchievementFrameAchievements ]] --

function AchievementFrameAchievements_OnLoad (self)
	AchievementFrameAchievementsContainerScrollBar.Show = 
		function (self)
			AchievementFrameAchievements:SetWidth(504);
			for _, button in next, AchievementFrameAchievements.buttons do
				button:SetWidth(496);
			end
			getmetatable(self).__index.Show(self);
		end
		
	AchievementFrameAchievementsContainerScrollBar.Hide = 
		function (self)
			AchievementFrameAchievements:SetWidth(527);
			for _, button in next, AchievementFrameAchievements.buttons do
				button:SetWidth(519);
			end
			getmetatable(self).__index.Hide(self);
		end
		
	self:RegisterEvent("ACHIEVEMENT_EARNED");
	self:RegisterEvent("CRITERIA_UPDATE");
	AchievementFrameAchievementsContainerScrollBarBG:Show();
	AchievementFrameAchievementsContainer.update = AchievementFrameAchievements_Update;
	HybridScrollFrame_CreateButtons(AchievementFrameAchievementsContainer, "AchievementTemplate", 0, -2);
end

function AchievementFrameAchievements_OnEvent (self, event, ...)
	if ( event == "ACHIEVEMENT_EARNED" ) then
		AchievementFrameAchievements_Update();
		AchievementAlertFrame_ShowAlert(...);
		AchievementFrameHeaderPoints:SetText(GetTotalAchievementPoints());

	elseif ( event == "CRITERIA_UPDATE" ) then
		if ( AchievementFrameAchievements.selection ) then
			local id = AchievementFrameAchievementsObjectives.id;
			local button = AchievementFrameAchievementsObjectives:GetParent();
			AchievementFrameAchievementsObjectives.id = nil;
			AchievementButton_DisplayObjectives(button, id, button.completed);
		end
	end
end

function AchievementFrameAchievementsBackdrop_OnLoad (self)
	self:SetBackdropBorderColor(ACHIEVEMENTUI_GOLDBORDER_R, ACHIEVEMENTUI_GOLDBORDER_G, ACHIEVEMENTUI_GOLDBORDER_B, ACHIEVEMENTUI_GOLDBORDER_A);
	self:SetFrameLevel(self:GetFrameLevel()+1);
end

function AchievementFrameAchievements_Update (category)
	category = category or achievementFunctions.selectedCategory;
	if ( category == "summary" ) then
		return;
	end
	local scrollFrame = AchievementFrameAchievementsContainer
	
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numAchievements, numCompleted = GetCategoryNumAchievements(category);
	local numButtons = #buttons;
	
	local selection = AchievementFrameAchievements.selection;
	if ( selection ) then
		AchievementButton_ResetObjectives();
	end
	
	local extraHeight = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT;
	local displayedHeight = 0;
	for i = 1, numButtons do
		achievementIndex = i + offset;
		local id = AchievementButton_DisplayAchievement(buttons[i], category, achievementIndex, selection);
		-- if ( ( selection ~= nil ) and id == selection and not AchievementFrameAchievements.selection ) then
			-- AchievementFrameAchievements_SelectButton(buttons[i]);
		-- end
		local height = buttons[i]:GetHeight();
		extraHeight = max(height, extraHeight);
		displayedHeight = displayedHeight + height;	
	end
	
	local totalHeight = numAchievements * ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT;
	totalHeight = totalHeight + (extraHeight - ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT);
	
	HybridScrollFrame_Update(scrollFrame, numAchievements, totalHeight, displayedHeight);

	if ( selection ) then
		AchievementFrameAchievements.selection = selection;
	end
end

function AchievementHasProgressBar (achievementID)
	return false;
end

function AchievementFrameAchievements_ClearSelection ()
	AchievementButton_ResetObjectives();
	for _, button in next, AchievementFrameAchievements.buttons do
		button:Collapse();
		if ( not MouseIsOver(button) ) then
			button.highlight:Hide();
		end
		button.selected = nil;
		button.highlight:Hide();
	end
	
	AchievementFrameAchievements.selection = nil;
end


-- [[ Achievement Icon ]] --
if ( desaturateSupported ) then
	function AchievementIcon_Desaturate (self)
		self.bling:SetVertexColor(.6, .6, .6, 1);
		self.frame:SetVertexColor(.75, .75, .75, 1);
		self.texture:SetVertexColor(.55, .55, .55, 1);
	end

	function AchievementIcon_Saturate (self)
		self.bling:SetVertexColor(1, 1, 1, 1);
		self.frame:SetVertexColor(1, 1, 1, 1);
		self.texture:SetVertexColor(1, 1, 1, 1);
	end
else
	function AchievementIcon_Desaturate (self)
		self.bling:SetVertexColor(.6, .6, .6, 1);
		self.frame:SetVertexColor(.75, .75, .75, 1);
		self.texture:SetVertexColor(.55, .55, .55, 1);
	end

	function AchievementIcon_Saturate (self)
		self.bling:SetVertexColor(1, 1, 1, 1);
		self.frame:SetVertexColor(1, 1, 1, 1);
		self.texture:SetVertexColor(1, 1, 1, 1);
	end
end

function AchievementIcon_OnLoad (self)
	local name = self:GetName();
	self.bling = getglobal(name .. "Bling");
	self.texture = getglobal(name .. "Texture");
	self.frame = getglobal(name .. "Overlay");
	
	self.Desaturate = AchievementIcon_Desaturate;
	self.Saturate = AchievementIcon_Saturate;
end

-- [[ Achievement Shield ]] --

function AchievementShield_Desaturate (self)
	self.icon:SetTexCoord(.5, 1, 0, .9);
end

function AchievementShield_Saturate (self)
	self.icon:SetTexCoord(0, .5, 0, .9);
end

function AchievementShield_OnLoad (self)
	local name = self:GetName();
	self.icon = getglobal(name .. "Icon");
	self.points = getglobal(name .. "Points");
	
	self.Desaturate = AchievementShield_Desaturate;
	self.Saturate = AchievementShield_Saturate;
end

-- [[ AchievementButton ]] --

ACHIEVEMENTBUTTON_DESCRIPTIONHEIGHT = 10;
ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT = 82;
ACHIEVEMENTBUTTON_CRITERIAROWHEIGHT = 15;
ACHIEVEMENTBUTTON_MAXHEIGHT = 232;
ACHIEVEMENTBUTTON_TEXTUREHEIGHT = 128;

function AchievementButton_Collapse (self)
	if ( self.collapsed ) then
		return;
	end
	
	self.collapsed = true;
	
	self:SetHeight(ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT);
	
	getglobal(self:GetName() .. "Background"):SetTexCoord(0, 1, 1-(ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT / 256), 1);
	getglobal(self:GetName() .. "Glow"):SetTexCoord(0, 1, 0, ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT / 128);
end

function AchievementButton_Expand (self, height)
	if ( not self.collapsed ) then
		return;
	end
	
	self.collapsed = nil;
	self:SetHeight(height);
	
	getglobal(self:GetName() .. "Background"):SetTexCoord(0, 1, max(0, 1-(height / 256)), 1);
	getglobal(self:GetName() .. "Glow"):SetTexCoord(0, 1, 0, (height+5) / 128);
end

function AchievementButton_Saturate (self)
	local name = self:GetName();
	getglobal(name .. "TitleBackground"):SetTexCoord(0, 0.9765625, 0, 0.3125);
	getglobal(name .. "Background"):SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal");
	getglobal(name .. "Glow"):SetVertexColor(1.0, 1.0, 1.0);
	self.icon:Saturate();
	self.shield:Saturate();
	self.shield.points:SetVertexColor(1, 1, 1);
	self.reward:SetVertexColor(1, .82, 0);
	self.label:SetVertexColor(1, 1, 1);
	self.description:SetFontObject("AchievementDescriptionEnabledFont");
	self.description:SetShadowOffset(0, 0);
	self:SetBackdropBorderColor(ACHIEVEMENTUI_REDBORDER_R, ACHIEVEMENTUI_REDBORDER_G, ACHIEVEMENTUI_REDBORDER_B, ACHIEVEMENTUI_REDBORDER_A);
end

function AchievementButton_Desaturate (self)
	local name = self:GetName();
	getglobal(name .. "TitleBackground"):SetTexCoord(0, 0.9765625, 0.34375, 0.65625);
	getglobal(name .. "Background"):SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal-Desaturated");
	getglobal(name .. "Glow"):SetVertexColor(.22, .17, .13);
	self.icon:Desaturate();
	self.shield:Desaturate();
	self.shield.points:SetVertexColor(.65, .65, .65);
	self.reward:SetVertexColor(.8, .8, .8);
	self.label:SetVertexColor(.65, .65, .65);
	self.description:SetFontObject("AchievementDescriptionDisabledFont");
	self.description:SetShadowOffset(1, -1);
	self:SetBackdropBorderColor(.5, .5, .5);
end

function AchievementButton_OnLoad (self)
	local name = self:GetName();
	
	self.label = getglobal(name .. "Label");
	self.description = getglobal(name .. "Description");
	self.hiddenDescription = getglobal(name .. "HiddenDescription");
	self.check = getglobal(name .. "Check");
	self.reward = getglobal(name .. "Reward");
	self.rewardBackground = getglobal(name.."RewardBackground");
	self.icon = getglobal(name .. "Icon");
	self.shield = getglobal(name .. "Shield");
	self.objectives = getglobal(name .. "Objectives");
	self.highlight = getglobal(name .. "Highlight");
	self.dateCompleted = getglobal(name .. "DateCompleted")
	
	self:SetBackdropBorderColor(ACHIEVEMENTUI_REDBORDER_R, ACHIEVEMENTUI_REDBORDER_G, ACHIEVEMENTUI_REDBORDER_B, ACHIEVEMENTUI_REDBORDER_A);
	self.Collapse = AchievementButton_Collapse;
	self.Expand = AchievementButton_Expand;
	self.Saturate = AchievementButton_Saturate;
	self.Desaturate = AchievementButton_Desaturate;
	
	self:Collapse();
	self:Desaturate();
	
	AchievementFrameAchievements.buttons = AchievementFrameAchievements.buttons or {};
	tinsert(AchievementFrameAchievements.buttons, self);
end

function AchievementButton_OnClick (self)
	if ( self.selected ) then
		if ( not MouseIsOver(self) ) then
			self.highlight:Hide();
		end
		AchievementFrameAchievements_ClearSelection()
		AchievementFrameAchievements_Update();
		return;
	end
	
	if(IsModifiedClick()) then
		if ( IsModifiedClick("CHATLINK") and ChatFrameEditBox:IsVisible() ) then
			local achievementLink = GetAchievementLink(self.id);
			if ( achievementLink ) then
				ChatEdit_InsertLink(achievementLink);
			end
		end
	end
	
	AchievementFrameAchievements_SelectButton(self);
	AchievementFrameAchievements_Update();
end

function AchievementButton_DisplayAchievement (button, category, achievement, selectionID)
	local id, name, points, completed, month, day, year, description, flags, icon = GetAchievementInfo(category, achievement);
	if ( not id ) then
		button:Hide();
		return;
	else
		button:Show();
	end
	
	button.index = achievement;
	button.id = id;
	button.element = true; -- This button has an element
	button.label:SetText(name)
	
	-- Get the cumulative score
	local progressivePoints = AchievementButton_GetProgressivePoints(id);
	if ( progressivePoints ) then
		button.shield.points:SetText(progressivePoints);
	else
		button.shield.points:SetText(points);
	end

	if ( GetAchievementNumCriteria(id) == 0 ) then
		if ( completed ) then
			button.description:SetFontObject("AchievementDescriptionEnabledFont");
			button.description:SetTextColor(0, 0, 0, 1);
			button.check:Show();
			button.description:SetText(description);
		else
			button.description:SetFontObject("AchievementDescriptionDisabledFont");
			button.description:SetTextColor(.6, .6, .6, 1);
			button.check:Hide();
			button.description:SetText("- "..description);
		end
		
	else
		button.description:SetFontObject("AchievementDescriptionEnabledFont");
		button.description:SetTextColor(1, 1, 1, 1);
		button.description:SetText(description);
		button.check:Hide();
	end
	button.hiddenDescription:SetText(description);
	if ( button.hiddenDescription:GetWidth() > ACHIEVEMENTUI_MAXCONTENTWIDTH ) then
		button.description:SetWidth(ACHIEVEMENTUI_MAXCONTENTWIDTH);
	else
		button.description:SetWidth(0);
	end

	
	button.icon.texture:SetTexture(icon);
	if ( rewardText ) then
		button.reward:SetText(rewardText);
		button.reward:Show();
		button.rewardBackground:Show();
	else
		button.reward:Hide();
		button.rewardBackground:Hide();
	end
	if ( completed and not button.completed ) then
		button.completed = true;
		button.dateCompleted:SetText(Localization_GetShortDate(day, month, year));
		button.dateCompleted:Show();
		button:Saturate();
	elseif ( completed ) then
		button.dateCompleted:SetText(Localization_GetShortDate(day, month, year));
	else
		button.completed = nil;
		button.dateCompleted:Hide();
		button:Desaturate();
	end
		
	if ( id == selectionID ) then
		local achievements = AchievementFrameAchievements;
		
		achievements.selection = button.id;
		achievements.selectionIndex = button.index;
		button.selected = true;
		button.highlight:Show();
		local rows = 0;
		
		local height = AchievementButton_DisplayObjectives(button, button.id, button.completed);
		button:Expand(height);
	elseif ( button.selected ) then
		button.selected = nil;
		if ( not MouseIsOver(button) ) then
			button.highlight:Hide();
		end
		button:Collapse();
	end
	
	return id;
end

function AchievementFrameAchievements_SelectButton (button)
	local achievements = AchievementFrameAchievements;
	
	achievements.selection = button.id;
	achievements.selectionIndex = button.index;
	button.selected = true;
end

function AchievementButton_ResetObjectives ()
	AchievementFrameAchievementsObjectives:Hide();
end

function AchievementButton_DisplayObjectives (button, id, completed)
	local objectives = AchievementFrameAchievementsObjectives;
	
	objectives:ClearAllPoints();
	objectives:SetParent(button);
	objectives:Show();
	objectives.completed = completed;
	local height = 0;
	if ( objectives.id == id ) then
		local ACHIEVEMENTMODE_CRITERIA = 1;
		if ( objectives.mode == ACHIEVEMENTMODE_CRITERIA ) then
			if ( objectives:GetHeight() > 0 ) then
				objectives:SetPoint("TOP", "$parentDescription", "BOTTOM", 0, -8);
				objectives:SetPoint("LEFT", "$parentIcon", "RIGHT", -5, 0);
				objectives:SetPoint("RIGHT", "$parentShield", "LEFT", -10, 0);
			end
			height = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT + objectives:GetHeight();
		else
			objectives:SetPoint("TOP", 0, -50);
			height = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT + objectives:GetHeight();
		end
	elseif ( completed and GetPreviousAchievement(id) ) then
		objectives:SetHeight(0);
		AchievementButton_ResetCriteria();
		AchievementButton_ResetProgressBars();
		AchievementButton_ResetMiniAchievements();
		AchievementButton_ResetMetas();
		AchievementObjectives_DisplayProgressiveAchievement(objectives, id);
		objectives:SetPoint("TOP", 0, -50);
		height = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT + objectives:GetHeight();
	else
		objectives:SetHeight(0);	
		AchievementButton_ResetCriteria();
		AchievementButton_ResetProgressBars();
		AchievementButton_ResetMiniAchievements();
		AchievementButton_ResetMetas();
		AchievementObjectives_DisplayCriteria(objectives, id);
		if ( objectives:GetHeight() > 0 ) then
			objectives:SetPoint("TOP", "$parentDescription", "BOTTOM", 0, -8);
			objectives:SetPoint("LEFT", "$parentIcon", "RIGHT", -5, -25);
			objectives:SetPoint("RIGHT", "$parentShield", "LEFT", -10, 0);
		end
		height = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT + objectives:GetHeight();
	end

	objectives.id = id;
	return height;
end


function AchievementButton_ResetTable (t)
	for k, v in next, t do
		v:Hide();
	end
end

local criteriaTable = {}

function AchievementButton_ResetCriteria ()
	AchievementButton_ResetTable(criteriaTable);
end

function AchievementButton_GetCriteria (index)
	local criteriaTable = criteriaTable;
	
	if ( criteriaTable[index] ) then
		return criteriaTable[index];
	end
	
	local frame = CreateFrame("FRAME", "AchievementFrameCriteria" .. index, AchievementFrameAchievements, "AchievementCriteriaTemplate");
	criteriaTable[index] = frame;
	
	return frame;
end

-- The smallest table in WoW.
local miniTable = {}

function AchievementButton_ResetMiniAchievements ()
	AchievementButton_ResetTable(miniTable);
end

function AchievementButton_GetMiniAchievement (index)
	local miniTable = miniTable;
	if ( miniTable[index] ) then
		return miniTable[index];
	end
	
	local frame = CreateFrame("FRAME", "AchievementFrameMiniAchievement" .. index, AchievementFrameAchievements, "MiniAchievementTemplate");
	miniTable[index] = frame;
	
	return frame;
end

local progressBarTable = {};

function AchievementButton_ResetProgressBars ()
	AchievementButton_ResetTable(progressBarTable);
end

function AchievementButton_GetProgressBar (index)
	local progressBarTable = progressBarTable;
	if ( progressBarTable[index] ) then
		return progressBarTable[index];
	end
	
	local frame = CreateFrame("STATUSBAR", "AchievementFrameProgressBar" .. index, AchievementFrameAchievements, "AchievementProgressBarTemplate");
	progressBarTable[index] = frame;
	
	return frame;
end

local metaCriteriaTable = {};

function AchievementButton_ResetMetas ()
	AchievementButton_ResetTable(metaCriteriaTable);
end

function AchievementButton_GetMeta (index)
	local metaCriteriaTable = metaCriteriaTable;
	if ( metaCriteriaTable[index] ) then
		return metaCriteriaTable[index];
	end
	
	local frame = CreateFrame("STATUSBAR", "AchievementFrameMeta" .. index, AchievementFrameAchievements, "MetaCriteriaTemplate");
	metaCriteriaTable[index] = frame;
	
	return frame;
end

function AchievementButton_GetProgressivePoints(achievementID)
	local progressivePoints = 0;
	local _, _, points, completed = GetAchievementInfo(achievementID);
	if ( not completed ) then
		return nil;
	end
	while GetPreviousAchievement(achievementID) do
		_, _, points, completed = GetAchievementInfo(achievementID);
		if ( completed ) then
			progressivePoints = progressivePoints+points;
		end
		achievementID = GetPreviousAchievement(achievementID);
	end
	if ( progressivePoints > 0 ) then
		return progressivePoints;
	else
		return nil;
	end
end

local achievementList = {};

function AchievementObjectives_DisplayProgressiveAchievement (objectivesFrame, id)
	local ACHIEVEMENTMODE_PROGRESSIVE = 2;
	local achievementID = id;

	local achievementList = achievementList;
	for i in next, achievementList do
		achievementList[i] = nil;
	end
	
	while GetPreviousAchievement(achievementID) do
		tinsert(achievementList, 1, GetPreviousAchievement(achievementID));
		achievementID = GetPreviousAchievement(achievementID);
	end
	
	local i = 0;
	for index, achievementID in ipairs(achievementList) do
		local _, achievementName, points, completed, month, day, year, description, flags, iconpath = GetAchievementInfo(achievementID);
		
		local miniAchievement = AchievementButton_GetMiniAchievement(index);
		
		miniAchievement:Show();
		miniAchievement:SetParent(objectivesFrame);
		getglobal(miniAchievement:GetName() .. "Icon"):SetTexture(iconpath);
		if ( index == 1 ) then
			miniAchievement:SetPoint("TOPLEFT", objectivesFrame, "TOPLEFT", -4, -4);
		elseif ( index == 7 ) then
			miniAchievement:SetPoint("TOPLEFT", miniTable[1], "BOTTOMLEFT", 0, -8);
		else
			miniAchievement:SetPoint("TOPLEFT", miniTable[index-1], "TOPRIGHT", 4, 0);
		end
		
		miniAchievement.points:SetText(points);
		
		for i = 1, GetAchievementNumCriteria(achievementID) do
			local criteriaString, criteriaType, completed = GetAchievementCriteriaInfo(achievementID, i);
			if ( completed == false ) then
				criteriaString = "|CFF808080 - " .. criteriaString;
			else
				criteriaString = "|CFF00FF00 - " .. criteriaString;
			end
			miniAchievement["criteria" .. i] = criteriaString;
			miniAchievement.numCriteria = i;
		end
		miniAchievement.name = achievementName;
		miniAchievement.desc = description;
		if ( month ) then
			miniAchievement.date = Localization_GetShortDate(day, month, year);
		end
		i = index;
	end
	
	objectivesFrame:SetHeight(math.ceil(i/6) * 42);
	objectivesFrame:SetWidth(min(i, 6) * 42);
	objectivesFrame.mode = ACHIEVEMENTMODE_PROGRESSIVE;
end

function AchievementObjectives_DisplayCriteria (objectivesFrame, id)
	if ( not id ) then
		return;
	end

	local ACHIEVEMENTMODE_CRITERIA = 1;
	local numCriteria = GetAchievementNumCriteria(id);
	
	if ( numCriteria == 0 ) then
		objectivesFrame.mode = ACHIEVEMENTMODE_CRITERIA;
		objectivesFrame:SetHeight(0);
		return;
	end
	
	local frameLevel = objectivesFrame:GetFrameLevel() + 1;
	
	-- Why textStrings? You try naming anything just "string" and see how happy you are.
	local textStrings, progressBars, metas = 0, 0, 0
	
	local numRows = 0;
	local maxCriteriaWidth = 0;
	for i = 1, numCriteria do	
		local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID = GetAchievementCriteriaInfo(id, i);
		
		if ( criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID ) then
			metas = metas + 1;
			local metaCriteria = AchievementButton_GetMeta(metas);
			
			if ( metas == 1 ) then
				metaCriteria:SetPoint("TOP", objectivesFrame, "TOP", 0, -4);
				numRows = numRows + 2;
			elseif ( math.fmod(metas, 2) == 0 ) then
				metaCriteriaTable[metas-1]:SetPoint("TOPLEFT", objectivesFrame, "TOPLEFT", -20, -((metas/2 - 1) * 28) - 8);
				metaCriteria:SetPoint("TOPLEFT", objectivesFrame, "TOPLEFT", 160, -((metas/2 - 1) * 28) - 8);
			else
				metaCriteria:SetPoint("TOP", objectivesFrame, "BOTTOM", 0, -(math.ceil(metas/2 - 1) * 28) - 8);
				numRows = numRows + 2;
			end
			
			local id, achievementName, points, completed, month, day, year, description, flags, iconpath = GetAchievementInfo(assetID);
			
			if ( month ) then
				metaCriteria.date = Localization_GetShortDate(day, month, year);
			end
			
			metaCriteria.id = id;
			metaCriteria.label:SetText(achievementName);
			metaCriteria.icon:SetTexture(iconpath);

			if ( objectivesFrame.completed and completed ) then
				metaCriteria.check:Show();
				metaCriteria.border:SetVertexColor(1, 1, 1, 1);
				metaCriteria.icon:SetVertexColor(1, 1, 1, 1);
				metaCriteria.label:SetFontObject("AchievementDescriptionEnabledFont");
				metaCriteria.label:SetTextColor(0, 0, 0, 1);
			elseif ( completed ) then
				metaCriteria.check:Show();
				metaCriteria.border:SetVertexColor(1, 1, 1, 1);
				metaCriteria.icon:SetVertexColor(1, 1, 1, 1);
				metaCriteria.label:SetFontObject("AchievementDescriptionEnabledFont");
				metaCriteria.label:SetTextColor(0, 1, 0, 1);
			else
				metaCriteria.check:Hide();
				metaCriteria.border:SetVertexColor(.75, .75, .75, 1);
				metaCriteria.icon:SetVertexColor(.55, .55, .55, 1);
				metaCriteria.label:SetFontObject("AchievementDescriptionDisabledFont");
				metaCriteria.label:SetTextColor(.6, .6, .6, 1);
			end
			
			metaCriteria:SetParent(objectivesFrame);
			metaCriteria:Show();
		elseif ( bit.band(flags, ACHIEVEMENT_CRITERIA_PROGRESS_BAR) == ACHIEVEMENT_CRITERIA_PROGRESS_BAR ) then
			-- Display this criteria as a progress bar!
			progressBars = progressBars + 1;
			local progressBar = AchievementButton_GetProgressBar(progressBars);
			
			if ( progressBars == 1 ) then
				progressBar:SetPoint("TOP", objectivesFrame, "TOP", 4, -4);
			else
				progressBar:SetPoint("TOP", progressBarTable[progressBars-1], "BOTTOM", 0, 0);
			end
			
			progressBar.text:SetText(string.format("%d / %d", quantity, reqQuantity));
			progressBar:SetMinMaxValues(0, reqQuantity);
			progressBar:SetValue(quantity);
			
			progressBar:SetParent(objectivesFrame);
			progressBar:Show();
			
			numRows = numRows + 1;
		else
			textStrings = textStrings + 1;
			local criteria = AchievementButton_GetCriteria(textStrings);
			criteria:ClearAllPoints();
			if ( textStrings == 1 ) then
				if ( numCriteria == 1 ) then
					criteria:SetPoint("TOP", objectivesFrame, "TOP", 0, 0);
				else
					criteria:SetPoint("TOPLEFT", objectivesFrame, "TOPLEFT", 0, 0);
				end
				
			else
				criteria:SetPoint("TOPLEFT", criteriaTable[textStrings-1], "BOTTOMLEFT", 0, 0);
			end
			
			if ( completed ) then
				criteria.check:Show();
				criteria.name:SetText(criteriaString);
			else
				criteria.check:Hide();
				criteria.name:SetText("- "..criteriaString);
			end
			
			if ( objectivesFrame.completed and completed ) then
				criteria.name:SetTextColor(0, 0, 0, 1);
				criteria.name:SetFontObject("AchievementDescriptionEnabledFont");
			elseif ( completed ) then
				criteria.name:SetTextColor(0, 1, 0, 1);
			else
				criteria.name:SetFontObject("AchievementDescriptionDisabledFont");
				criteria.name:SetTextColor(.6, .6, .6, 1);
			end
				
			criteria:SetParent(objectivesFrame);
			criteria:Show();
			local stringWidth = criteria.name:GetStringWidth()
			criteria:SetWidth(stringWidth + criteria.check:GetWidth());
			maxCriteriaWidth = max(maxCriteriaWidth, stringWidth + criteria.check:GetWidth());

			numRows = numRows + 1;
		end
	end

	if ( textStrings > 0 and progressBars > 0 ) then
		-- If we have text criteria and progressBar criteria, display the progressBar criteria first and position the textStrings under them.
		criteriaTable[1]:SetPoint("TOP", progressBarTable[progressBars], "BOTTOM", 0, -4);
	elseif ( textStrings > 1 ) then
		-- Figure out if we can make multiple columns worth of criteria instead of one long one
		local numColumns = floor(ACHIEVEMENTUI_MAXCONTENTWIDTH/maxCriteriaWidth);
		if ( numColumns > 1 ) then
			local step;
			local remainingColumns = numColumns;
			for i=1, numColumns-1 do
				step = ceil(textStrings/remainingColumns)+1;
				criteria = criteriaTable[i*step];
				criteria:SetPoint("TOPLEFT", objectivesFrame, "TOPLEFT", i*ACHIEVEMENTUI_MAXCONTENTWIDTH/numColumns, 0);
				textStrings = textStrings-step;
				remainingColumns = remainingColumns-1;
			end
			numRows = ceil(numRows/numColumns);
		end
	end
	
	objectivesFrame:SetHeight(numRows * ACHIEVEMENTBUTTON_CRITERIAROWHEIGHT);
	objectivesFrame.mode = ACHIEVEMENTMODE_CRITERIA;
end

-- [[ AchievementProgressBars ]] --

function AchievementProgressBar_OnLoad (self)
	self:SetStatusBarColor(0, .6, 0, 1);
	self:SetMinMaxValues(0, 100);
	self:SetValue(0);
	self.text = getglobal(self:GetName() .. "Text");
end

-- [[ StatsFrames ]]--

function AchievementFrameStats_OnLoad (self)
	AchievementFrameStatsContainerScrollBar.Show = 
		function (self)
			AchievementFrameStats:SetWidth(504);
			for _, button in next, AchievementFrameStats.buttons do
				button:SetWidth(496);
			end
			getmetatable(self).__index.Show(self);
		end
		
	AchievementFrameStatsContainerScrollBar.Hide = 
		function (self)
			AchievementFrameStats:SetWidth(527);
			for _, button in next, AchievementFrameStats.buttons do
				button:SetWidth(519);
			end
			getmetatable(self).__index.Hide(self);
		end
		
	AchievementFrameStatsContainerScrollBarBG:Show();
	AchievementFrameStatsContainer.update = AchievementFrameStats_Update;
	HybridScrollFrame_CreateButtons(AchievementFrameStatsContainer, "StatTemplate");
end

function AchievementFrameStats_Update (category)
	category = category or achievementFunctions.selectedCategory;
	local scrollFrame = AchievementFrameStatsContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numStats, numCompleted = GetCategoryNumAchievements(category);
	numStats = numStats+1;
	local numButtons = #buttons;
	local selection = AchievementFrameStats.selection;
	local totalHeight = numStats * 20;
	local displayedHeight = 0;
	local statIndex, id, button;
	
	local buttonIndex = 1+offset;
	for i = 1, numButtons do
		statIndex = i + offset;
		button = buttons[i];
		if ( statIndex <= numStats ) then
			if ( statIndex == 1 ) then
				AchievementFrameStats_SetHeader(button, GetCategoryInfo(category));
				buttonIndex = buttonIndex+1;
			else
				AchievementFramestats_SetStat(button, category, statIndex-1);
			end
			button:Show();
		else
			button:Hide();
		end
		
		displayedHeight = displayedHeight + buttons[i]:GetHeight();
	end
	
	HybridScrollFrame_Update(scrollFrame, numStats, totalHeight, displayedHeight);
end

function AchievementFramestats_SetStat(button, category, index, colorIndex, isSummary)
	--Remove these variables when we know for sure we don't need them
	local id, name, points, completed, month, day, year, description, flags, icon;
	if ( not isSummary ) then
		id, name, points, completed, month, day, year, description, flags, icon = GetAchievementInfo(category, index);
	else
		-- This is on the summary page
		id, name, points, completed, month, day, year, description, flags, icon = GetAchievementInfoFromCriteria(category);
	end

	if ( not colorIndex ) then
		if ( not index ) then
			message("Error, need a color index or index");
		end
		colorIndex = index;
	end
	button:SetText(name);
	button.background:Show();
	-- Color every other line yellow
	if ( mod(colorIndex, 2) == 1 ) then
		button.background:SetTexCoord(0, 1, 0.1875, 0.3671875);
		button.background:SetBlendMode("BLEND");
		button.background:SetAlpha(1.0);
		button:SetHeight(24);
	else
		button.background:SetTexCoord(0, 1, 0.375, 0.5390625);
		button.background:SetBlendMode("ADD");
		button.background:SetAlpha(0.5);
		button:SetHeight(24);
	end
	
	-- Figure out the criteria
	local numCriteria = GetAchievementNumCriteria(id);
	if ( numCriteria == 0 ) then
		-- This is no good!
		--debugprint(name.." has no criteria");
	end
	-- Just show the first criteria for now
	local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID;
	if ( not isSummary ) then
		quantity = GetStatistic(id);
	else
		criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID = GetAchievementCriteriaInfo(category);
	end
	if ( not quantity ) then
		quantity = "--";
	end
	button.value:SetText(quantity);
	
	-- Hide the header images
	button.title:Hide();
	button.left:Hide();
	button.middle:Hide();
	button.right:Hide();

end

function AchievementFrameStats_SetHeader(button, text)
	-- show header
	button.left:Show();
	button.middle:Show();
	button.right:Show();
	button.title:SetText(text);
	button.title:Show();
	button.value:SetText("");
	button:SetText("");
	button:SetHeight(24);
	button.background:Hide();
end

function AchievementStatTemplate_OnLoad(self, parentFrame)
	local name = self:GetName();
	self.background = getglobal(name.."BG");
	self.left = getglobal(name.."HeaderLeft");
	self.middle = getglobal(name.."HeaderMiddle");
	self.right = getglobal(name.."HeaderRight");
	self.text = getglobal(name.."Text");
	self.title = getglobal(name.."Title");
	self.value = getglobal(name.."Value");
	self.value:SetVertexColor(1, 0.97, 0.6);
	parentFrame.buttons = parentFrame.buttons or {};
	tinsert(parentFrame.buttons, self);
end

-- [[ Summary Frame ]] --
function AchievementFrameSummary_Update()
	AchievementFrameSummaryStatusBar_Update();
	AchievementFrameSummary_UpdateAchievements(GetLatestCompletedAchievements());
	AchievementFrameSummary_UpdateStats(GetLatestUpdatedStats());
end

function AchievementFrameSummary_UpdateAchievements(...)
	local numAchievements = select("#", ...);
	local id, name, points, completed, month, day, year, description, flags, icon;
	local buttons = AchievementFrameSummaryAchievements.buttons;
	local button, achievementID;
	
	for i=1, ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
		if ( buttons ) then
			button = buttons[i];
		end
		if ( not button ) then
			button = CreateFrame("Button", "AchievementFrameSummaryAchievement"..i, AchievementFrameSummaryAchievements, "SummaryAchievementTemplate");
			if ( i == 1 ) then
				button:SetPoint("TOPLEFT",AchievementFrameSummaryAchievementsHeader, "BOTTOMLEFT", 0, 0 );
				button:SetPoint("TOPRIGHT",AchievementFrameSummaryAchievementsHeader, "BOTTOMRIGHT", 0, 0 );
			else
				anchorTo = getglobal("AchievementFrameSummaryAchievement"..i-1);
				button:SetPoint("TOPLEFT",anchorTo, "BOTTOMLEFT", 0, 0 );
				button:SetPoint("TOPRIGHT",anchorTo, "BOTTOMRIGHT", 0, 0 );
			end
			if ( not buttons ) then
				buttons = AchievementFrameSummaryAchievements.buttons;
			end
		end;
		if ( i <= numAchievements ) then
			achievementID = select(i, ...);
			id, name, points, completed, month, day, year, description, flags, icon = GetAchievementInfo(achievementID);
			button.name:SetText(name);
			button.points:SetText(points);
			button.icon:SetTexture(icon);
			button.id = id;
			--button.date:SetText(month.."/"..day.."/"..year);
			if ( mod(i, 2) == 1 ) then
				button.background:Show();
			else
				button.background:Hide();
			end
			button:Show();
		else
			button:Hide();
		end
	end
	if ( numAchievements == 0 ) then
		AchievementFrameSummaryAchievementsEmptyText:Show();
	else
		AchievementFrameSummaryAchievementsEmptyText:Hide();
	end
end

function AchievementFrameSummary_UpdateStats(...)
	local numStats = select("#", ...);
	local buttons = AchievementFrameSummaryStats.buttons;
	local stat, statID, anchorTo;
	
	for i=1, ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
		if ( buttons ) then
			stat = buttons[i];
		end
		if ( not stat ) then
			stat = CreateFrame("Button", "AchievementFrameSummaryStat"..i, AchievementFrameSummaryStats, "SummaryStatTemplate");
			if ( i == 1 ) then
				stat:SetPoint("TOPLEFT",AchievementFrameSummaryStatsHeader, "BOTTOMLEFT", 0, 0 );
				stat:SetPoint("TOPRIGHT",AchievementFrameSummaryStatsHeader, "BOTTOMRIGHT", 0, 0 );
			else
				anchorTo = getglobal("AchievementFrameSummaryStat"..i-1);
				stat:SetPoint("TOPLEFT",anchorTo, "BOTTOMLEFT", 0, 0 );
				stat:SetPoint("TOPRIGHT",anchorTo, "BOTTOMRIGHT", 0, 0 );
			end
			stat:Disable();
			if ( not buttons ) then
				buttons = AchievementFrameSummaryStats.buttons;
			end
		end;
		if ( i <= numStats ) then
			statID = select(i, ...);
			AchievementFramestats_SetStat(stat, statID, nil, i, 1);
			stat:Show();
		else
			stat:Hide();
		end
	end
	if ( numStats == 0 ) then
		AchievementFrameSummaryStatsEmptyText:Show();
	else
		AchievementFrameSummaryStatsEmptyText:Hide();
	end
end

function AchievementFrameSummaryStatusBar_Update()
	local total, completed = GetNumCompletedAchievements();
	AchievementFrameSummaryStatusBar:SetMinMaxValues(0, total);
	AchievementFrameSummaryStatusBar:SetValue(completed);
	AchievementFrameSummaryStatusBarText:SetText(completed.."/"..total);
end

function AchievementFrameSummaryAchievement_OnClick(self)

end

-- [[ AchievementAlertFrame ]] --
function AchievementAlertFrame_OnLoad (self)
	self.glow = getglobal(self:GetName().."ButtonGlow");
	self.shine = getglobal(self:GetName().."ButtonShine");
	-- Setup a continous timescale since the table values are offsets
	self.fadeinDuration = 0.2;
	self.flashDuration = 0.5;
	self.shineStartTime = 0.3;
	self.shineDuration = 0.85;
	self.holdDuration = 3;
	self.fadeoutDuration = 1.5;
end

function AchievementAlertFrame_ShowAlert (achievementID)
	local frame = AchievementAlertFrame_GetAlertFrame();
	local _, name, points, completed, month, day, year, description, flags, icon = GetAchievementInfo(achievementID);
	if ( not frame ) then
		-- change this!!!
		local info = ChatTypeInfo["SYSTEM"];
		DEFAULT_CHAT_FRAME:AddMessage(format(ACHIEVEMENT_UNLOCKED_CHAT_MSG, name), info.r, info.g, info.b);
		return;
	end

	getglobal(frame:GetName() .. "Name"):SetText(name);
	getglobal(frame:GetName() .. "Shield").points:SetText(points);
	getglobal(frame:GetName() .. "IconTexture"):SetTexture(icon);
	frame.elapsed = 0;
	frame.state = nil;
	frame:SetAlpha(0);
	frame:Show();
	frame.id = achievementID;
	
	frame:SetScript("OnUpdate", AchievementAlertFrame_OnUpdate);
end

function AchievementAlertFrame_GetAlertFrame()
	local maxAlerts = 2;
	local name, frame, previousFrame;
	for i=1, maxAlerts do
		name = "AchievementAlertFrame"..i;
		frame = getglobal(name);
		if ( frame ) then
			if ( not frame:IsShown() ) then
				return frame;
			end
		else
			frame = CreateFrame("Frame", name, UIParent, "AchievementAlertFrameTemplate");
			if ( not previousFrame ) then
				frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 128);
			else
				frame:SetPoint("BOTTOM", previousFrame, "TOP", 0, -10);
			end
			return frame;
		end
		previousFrame = frame;
	end
	return nil;
end

function AchievementAlertFrame_OnUpdate (self, elapsed)
	local state = self.state;
	local alpha;
	local deltaTime = elapsed;
	--initialize
	if ( not state ) then
		state = "fadein";
		self.glow:Show();
		self.glow:SetAlpha(0);
		self.totalElapsed = 0;
	end
	self.totalElapsed = self.totalElapsed+elapsed;
	elapsed = self.elapsed + elapsed;
	if ( state == "fadein" ) then
		if ( elapsed >= self.fadeinDuration ) then
			state = "flash";
			elapsed = 0;
			self:SetAlpha(1);
			self.glow:Show();
		else
			self:SetAlpha(elapsed/self.fadeinDuration);
			self.glow:SetAlpha(elapsed/self.fadeinDuration);
		end
	elseif ( state == "flash" ) then
		if ( elapsed >= self.flashDuration ) then
			state = "hold";
			elapsed = 0;
			self.glow:Hide();
		else
			self.glow:SetAlpha(1-(elapsed/self.flashDuration));
		end
	elseif ( state == "hold" ) then
		if ( elapsed >= self.holdDuration ) then
			state = "fadeout";
			elapsed = 0;
		end
	elseif ( state == "fadeout" ) then
		if ( elapsed >= self.fadeoutDuration ) then
			state = nil;
			self:SetScript("OnUpdate", nil);
			self:Hide();
			self.id = nil;
		else
			self:SetAlpha(1-(elapsed/self.fadeoutDuration));
		end
	end

	--Handle shine
	local normalizedTime = self.totalElapsed - self.shineStartTime;
	if ( normalizedTime >= 0 and normalizedTime <= self.shineDuration ) then
		if ( not self.shine:IsShown() ) then
			self.shine:Show();
			self.shine:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -8);
			self.shine:SetAlpha(1);
		end
		local target = 239;
		local _,_,_,x = self.shine:GetPoint();
		if ( x ~= target ) then
			x = x +(target-x)*(deltaTime/(self.shineDuration/3));
			if ( floor(abs(target - x)) == 0 ) then
				x = target;
			end
		end
		
		self.shine:SetPoint("TOPLEFT", self, "TOPLEFT", x, -8);
		self.shine:SetAlpha(1);
		local startShineFade = 0.8*self.shineDuration;
		if ( normalizedTime >= startShineFade ) then
			self.shine:SetAlpha(1-((normalizedTime-startShineFade)/(self.shineDuration-startShineFade)));
		end
	else
		if ( self.shine:IsShown() ) then
			self.shine:Hide();
			self.vel = nil;
		end
	end

	self.state = state;
	self.elapsed = elapsed;
end

function AchievementAlertFrame_OnClick (self)
	local id = self.id;
	if ( not id ) then
		return;
	end
	
	self.elapsed = 0;
	ShowUIPanel(AchievementFrame);
	AchievementFrame_SelectAchievement(id)
end

function AchievementFrame_SelectAchievement(id)
	AchievementFrameCategories_ClearSelection();
	local category = GetAchievementCategory(id);
	
	local categoryIndex, parent, hidden = 0;
	for i, entry in next, ACHIEVEMENTUI_CATEGORIES do
		if ( entry.id == category ) then
			index = i;
			parent = entry.parent;
		end
	end
	
	for i, entry in next, ACHIEVEMENTUI_CATEGORIES do
		if ( entry.id == parent ) then
			entry.collapsed = false;
		elseif ( entry.parent == parent ) then
			entry.hidden = false;
		elseif ( entry.parent == true ) then
			entry.collapsed = true;
		elseif ( entry.parent ) then
			entry.hidden = true;
		end
	end
		
	achievementFunctions.selectedCategory = category;
	AchievementFrameCategories_Update();
	AchievementFrameCategoriesContainerScrollBar:SetValue(0);
	
	local shown, i = false, 1;
	while ( not shown ) do
		for _, button in next, AchievementFrameCategoriesContainer.buttons do
			if ( button.categoryID == category and math.ceil(button:GetBottom()) >= math.ceil(AchievementFrameAchievementsContainer:GetBottom())) then
				shown = true;
			end
		end
		
		if ( not shown ) then
			local _, maxVal = AchievementFrameCategoriesContainerScrollBar:GetMinMaxValues();
			if ( AchievementFrameCategoriesContainerScrollBar:GetValue() == maxVal ) then
				assert(false)
			else
				HybridScrollFrame_OnMouseWheel(AchievementFrameCategoriesContainer, -1);
			end			
		end
		
		-- Remove me if everything's working fine
		i = i + 1;
		if ( i > 100 ) then
			assert(false);
		end
	end		
	
	AchievementFrameAchievements_ClearSelection();	
	AchievementFrameAchievements_Update();
	AchievementFrameAchievementsContainerScrollBar:SetValue(0);

	local shown, i = false, 1;
	while ( not shown ) do
		for _, button in next, AchievementFrameAchievementsContainer.buttons do
			if ( button.id == id and math.ceil(button:GetBottom()) >= math.ceil(AchievementFrameAchievementsContainer:GetBottom())) then
				AchievementFrameAchievements_SelectButton(button);
				shown = true;
			end
		end			
		
		if ( not shown ) then
			local _, maxVal = AchievementFrameAchievementsContainerScrollBar:GetMinMaxValues();
			if ( AchievementFrameAchievementsContainerScrollBar:GetValue() == maxVal ) then
				assert(false)
			else
				HybridScrollFrame_OnMouseWheel(AchievementFrameAchievementsContainer, -1);
			end			
		end
		
		-- Remove me if everything's working fine.
		i = i + 1;
		if ( i > 100 ) then
			assert(false);
		end
	end
end

ACHIEVEMENT_FUNCTIONS = {
	categoryAccessor = GetCategoryList,
	clearFunc = AchievementFrameAchievements_ClearSelection,
	updateFunc = AchievementFrameAchievements_Update,
	selectedCategory = "summary";
}
STAT_FUNCTIONS = {
	categoryAccessor = GetStatisticsCategoryList,
	clearFunc = nil,
	updateFunc = AchievementFrameStats_Update,
	selectedCategory = "summary";
}
achievementFunctions = ACHIEVEMENT_FUNCTIONS;