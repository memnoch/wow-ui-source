PERFORMANCEBAR_UPDATE_INTERVAL = 1;
MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"EJMicroButton",
	"CompanionsMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
	"StoreMicroButton",
	}


function LoadMicroButtonTextures(self, name)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:RegisterEvent("UPDATE_BINDINGS");
	self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT");
	local prefix = "Interface\\Buttons\\UI-MicroButton-";
	self:SetNormalTexture(prefix..name.."-Up");
	self:SetPushedTexture(prefix..name.."-Down");
	self:SetDisabledTexture(prefix..name.."-Disabled");
	self:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight");
end

function MicroButtonTooltipText(text, action)
	if ( GetBindingKey(action) ) then
		return text.." "..NORMAL_FONT_COLOR_CODE.."("..GetBindingText(GetBindingKey(action))..")"..FONT_COLOR_CODE_CLOSE;
	else
		return text;
	end
	
end

function MicroButton_OnEnter(self)
	if ( self:IsEnabled() or self.minLevel or self.disabledTooltip or self.factionGroup) then
		GameTooltip_AddNewbieTip(self, self.tooltipText, 1.0, 1.0, 1.0, self.newbieText);
		GameTooltip:AddLine(" ");
		if ( not self:IsEnabled() ) then
			if ( self.factionGroup == "Neutral" ) then
				GameTooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
				GameTooltip:Show();
			elseif ( self.minLevel ) then
				GameTooltip:AddLine(format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, self.minLevel), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
				GameTooltip:Show();
			elseif ( self.disabledTooltip ) then
				GameTooltip:AddLine(self.disabledTooltip, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
				GameTooltip:Show();
			end
		end
	end
end

function UpdateMicroButtonsParent(parent)
	for i=1, #MICRO_BUTTONS do
		_G[MICRO_BUTTONS[i]]:SetParent(parent);
	end
end

function MoveMicroButtons(anchor, anchorTo, relAnchor, x, y, isStacked)
	CharacterMicroButton:ClearAllPoints();
	CharacterMicroButton:SetPoint(anchor, anchorTo, relAnchor, x, y);
	LFDMicroButton:ClearAllPoints();
	if ( isStacked ) then
		LFDMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 24);
	else
		LFDMicroButton:SetPoint("BOTTOMLEFT", GuildMicroButton, "BOTTOMRIGHT", -3, 0);
	end
	UpdateMicroButtons();
end

function UpdateMicroButtons()
	local playerLevel = UnitLevel("player");
	local factionGroup = UnitFactionGroup("player");

	if ( factionGroup == "Neutral" ) then
		GuildMicroButton.factionGroup = factionGroup;
		LFDMicroButton.factionGroup = factionGroup;
	else
		GuildMicroButton.factionGroup = nil;
		LFDMicroButton.factionGroup = nil;
	end
		

	if ( CharacterFrame and CharacterFrame:IsShown() ) then
		CharacterMicroButton:SetButtonState("PUSHED", true);
		CharacterMicroButton_SetPushed();
	else
		CharacterMicroButton:SetButtonState("NORMAL");
		CharacterMicroButton_SetNormal();
	end
	
	if ( SpellBookFrame and SpellBookFrame:IsShown() ) then
		SpellbookMicroButton:SetButtonState("PUSHED", true);
	else
		SpellbookMicroButton:SetButtonState("NORMAL");
	end

	if ( PlayerTalentFrame and PlayerTalentFrame:IsShown() ) then
		TalentMicroButton:SetButtonState("PUSHED", true);
	else
		if ( playerLevel < SHOW_SPEC_LEVEL ) then
			TalentMicroButton:Disable();
		else
			TalentMicroButton:Enable();
			TalentMicroButton:SetButtonState("NORMAL");
		end
	end

	if (  WorldMapFrame and WorldMapFrame:IsShown() ) then
		QuestLogMicroButton:SetButtonState("PUSHED", true);
	else
		QuestLogMicroButton:SetButtonState("NORMAL");
	end
	
	if ( ( GameMenuFrame and GameMenuFrame:IsShown() ) 
		or ( InterfaceOptionsFrame:IsShown()) 
		or ( KeyBindingFrame and KeyBindingFrame:IsShown()) 
		or ( MacroFrame and MacroFrame:IsShown()) ) then
		MainMenuMicroButton:SetButtonState("PUSHED", true);
		MainMenuMicroButton_SetPushed();
	else
		MainMenuMicroButton:SetButtonState("NORMAL");
		MainMenuMicroButton_SetNormal();
	end

	GuildMicroButton_UpdateTabard();
	if ( IsTrialAccount() or factionGroup == "Neutral" ) then
		GuildMicroButton:Disable();
	elseif ( ( GuildFrame and GuildFrame:IsShown() ) or ( LookingForGuildFrame and LookingForGuildFrame:IsShown() ) ) then
		GuildMicroButton:Enable();
		GuildMicroButton:SetButtonState("PUSHED", true);
		GuildMicroButtonTabard:SetPoint("TOPLEFT", -1, -1);
		GuildMicroButtonTabard:SetAlpha(0.70);
	else
		GuildMicroButton:Enable();
		GuildMicroButton:SetButtonState("NORMAL");
		GuildMicroButtonTabard:SetPoint("TOPLEFT", 0, 0);
		GuildMicroButtonTabard:SetAlpha(1);	
		if ( IsInGuild() ) then
			GuildMicroButton.tooltipText = MicroButtonTooltipText(GUILD, "TOGGLEGUILDTAB");
			GuildMicroButton.newbieText = NEWBIE_TOOLTIP_GUILDTAB;
		else
			GuildMicroButton.tooltipText = MicroButtonTooltipText(LOOKINGFORGUILD, "TOGGLEGUILDTAB");
			GuildMicroButton.newbieText = NEWBIE_TOOLTIP_LOOKINGFORGUILDTAB;
		end
	end
	
	if ( PVEFrame and PVEFrame:IsShown() ) then
		LFDMicroButton:SetButtonState("PUSHED", true);
	else
		if ( playerLevel < LFDMicroButton.minLevel or factionGroup == "Neutral" ) then
			LFDMicroButton:Disable();
		else
			LFDMicroButton:Enable();
			LFDMicroButton:SetButtonState("NORMAL");
		end
	end

	if ( HelpFrame and HelpFrame:IsShown() ) then
		HelpMicroButton:SetButtonState("PUSHED", true);
	else
		HelpMicroButton:SetButtonState("NORMAL");
	end
	
	if ( AchievementFrame and AchievementFrame:IsShown() ) then
		AchievementMicroButton:SetButtonState("PUSHED", true);
	else
		if ( ( HasCompletedAnyAchievement() or IsInGuild() ) and CanShowAchievementUI() ) then
			AchievementMicroButton:Enable();
			AchievementMicroButton:SetButtonState("NORMAL");
		else
			AchievementMicroButton:Disable();
		end
	end
	
	if ( EncounterJournal and EncounterJournal:IsShown() ) then
		EJMicroButton:SetButtonState("PUSHED", true);
	else
		EJMicroButton:SetButtonState("NORMAL");
	end

	if ( PetJournalParent and PetJournalParent:IsShown() ) then
		CompanionsMicroButton:Enable();
		CompanionsMicroButton:SetButtonState("PUSHED", true);
	else
		CompanionsMicroButton:Enable();
		CompanionsMicroButton:SetButtonState("NORMAL");
	end

	if ( StoreFrame and StoreFrame_IsShown() ) then
		StoreMicroButton:SetButtonState("PUSHED", true);
	else
		StoreMicroButton:SetButtonState("NORMAL");
	end

	if ( C_StorePublic.IsEnabled() ) then
		MainMenuMicroButton:SetPoint("BOTTOMLEFT", StoreMicroButton, "BOTTOMRIGHT", -3, 0);
		HelpMicroButton:Hide();
		StoreMicroButton:Show();
	else
		MainMenuMicroButton:SetPoint("BOTTOMLEFT", EJMicroButton, "BOTTOMRIGHT", -3, 0);
		HelpMicroButton:Show();
		StoreMicroButton:Hide();
	end

	if ( IsTrialAccount() ) then
		StoreMicroButton.disabledTooltip = ERR_GUILD_TRIAL_ACCOUNT;
		StoreMicroButton:Disable();
	elseif ( C_StorePublic.IsDisabledByParentalControls() ) then
		StoreMicroButton.disabledTooltip = BLIZZARD_STORE_ERROR_PARENTAL_CONTROLS;
		StoreMicroButton:Disable();		
	else
		StoreMicroButton.disabledTooltip = nil;
		StoreMicroButton:Enable();
	end
end

function MicroButtonPulse(self, duration)
	UIFrameFlash(self.Flash, 1.0, 1.0, duration or -1, false, 0, 0, "microbutton");
end

function MicroButtonPulseStop(self)
	UIFrameFlashStop(self.Flash);
end

function AchievementMicroButton_OnEvent(self, event, ...)
	if (IsBlizzCon()) then
		return;
	end

	if ( event == "UPDATE_BINDINGS" ) then
		AchievementMicroButton.tooltipText = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT");
	else
		UpdateMicroButtons();
	end
end

function GuildMicroButton_OnEvent(self, event, ...)
	if (IsBlizzCon()) then
		return;
	end

	if ( event == "UPDATE_BINDINGS" ) then
		if ( IsInGuild() ) then
			GuildMicroButton.tooltipText = MicroButtonTooltipText(GUILD, "TOGGLEGUILDTAB");
		else
			GuildMicroButton.tooltipText = MicroButtonTooltipText(LOOKINGFORGUILD, "TOGGLEGUILDTAB");
		end
	elseif ( event == "PLAYER_GUILD_UPDATE" or event == "NEUTRAL_FACTION_SELECT_RESULT" ) then
		GuildMicroButtonTabard.needsUpdate = true;
		UpdateMicroButtons();
	end
end

function GuildMicroButton_UpdateTabard(forceUpdate)
	local tabard = GuildMicroButtonTabard;
	if ( not tabard.needsUpdate and not forceUpdate ) then
		return;
	end
	-- switch textures if the guild has a custom tabard	
	local emblemFilename = select(10, GetGuildLogoInfo());
	if ( emblemFilename ) then
		if ( not tabard:IsShown() ) then
			local button = GuildMicroButton;
			button:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up");
			button:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down");
			-- no need to change disabled texture, should always be available if you're in a guild
			tabard:Show();
		end
		SetSmallGuildTabardTextures("player", tabard.emblem, tabard.background);
	else
		if ( tabard:IsShown() ) then
			local button = GuildMicroButton;
			button:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Socials-Up");
			button:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Socials-Down");
			button:SetDisabledTexture("Interface\\Buttons\\UI-MicroButton-Socials-Disabled");
			tabard:Hide();
		end
	end
	tabard.needsUpdate = nil;
end

function CharacterMicroButton_OnLoad(self)
	self:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up");
	self:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down");
	self:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	self:RegisterEvent("UPDATE_BINDINGS");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0");
	self.newbieText = NEWBIE_TOOLTIP_CHARACTER;
end

function CharacterMicroButton_OnEvent(self, event, ...)
	if ( event == "UNIT_PORTRAIT_UPDATE" ) then
		local unit = ...;
		if ( not unit or unit == "player" ) then
			SetPortraitTexture(MicroButtonPortrait, "player");
		end
		return;
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		SetPortraitTexture(MicroButtonPortrait, "player");
	elseif ( event == "UPDATE_BINDINGS" ) then
		self.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0");
	end
end

function CharacterMicroButton_SetPushed()
	MicroButtonPortrait:SetTexCoord(0.2666, 0.8666, 0, 0.8333);
	MicroButtonPortrait:SetAlpha(0.5);
end

function CharacterMicroButton_SetNormal()
	MicroButtonPortrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9);
	MicroButtonPortrait:SetAlpha(1.0);
end

function MainMenuMicroButton_SetPushed()
	MainMenuMicroButton:SetButtonState("PUSHED", true);
end

function MainMenuMicroButton_SetNormal()
	MainMenuMicroButton:SetButtonState("NORMAL");
end

--Talent button specific functions
function TalentMicroButton_OnEvent(self, event, ...)
	if ( event == "PLAYER_LEVEL_UP" ) then
		local level = ...;
		if (level == SHOW_SPEC_LEVEL) then
			MicroButtonPulse(self);
			TalentMicroButtonAlert.Text:SetText(TALENT_MICRO_BUTTON_SPEC_TUTORIAL);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:Show();
		elseif (level == SHOW_TALENT_LEVEL) then
			MicroButtonPulse(self);
			TalentMicroButtonAlert.Text:SetText(TALENT_MICRO_BUTTON_TALENT_TUTORIAL);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:Show();
		end
	elseif ( event == "PLAYER_SPECIALIZATION_CHANGED") then
		-- If we just unspecced, and we have unspent talent points, it's probably spec-specific talents that were just wiped.  Show the tutorial box.
		local unit = ...;
		if(unit == "player" and GetSpecialization() == nil and GetNumUnspentTalents() > 0) then
			TalentMicroButtonAlert.Text:SetText(TALENT_MICRO_BUTTON_UNSPENT_TALENTS);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:Show();
		end
	elseif ( event == "PLAYER_TALENT_UPDATE" or event == "NEUTRAL_FACTION_SELECT_RESULT" ) then
		UpdateMicroButtons();
		
		-- On the first update from the server, flash the button if there are unspent points
		-- Small hack: GetNumSpecializations should return 0 if talents haven't been initialized yet
		if (not self.receivedUpdate and GetNumSpecializations(false) > 0) then
			self.receivedUpdate = true;
			local shouldPulseForTalents = GetNumUnspentTalents() > 0 and not ShouldHideTalentsTab();
			if (UnitLevel("player") >= SHOW_SPEC_LEVEL and (not GetSpecialization() or shouldPulseForTalents)) then
				MicroButtonPulse(self);
			end
		end
	elseif ( event == "UPDATE_BINDINGS" ) then
		self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS");
	elseif ( event == "PLAYER_CHARACTER_UPGRADE_TALENT_COUNT_CHANGED" ) then
		local prev, current = ...;
		if ( prev == 0 and current > 0 ) then
			MicroButtonPulse(self);
			TalentMicroButtonAlert.Text:SetText(TALENT_MICRO_BUTTON_TALENT_TUTORIAL);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:Show();
		elseif ( prev ~= current ) then
			MicroButtonPulse(self);
			TalentMicroButtonAlert.Text:SetText(TALENT_MICRO_BUTTON_UNSPENT_TALENTS);
			TalentMicroButtonAlert:SetHeight(TalentMicroButtonAlert.Text:GetHeight()+42);
			TalentMicroButtonAlert:Show();
		end
	end
end

--Micro Button alerts
function MicroButtonAlert_OnLoad(self)
	self.Text:SetSpacing(4);
	if ( self.label ) then
		self.Text:SetText(self.label);
	end
end

