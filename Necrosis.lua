------------------------------------------------------------------------------------------------------
-- Necrosis LdC
--
-- Original creator (US): Infernal (http://www.revolvus.com/games/interface/necrosis/)
-- Base implementation (FR): Tilienna Thorondor
-- Project continuation: Lomig & Nyx of Larmes de Cenarius, Kael'Thas
--
-- French skins and voices: Eliah, Ner'zhul
-- German version: Arne Meier and Halisstra, Lothar
-- Special thanks to Sadyre (JoL)
-- Version 05.09.2006-1
------------------------------------------------------------------------------------------------------

-- Default configuration
-- Loaded when no configuration is found or when the version changes
Default_NecrosisConfig = {
	Version = NecrosisData.Version;
	SoulshardContainer = 4;
	SoulshardSort = false;
	SoulshardDestroy = false;
	ShadowTranceAlert = true;
	ShowSpellTimers = true;
	AntiFearAlert = true;
	NecrosisLockServ = true;
	NecrosisAngle = 180;
	StonePosition = {true, true, true, true, true, true, true, true};
	NecrosisToolTip = true;
	NoDragAll = false;
	PetMenuPos = 34;
	BuffMenuPos = 34;
	CurseMenuPos = 34;
	StoneMenuPos = 34;
	ChatMsg = true;
	ChatType = true;
	NecrosisLanguage = GetLocale();
	ShowCount = true;
	CountType = 1;
	ShadowTranceScale = 100;
	NecrosisButtonScale = 90;
	NecrosisColor = "Rose";
	Sound = true;
	SpellTimerPos = 1;
	SpellTimerJust = "LEFT";
	Circle = 1;
	Graphical = true;
	Yellow = true;
	SensListe = 1;
	PetName = {
		[1] = " ",
		[2] = " ",
		[3] = " ",
		[4] = " "
	};
	DominationUp = false;
	AmplifyUp = false;
	SM = false;
	SteedSummon = false;
	DemonSummon = true;
	RitualMessage = true;
	BanishScale = 100;
};

NecrosisConfig = {};
local Debug = false;
local Loaded = false

-- Detect mod initialization
local NecrosisRL = true;

-- Initialize variables used by Necrosis to manage spell casts
local SpellCastName = nil;
local SpellCastRank = nil;
local SpellTargetName = nil;
local SpellTargetLevel = nil;
local SpellCastTime = 0;

-- Initialize the tables that manage timers
-- One stores timed spells, the other stores mob groups
-- The last one links a timer to a graphical frame
SpellTimer = {};
local SpellGroup = {
	Name = {"Rez", "Main", "Cooldown"},
	SubName = {" ", " ", " "},
	Visible = {true, true, true}
};

-- Clears contents but preserves subtable objects
local function clear_tables(t)
    for k, v in pairs(t) do
        if type(v) == "table" then
            -- recurse: empty the subtable
            clear_tables(v)
        else
            -- remove only non-table values
            t[k] = nil
        end
    end
end


-- Reusable buffers for graphical timers (avoid per-frame allocations)
local GraphicalTimer = {
  texte  = {},
  TimeMax= {},
  Time   = {},
  titre  = {},
  temps  = {},
  Gtimer = {},
}

local TimerTable = {};
for i = 1, 50, 1 do
	TimerTable[i] = false;
end

local ICON_BASE_PATH = "Interface\\AddOns\\Necrosis\\UI\\"
local ACCENT_RING_TEXTURE = ICON_BASE_PATH .. "AccentRing"

local ICON_ACCENT_COLORS = {
	Agony = {0.4656, 0.4655, 0.4655},
	Amplify = {0.2623, 0.2623, 0.2623},
	Aqua = {0.4678, 0.4678, 0.4678},
	ArmureDemo = {0.2955, 0.2952, 0.2953},
	Banish = {0.4772, 0.4775, 0.4783},
	Domination = {0.3429, 0.3429, 0.3429},
	Doom = {0.2978, 0.2977, 0.2977},
	Doomguard = {0.3490, 0.3490, 0.3490},
	Elements = {0.3217, 0.3216, 0.3216},
	Enslave = {0.3878, 0.3878, 0.3881},
	Exhaust = {0.3205, 0.3205, 0.3205},
	Felhunter = {0.2852, 0.2825, 0.2816},
	Felstone = {0.3590, 0.5627, 0.2030},
	FirestoneButton = {0.8148, 0.3459, 0.5506},
	HealthstoneButton = {0.2921, 0.7151, 0.2921},
	Imp = {0.3634, 0.3649, 0.3521},
	Infernal = {0.4980, 0.4980, 0.4980},
	Invisible = {0.5955, 0.5955, 0.5955},
	Kilrogg = {0.3402, 0.3402, 0.3402},
	Lien = {0.4047, 0.4047, 0.4047},
	MountButton = {0.3368, 0.3336, 0.3327},
	Radar = {0.3104, 0.3104, 0.3104},
	Reckless = {0.3942, 0.3941, 0.3941},
	Sacrifice = {0.3967, 0.3967, 0.3967},
	Shadow = {0.4189, 0.4188, 0.4188},
	["ShadowTrance-Icon"] = {0.4173, 0.2913, 0.4487},
	ShadowWard = {0.2620, 0.2620, 0.2620},
	SoulstoneButton = {0.5463, 0.2720, 0.5324},
	SpellstoneButton = {0.2844, 0.4891, 0.8284},
	Succubus = {0.3056, 0.3053, 0.3055},
	Tongues = {0.3034, 0.3034, 0.3034},
	Voidstone = {0.2820, 0.1570, 0.5112},
	Voidwalker = {0.1769, 0.1775, 0.1825},
	Weakness = {0.3441, 0.3440, 0.3440},
	Wrathstone = {0.5331, 0.1212, 0.1892},
}

local HANDLED_ICON_BASES = {}
for name in pairs(ICON_ACCENT_COLORS) do
	HANDLED_ICON_BASES[name] = true
end

local function Necrosis_AttachRing(button)
	if button.NecrosisAccentRing then
		return button.NecrosisAccentRing
	end
	local ring = button:CreateTexture(nil, "OVERLAY")
	ring:SetTexture(ACCENT_RING_TEXTURE)
	ring:SetAllPoints(button)
	ring:SetVertexColor(0.66, 0.66, 0.66)
	button.NecrosisAccentRing = ring
	return ring
end

local function Necrosis_SetButtonTexture(button, base, variant)
	if not button or not base then
		return
	end
	local numberVariant = tonumber(variant) or variant or 2
	if not HANDLED_ICON_BASES[base] then
		button:SetNormalTexture(ICON_BASE_PATH .. base .. "-0" .. numberVariant)
		return
	end
	local texturePath = ICON_BASE_PATH .. base .. ".tga"
	button:SetNormalTexture(texturePath)
	local icon = button:GetNormalTexture()
	button.NecrosisIconBase = base
	icon:SetVertexColor(1, 1, 1)
	local ring = Necrosis_AttachRing(button)
	if numberVariant == 1 then
		icon:SetVertexColor(0.35, 0.35, 0.35)
		ring:SetVertexColor(0.35, 0.35, 0.35)
	elseif numberVariant == 3 then
		ring:SetVertexColor(unpack(ICON_ACCENT_COLORS[base] or {0.66, 0.66, 0.66}))
	else
		ring:SetVertexColor(0.66, 0.66, 0.66)
	end
end

local MENU_BUTTON_COUNT = 9;

local function Necrosis_SetMenuAlpha(prefix, alpha)
	for index = 1, MENU_BUTTON_COUNT, 1 do
		local frame = getglobal(prefix .. index);
		if frame then
			frame:SetAlpha(alpha);
		end
	end
end

local function Necrosis_OnBagUpdate()
	if NecrosisConfig.SoulshardSort then
		Necrosis_SoulshardSwitch("CHECK");
	else
		Necrosis_BagExplore();
	end
end

local function Necrosis_OnSpellcastStart(spellName)
	SpellCastName = spellName;
	SpellTargetName = UnitName("target");
	if not SpellTargetName then
		SpellTargetName = "";
	end
	SpellTargetLevel = UnitLevel("target");
	if not SpellTargetLevel then
		SpellTargetLevel = "";
	end
end

local function Necrosis_ClearSpellcastContext()
	SpellCastName = nil;
	SpellCastRank = nil;
	SpellTargetName = nil;
	SpellTargetLevel = nil;
end

local function Necrosis_SetTradeRequest(active)
	NecrosisTradeRequest = active;
end

local function Necrosis_OnTargetChanged()
	if NecrosisConfig.AntiFearAlert and AFCurrentTargetImmune then
		AFCurrentTargetImmune = false;
	end
end

local function Necrosis_HandleSelfFearDamage(message)
	if not NecrosisConfig.AntiFearAlert or not message then
		return;
	end
	for spell, creatureName in string.gfind(message, NECROSIS_ANTI_FEAR_SRCH) do
		if spell == NECROSIS_SPELL_TABLE[13].Name or spell == NECROSIS_SPELL_TABLE[19].Name then
			AFCurrentTargetImmune = true;
			break;
		end
	end
end

local function Necrosis_OnSpellLearned()
	Necrosis_SpellSetup();
	Necrosis_CreateMenu();
	Necrosis_ButtonSetup();
end

local function Necrosis_OnCombatEnd()
	PlayerCombat = false;
	SpellGroup, SpellTimer, TimerTable = Necrosis_RetraitTimerCombat(SpellGroup, SpellTimer, TimerTable);
	for i = 1, 10, 1 do
		local frameName = "NecrosisTarget"..i.."Text";
		local frameItem = getglobal(frameName);
		if frameItem:IsShown() then
			frameItem:Hide();
		end
	end
end

local function Necrosis_OnSpellcastStartEvent(_, spellName)
	Necrosis_OnSpellcastStart(spellName);
end

local function Necrosis_OnTradeRequestEvent()
	Necrosis_SetTradeRequest(true);
end

local function Necrosis_OnTradeCancelledEvent()
	Necrosis_SetTradeRequest(false);
end

local function Necrosis_OnSelfDamageEvent(_, message)
	Necrosis_HandleSelfFearDamage(message);
end

local function Necrosis_OnUnitPetEvent(_, unitId)
	if unitId == "player" then
		Necrosis_ChangeDemon();
	end
end

local function Necrosis_OnBuffEvent()
	Necrosis_SelfEffect("BUFF");
end

local function Necrosis_OnDebuffEvent()
	Necrosis_SelfEffect("DEBUFF");
end

local function Necrosis_OnCombatStartEvent()
	PlayerCombat = true;
end


local NECROSIS_EVENT_HANDLERS = {
	BAG_UPDATE = Necrosis_OnBagUpdate,
	SPELLCAST_START = Necrosis_OnSpellcastStartEvent,
	SPELLCAST_STOP = Necrosis_SpellManagement,
	SPELLCAST_FAILED = Necrosis_ClearSpellcastContext,
	SPELLCAST_INTERRUPTED = Necrosis_ClearSpellcastContext,
	TRADE_REQUEST = Necrosis_OnTradeRequestEvent,
	TRADE_SHOW = Necrosis_OnTradeRequestEvent,
	TRADE_REQUEST_CANCEL = Necrosis_OnTradeCancelledEvent,
	TRADE_CLOSED = Necrosis_OnTradeCancelledEvent,
	PLAYER_TARGET_CHANGED = Necrosis_OnTargetChanged,
	CHAT_MSG_SPELL_SELF_DAMAGE = Necrosis_OnSelfDamageEvent,
	LEARNED_SPELL_IN_TAB = Necrosis_OnSpellLearned,
	PLAYER_REGEN_ENABLED = Necrosis_OnCombatEnd,
	PLAYER_REGEN_DISABLED = Necrosis_OnCombatStartEvent,
	UNIT_PET = Necrosis_OnUnitPetEvent,
	CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = Necrosis_OnBuffEvent,
	CHAT_MSG_SPELL_AURA_GONE_SELF = Necrosis_OnDebuffEvent,
	CHAT_MSG_SPELL_BREAK_AURA = Necrosis_OnDebuffEvent,
};

local function Necrosis_RegisterSpecialFrame(frameName)
	if not UISpecialFrames then
		UISpecialFrames = {};
	end
	for index = 1, table.getn(UISpecialFrames), 1 do
		if UISpecialFrames[index] == frameName then
			return;
		end
	end
	table.insert(UISpecialFrames, frameName);
end

-- Menus: Enables display of the buff and pet menus
local PetShow = false;
local PetMenuShow = false;
local BuffShow = false;
local BuffMenuShow = false;
local CurseShow = false;
local CurseMenuShow = false;
local StoneShow = false;
local StoneMenuShow = false;

-- Menus: Handles fading out the pet menu (transparency)
local AlphaPetMenu = 1;
local AlphaPetVar = 0;
local PetVisible = false;

-- Menus: Handles fading out the buff menu (transparency)
local AlphaBuffMenu = 1;
local AlphaBuffVar = 0;
local BuffVisible = false;

-- Menus: Handles fading out the curse menu (transparency)
local AlphaCurseMenu = 1;
local AlphaCurseVar = 0;
local CurseVisible = false;

-- Menus: Handles fading out the stone menu (transparency)
local AlphaStoneMenu = 1;
local AlphaStoneVar = 0;
local StoneVisible = false;

-- Menus: Allows recasting the last menu spell with a middle click
local LastDemon = 0;
local LastBuff = 0;
local LastCurse = 0;
local LastCurseClick = "LeftButton";
local LastStone = 0;
local LastStoneClick = "LeftButton";

-- List of buttons available to the Warlock in each menu
local PetMenuCreate = {};
local BuffMenuCreate = {};
local CurseMenuCreate = {};
local StoneMenuCreate = {};

-- Variables used to manage mounts
local MountAvailable = false;
local NecrosisMounted = false;
local NecrosisTellMounted = true;
local PlayerCombat = false;

-- Variables used to manage Shadow Trance
local ShadowTrance = false;
local AntiFearInUse = false;
local ShadowTranceID = -1;

-- Variables used to manage soul shards
-- (primarily counting)
local Soulshards = 0;
local SoulshardContainer = 4;
local SoulshardSlot = {};
local SoulshardSlotID = 1;
local SoulshardMP = 0;
local SoulshardTime = 0;

-- Variables used to manage summoning components
-- (primarily counting)
local InfernalStone = 0;
local DemoniacStone = 0;


-- Variables used to manage stone summon and usage buttons
local StoneIDInSpellTable = {0, 0, 0, 0, 0, 0, 0}
-- Indices used for NecrosisConfig.StonePosition
StonePosHealthstone = 1;
StonePosSpellstone = 2;
StonePosSoulstone = 3;
StonePosBuffMenu = 4;
StonePosMount = 5;
StonePosPetMenu = 6;
StonePosCurseMenu = 7;
StonePosStoneMenu = 8;
local SoulstoneUsedOnTarget = false;
local SoulstoneOnHand = false;
local SoulstoneLocation = {nil,nil};
local SoulstoneMode = 1;
local HealthstoneOnHand = false;
local HealthstoneLocation = {nil,nil};
local HealthstoneMode = 1;
local FirestoneOnHand = false;
local FirestoneLocation = {nil,nil};
local FirestoneMode = 1;
local SpellstoneOnHand = false;
local SpellstoneLocation = {nil,nil};
local SpellstoneMode = 1;
local FelstoneOnHand = false;
local FelstoneLocation = {nil,nil};
local FelstoneMode = 1;
local WrathstoneOnHand = false;
local WrathstoneLocation = {nil,nil};
local WrathstoneMode = 1;
local VoidstoneOnHand = false;
local VoidstoneLocation = {nil,nil};
local VoidstoneMode = 1;
local HearthstoneOnHand = false;
local HearthstoneLocation = {nil,nil};
local ItemswitchLocation = {nil,nil};
local ItemOnHand = false;

-- Variables controlling whether a resurrection timer can be used
local SoulstoneWaiting = false;
local SoulstoneCooldown = false;
local SoulstoneAdvice = false;
local SoulstoneTarget = "";

-- Variables used for demon management
local DemonType = nil;
local DemonEnslaved = false;

-- Variables used for anti-fear handling
local AFblink1, AFBlink2 = 0;
local AFImageType = { "", "Immu", "Prot"}; -- Fear warning button filename variations
local AFCurrentTargetImmune = false;

-- Variables used for trading stones with players
local NecrosisTradeRequest = false;
local Trading = false;
local TradingNow = 0;

-- Manage soul shard bags
local BagIsSoulPouch = {nil, nil, nil, nil, nil};

-- Store the last summon messages
local PetMess = 0
local SteedMess = 0
local RezMess = 0
local TPMess = 0

-- Manages tooltips in Necrosis (excluding the coin frame)
local lOriginal_GameTooltip_ClearMoney;

local Necrosis_In = true;

------------------------------------------------------------------------------------------------------
-- FONCTIONS NECROSIS APPLIQUEES A L'ENTREE DANS LE JEU
------------------------------------------------------------------------------------------------------


-- Function executed during load
function Necrosis_OnLoad()
	
	-- Allows tracking which spells are cast
	Necrosis_Hook("UseAction", "Necrosis_UseAction", "before");
	Necrosis_Hook("CastSpell", "Necrosis_CastSpell", "before");
	Necrosis_Hook("CastSpellByName", "Necrosis_CastSpellByName", "before");
	
	-- Register the events intercepted by Necrosis
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("PLAYER_LEAVING_WORLD");
	
	for eventName in pairs(NECROSIS_EVENT_HANDLERS) do
		NecrosisButton:RegisterEvent(eventName);
	end

	Necrosis_RegisterSpecialFrame("NecrosisGeneralFrame");

	-- Register graphical components
	NecrosisButton:RegisterForDrag("LeftButton");
	NecrosisButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	NecrosisButton:SetFrameLevel(1);

	-- Enregistrement de la commande console
	SlashCmdList["NecrosisCommand"] = Necrosis_SlashHandler;
	SLASH_NecrosisCommand1 = "/necro";
end


-- Function executed after addon variables are loaded
function Necrosis_LoadVariables()
	if Loaded or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end
	
	Necrosis_Initialize();
	Loaded = true ;

	-- Detect the demon type when logging in
	DemonType = UnitCreatureFamily("pet");
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS NECROSIS
------------------------------------------------------------------------------------------------------

local textTimersDisplay = "";

-- Function executed on UI updates (roughly every 0.1 seconds)
function Necrosis_OnUpdate()

	-- The function is only used if Necrosis is initialized and the player is a Warlock --
	if (not Loaded) and UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return;
	end
	-- The function is only used if Necrosis is initialized and the player is a Warlock --

	
	-- Soul shard handling: sort shards once per second
	local curTime = GetTime();
	if ((curTime-SoulshardTime) >= 1) then
		SoulshardTime = curTime;
		if (SoulshardMP > 0) then
			Necrosis_SoulshardSwitch("MOVE");
		end
	end

	----------------------------------------------------------
	-- Manage Warlock spells
	----------------------------------------------------------
	
	-- Manage the demon summon menu
	if PetShow then
		if curTime >= AlphaPetVar and AlphaPetMenu > 0 and (not PetVisible) then
			AlphaPetVar = curTime + 0.1;
			Necrosis_SetMenuAlpha("NecrosisPetMenu", AlphaPetMenu);
			AlphaPetMenu = AlphaPetMenu - 0.1;
		end
		if AlphaPetMenu <= 0 then
			Necrosis_PetMenu();
		end
	end

	-- Gestion du menu des Buffs
	if BuffShow then
		if curTime >= AlphaBuffVar and AlphaBuffMenu > 0 and (not BuffVisible) then
			AlphaBuffVar = curTime + 0.1;
			Necrosis_SetMenuAlpha("NecrosisBuffMenu", AlphaBuffMenu);
			AlphaBuffMenu = AlphaBuffMenu - 0.1;
		end
		if AlphaBuffMenu <= 0 then
			Necrosis_BuffMenu();
		end
	end

	-- Gestion du menu des Curses
	if CurseShow then
		if curTime >= AlphaCurseVar and AlphaCurseMenu > 0 and (not CurseVisible) then
			AlphaCurseVar = curTime + 0.1;
			Necrosis_SetMenuAlpha("NecrosisCurseMenu", AlphaCurseMenu);
			AlphaCurseMenu = AlphaCurseMenu - 0.1;
		end
		if AlphaCurseMenu <= 0 then
			Necrosis_CurseMenu();
		end
	end
	
	-- Manage the Nightfall talent
	if NecrosisConfig.ShadowTranceAlert then
		local Actif = false;
		local TimeLeft = 0;
		Necrosis_UnitHasTrance();
   		if ShadowTranceID ~= -1 then Actif = true; end
		if Actif and not ShadowTrance then
			ShadowTrance = true;
			Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.Message, "USER");
			if NecrosisConfig.Sound then PlaySoundFile(NECROSIS_SOUND.ShadowTrance); end
			local ShadowTranceIndex, cancel = GetPlayerBuff(ShadowTranceID,"HELPFUL|HARMFUL|PASSIVE");
			TimeLeft = floor(GetPlayerBuffTimeLeft(ShadowTranceIndex));
			NecrosisShadowTranceTimer:SetText(TimeLeft);
			ShowUIPanel(NecrosisShadowTranceButton);
		end
		if not Actif and ShadowTrance then
			HideUIPanel(NecrosisShadowTranceButton);
			ShadowTrance = false;
		end
		if Actif and ShadowTrance then
			local ShadowTranceIndex, cancel = GetPlayerBuff(ShadowTranceID,"HELPFUL|HARMFUL|PASSIVE");
			TimeLeft = floor(GetPlayerBuffTimeLeft(ShadowTranceIndex));
			NecrosisShadowTranceTimer:SetText(TimeLeft);
		end
	end

	-- Gestion des Antifears
	if NecrosisConfig.AntiFearAlert then
		local Actif = false; -- must be False, or a number from 1 to AFImageType[] max element.
		
		-- Checking if we have a target. Any fear need a target to be casted on
		if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
			-- Checking if the target has natural immunity (only NPC target)
			if not UnitIsPlayer("target") then 				
				for index=1, table.getn(NECROSIS_ANTI_FEAR_UNIT), 1 do
					if (UnitCreatureType("target") == NECROSIS_ANTI_FEAR_UNIT[index] ) then
						Actif = 2; -- Immun
						break;
					end
				end
			end
				
			-- We'll start to parse the target buffs, as his class doesn't give him natural permanent immunity
			if not Actif then
				for index=1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Buff), 1 do
					if Necrosis_UnitHasBuff("target",NECROSIS_ANTI_FEAR_SPELL.Buff[index]) then
						Actif = 3; -- Prot
						break;
					end
				end
				
				-- No buff found, let's try the debuffs
				for index=1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Debuff), 1 do
					if Necrosis_UnitHasEffect("target",NECROSIS_ANTI_FEAR_SPELL.Debuff[index]) then
						Actif = 3; -- Prot
						break;
					end
				end
			end
			
			-- an immunity has been detected before, but we still don't know why => show the button anyway
			if AFCurrentTargetImmune and not Actif then 
				Actif = 1;	
			end
		end
		
		if Actif then
			-- Antifear button is currently not visible, we have to change that
			if not AntiFearInUse then
				AntiFearInUse = true;
				Necrosis_Msg(NECROSIS_MESSAGE.Information.FearProtect, "USER");
				NecrosisAntiFearButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\AntiFear"..AFImageType[Actif].."-02");
				if NecrosisConfig.Sound then PlaySoundFile(NECROSIS_SOUND.Fear); end
				ShowUIPanel(NecrosisAntiFearButton);
				AFBlink1 = curTime + 0.6;
				AFBlink2 = 2;
			
			-- Timer to make the button blink
			elseif curTime >= AFBlink1 then
				if AFBlink2 == 1 then
					AFBlink2 = 2;
				else
					AFBlink2 = 1;
				end
				AFBlink1 = curTime + 0.4;
				NecrosisAntiFearButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\AntiFear"..AFImageType[Actif].."-0"..AFBlink2);
			end
			
		elseif AntiFearInUse then	-- No antifear on target, but the button is still visible => gonna hide it
			AntiFearInUse = false;
			HideUIPanel(NecrosisAntiFearButton);
		end
	end

	-- Gestion du Timer des sorts
	if (not NecrosisSpellTimerButton:IsVisible()) then
		ShowUIPanel(NecrosisSpellTimerButton);
	end
	
	if NecrosisConfig.CountType == 3 then
		NecrosisShardCount:SetText("");
	end
	local update = false;
	if ((curTime - SpellCastTime) >= 1) then
		SpellCastTime = curTime;
		update = true;
	end
	
	-- Refresh the buttons every second
	-- On accepte le trade de la pierre de soin si transfert en cours
	if update then
		if Trading then
			TradingNow = TradingNow - 1;
			if TradingNow == 0 then
				AcceptTrade();
				Trading = false;
			end
		end
		Necrosis_UpdateIcons();
	end
	
	-- Parcours du tableau des Timers
	if SpellTimer then
		if update then
			clear_tables(GraphicalTimer);
			textTimersDisplay = "";
			for index = 1, table.getn(SpellTimer), 1 do
				if SpellTimer[index] then
					if (GetTime() <= SpellTimer[index].TimeMax) then
						-- Build the timer display
						textTimersDisplay, SpellGroup, GraphicalTimer, TimerTable = Necrosis_DisplayTimer(textTimersDisplay, index, SpellGroup, SpellTimer, GraphicalTimer, TimerTable);
					end
					-- Remove finished timers
					if curTime >= (SpellTimer[index].TimeMax - 0.5) and SpellTimer[index].TimeMax ~= -1 then
						-- If the timer was for the Soulstone, notify the Warlock
						if SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name then
							Necrosis_Msg(NECROSIS_MESSAGE.Information.SoulstoneEnd, "USER");
							SpellTimer[index].Target = "";
							SpellTimer[index].TimeMax = -1;
							if NecrosisConfig.Sound then PlaySoundFile(NECROSIS_SOUND.SoulstoneEnd); end
							Necrosis_RemoveFrame(SpellTimer[index].Gtimer, TimerTable);
								-- Update the Soulstone button appearance
							Necrosis_UpdateIcons();
						-- Otherwise remove the timer quietly (except for Enslave)
						elseif SpellTimer[index].Name ~= NECROSIS_SPELL_TABLE[10].Name then
							SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(index, SpellTimer, TimerTable);
							index = 0;
							break;
						end
					end
					-- If the Warlock is no longer affected by Demon Sacrifice
					if SpellTimer and SpellTimer[index].Name == NECROSIS_SPELL_TABLE[17].Name then -- Sacrifice
						if not Necrosis_UnitHasEffect("player", SpellTimer[index].Name) and SpellTimer[index].TimeMax ~= nil then
							SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(index, SpellTimer, TimerTable);
							index = 0;
							break;
						end
					end
					-- If the targeted unit is no longer affected by the spell (resist)
					if SpellTimer and (SpellTimer[index].Type == 4 or SpellTimer[index].Type == 5)
						and SpellTimer[index].Target == UnitName("target")
						then
						-- Cheat a little to let the mob fully register the debuff ^^
						if curTime >= ((SpellTimer[index].TimeMax - SpellTimer[index].Time) + 1.5)
							and SpellTimer[index] ~= 6 then
							if not Necrosis_UnitHasEffect("target", SpellTimer[index].Name) then
								SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(index, SpellTimer, TimerTable);
								index = 0;
								break;
							end
						end
					end
				end
			end
		end
	else
		for i = 1, 10, 1 do
			local frameName = "NecrosisTarget"..i.."Text";
			local frameItem = getglobal(frameName);
			if frameItem:IsShown() then
				frameItem:Hide();
			end
		end
	end

	if NecrosisConfig.ShowSpellTimers or NecrosisConfig.Graphical then
		-- Si affichage de timer texte
		if not NecrosisConfig.Graphical then
			-- Color the textual timer display
			textTimersDisplay = Necrosis_MsgAddColor(textTimersDisplay);
			-- Affichage des timers
			NecrosisListSpells:SetText(textTimersDisplay);
		else
			NecrosisListSpells:SetText("");			
		end
		for i = 4, table.getn(SpellGroup.Name) do
			SpellGroup.Visible[i] = false;
		end
	else
		if (NecrosisSpellTimerButton:IsVisible()) then
			NecrosisListSpells:SetText("");
			HideUIPanel(NecrosisSpellTimerButton);
		end
	end
end

-- Function triggered for each intercepted event
function Necrosis_OnEvent(event)
	if (event == "PLAYER_ENTERING_WORLD") then
		Necrosis_In = true;
		return;
	elseif (event == "PLAYER_LEAVING_WORLD") then
		Necrosis_In = false;
		return;
	end

	if (not Loaded) or (not Necrosis_In) or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then 
		return;
	end

	local handler = NECROSIS_EVENT_HANDLERS[event];
	if handler then
		handler(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
	end
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS NECROSIS "ON EVENT"
------------------------------------------------------------------------------------------------------

function Necrosis_ChangeDemon()
	-- If the new demon is enslaved, start a five-minute timer
	if (Necrosis_UnitHasEffect("pet", NECROSIS_SPELL_TABLE[10].Name)) then
		if (not DemonEnslaved) then
			DemonEnslaved = true;
			SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerParTable(10, "","", SpellGroup, SpellTimer, TimerTable);
		end
	else
		-- When the enslaved demon breaks free, remove the timer and warn the Warlock
		if (DemonEnslaved) then
			DemonEnslaved = false;
			SpellTimer, TimerTable = Necrosis_RetraitTimerParNom(NECROSIS_SPELL_TABLE[10].Name, SpellTimer, TimerTable);
			if NecrosisConfig.Sound then PlaySoundFile(NECROSIS_SOUND.EnslaveEnd); end
			Necrosis_Msg(NECROSIS_MESSAGE.Information.EnslaveBreak, "USER");
		end
	end
	
	-- If the demon is not enslaved, assign its title and update its name in Necrosis
	DemonType = UnitCreatureFamily("pet");
	for i = 1, 4, 1 do
		if DemonType == NECROSIS_PET_LOCAL_NAME[i] and NecrosisConfig.PetName[i] == " " and UnitName("pet") ~= UNKNOWNOBJECT then
			NecrosisConfig.PetName[i] = UnitName("pet");
			NecrosisLocalization();
			break;
		end
	end

	return;
end

-- events: CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS, CHAT_MSG_SPELL_AURA_GONE_SELF, and CHAT_MSG_SPELL_BREAK_AURA
-- Handles buffs and debuffs appearing on the Warlock
-- Based on the combat log
function Necrosis_SelfEffect(action)
	if action == "BUFF" then
		-- Insert a timer when the Warlock gains Demon Sacrifice
		if arg1 == NECROSIS_TRANSLATION.SacrificeGain then
			SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerParTable(17, "", "", SpellGroup, SpellTimer, TimerTable);
		end
		-- Update the mount button when the Warlock mounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or  string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			NecrosisMounted = true;
			if NecrosisConfig.SteedSummon and NecrosisTellMounted
				and NecrosisConfig.ChatMsg and NECROSIS_PET_MESSAGE[6] and not NecrosisConfig.SM
				then
					local mountMessages = NECROSIS_PET_MESSAGE[6];
					local messageCount = table.getn(mountMessages);
					if messageCount > 0 then
						local tempnum = random(1, messageCount);
						if messageCount >= 2 then
							while tempnum == SteedMess do
								tempnum = random(1, messageCount);
							end
						end
						SteedMess = tempnum;
						local lines = mountMessages[tempnum];
						local lineCount = table.getn(lines);
						for i = 1, lineCount, 1 do
							Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY");
						end
						NecrosisTellMounted = false;
					end
			end
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 2);
			
		end
		-- Update the Corrupted Domination button when active and start the cooldown timer
		if  string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = true;
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 2);
		end
		-- Update the Amplify Curse button when active and start the cooldown timer
		if  string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = true;
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 2);
		end
	else
		-- Update the mount button when the Warlock dismounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or  string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			NecrosisMounted = false;
			NecrosisTellMounted = true;
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1);
		end
		-- Change the Domination button when the Warlock is no longer under its effect
		if  string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = false;
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 1);
		end
		-- Change the Amplify Curse button when the Warlock leaves its effect
		if  string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = false;
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 1);
		end
	end
	return;
end

-- event : SPELLCAST_STOP
-- Handles everything related to spells after they finish casting
function Necrosis_SpellManagement()
	local SortActif = false;
	if (SpellCastName) then
		-- If the spell was Soulstone Resurrection, start its timer
		if (SpellCastName == NECROSIS_SPELL_TABLE[11].Name) then
			if SpellTargetName == UnitName("player") then
				SpellTargetName = "";
			end
			-- If messaging is enabled and the stone is used on the targeted player, broadcast the alert!
			if (NecrosisConfig.ChatMsg or NecrosisConfig.SM)
				and SoulstoneUsedOnTarget then
					SoulstoneTarget = SpellTargetName;
					SoulstoneAdvice = true;
			end
			SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerParTable(11, SpellTargetName, "", SpellGroup, SpellTimer, TimerTable);
		-- If the spell was Ritual of Summoning, send an informational message to players
		elseif (SpellCastName == NECROSIS_TRANSLATION.SummoningRitual)
			and (NecrosisConfig.ChatMsg or NecrosisConfig.SM)
			and NecrosisConfig.RitualMessage
			and NECROSIS_INVOCATION_MESSAGES then
				local ritualMessages = NECROSIS_INVOCATION_MESSAGES;
				local ritualCount = table.getn(ritualMessages);
				if ritualCount > 0 then
					local tempnum = random(1, ritualCount);
					if ritualCount >= 2 then
						while tempnum == TPMess do
							tempnum = random(1, ritualCount);
						end
					end
					TPMess = tempnum;
					local lines = ritualMessages[tempnum];
					local lineCount = table.getn(lines);
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i], SpellTargetName), "WORLD");
					end
				end
		elseif StoneIDInSpellTable[5] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Name then -- Create Felstone
			LastStone = 1
			LastStoneClick = "LeftButton"
		elseif StoneIDInSpellTable[6] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Name then -- Create Wrathstone
			LastStone = 2
			LastStoneClick = "LeftButton"
		elseif StoneIDInSpellTable[7] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Name then -- Create Voidstone
			LastStone = 3
			LastStoneClick = "LeftButton"
		elseif StoneIDInSpellTable[4] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Name then -- Create Firestone
			LastStone = 4
			LastStoneClick = "LeftButton"
		-- For other spells, attempt to create a timer if applicable
		else
			for spell=1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if SpellCastName == NECROSIS_SPELL_TABLE[spell].Name and not (spell == 10) then
					-- If the timer already exists on the target, refresh it
					for thisspell=1, table.getn(SpellTimer), 1 do
						if SpellTimer[thisspell].Name == SpellCastName
							and SpellTimer[thisspell].Target == SpellTargetName
							and SpellTimer[thisspell].TargetLevel == SpellTargetLevel
							and NECROSIS_SPELL_TABLE[spell].Type ~= 4
							and spell ~= 16
							then
							-- If the spell is already active on the mob, reset its timer
							if spell ~= 9 or (spell == 9 and not Necrosis_UnitHasEffect("target", SpellCastName)) then
								SpellTimer[thisspell].Time = NECROSIS_SPELL_TABLE[spell].Length;
								SpellTimer[thisspell].TimeMax = floor(GetTime() + NECROSIS_SPELL_TABLE[spell].Length);
								if spell == 9 and SpellCastRank == 1 then
									SpellTimer[thisspell].Time = 20;
									SpellTimer[thisspell].TimeMax = floor(GetTime() + 20);
								end
							end
							SortActif = true;
							break;
						end
						-- If Banish hits a new target, remove the previous timer
						if SpellTimer[thisspell].Name == SpellCastName and spell == 9
							and
								(SpellTimer[thisspell].Target ~= SpellTargetName
								or SpellTimer[thisspell].TargetLevel ~= SpellTargetLevel)
							then
							SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(thisspell, SpellTimer, TimerTable);
							SortActif = false;
							break;
						end	
						
						-- If it is a fear, remove the previous fear timer
						if SpellTimer[thisspell].Name == SpellCastName and spell == 13 then
							SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(thisspell, SpellTimer, TimerTable);
							SortActif = false;
							break;
						end
						if SortActif then break; end
					end
					-- If the timer is for a curse, remove the previous curse timer on the target
					if (NECROSIS_SPELL_TABLE[spell].Type == 4) or (spell == 16) then
						for thisspell=1, table.getn(SpellTimer), 1 do
							-- But keep the Curse of Doom cooldown
							if SpellTimer[thisspell].Name == NECROSIS_SPELL_TABLE[16].Name then
								SpellTimer[thisspell].Target = "";
								SpellTimer[thisspell].TargetLevel = "";
							end
							if SpellTimer[thisspell].Type == 4
								and SpellTimer[thisspell].Target == SpellTargetName
								and SpellTimer[thisspell].TargetLevel == SpellTargetLevel
								then
								SpellTimer, TimerTable = Necrosis_RetraitTimerParIndex(thisspell, SpellTimer, TimerTable);
								break;
							end
						end
						SortActif = false;
					end
					if not SortActif
						and NECROSIS_SPELL_TABLE[spell].Type ~= 0
						and spell ~= 10
						then
							
						if spell == 9 then 
							if SpellCastRank == 1 then
								NECROSIS_SPELL_TABLE[spell].Length = 20;
							else
								NECROSIS_SPELL_TABLE[spell].Length = 30;
							end
						end
		
						SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerParTable(spell, SpellTargetName, SpellTargetLevel, SpellGroup, SpellTimer, TimerTable);
						break;
					end
				end
			end
		end
	end
	SpellCastName = nil;
	SpellCastRank = nil;
	return;
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS DE L'INTERFACE -- LIENS XML
------------------------------------------------------------------------------------------------------

-- Right-clicking Necrosis toggles both configuration panels
function Necrosis_Toggle(button)
	if button == "LeftButton" then
		if NECROSIS_SPELL_TABLE[41].ID then
			CastSpell(NECROSIS_SPELL_TABLE[41].ID, "spell");
		end
		return;
	elseif (NecrosisGeneralFrame:IsVisible()) then
		HideUIPanel(NecrosisGeneralFrame);
		return;
	else
		if NecrosisConfig.SM then
			Necrosis_Msg("!!! Short Messages : <brightGreen>On", "USER");
		end
		ShowUIPanel(NecrosisGeneralFrame);
		NecrosisGeneralTab_OnClick(1);
		return;
	end
end

-- Function that lets Necrosis elements be moved on screen
function Necrosis_OnDragStart(button)
	if (button == "NecrosisIcon") then GameTooltip:Hide(); end
	button:StartMoving();
end

-- Function that stops moving Necrosis elements on screen
function Necrosis_OnDragStop(button)
	if (button == "NecrosisIcon") then Necrosis_BuildTooltip("OVERALL"); end
	button:StopMovingOrSizing();
end

-- Function that toggles between graphical and text timers
function Necrosis_HideGraphTimer()
	for i = 1, 50, 1 do
		local elements = {"Text", "Bar", "Texture", "OutText"}
		if NecrosisConfig.Graphical then
			if TimerTable[i] then
				for j = 1, 4, 1 do
					frameName = "NecrosisTimer"..i..elements[j];
					frameItem = getglobal(frameName);
					frameItem:Show();
				end
			end
		else
			for j = 1, 4, 1 do
				frameName = "NecrosisTimer"..i..elements[j];
				frameItem = getglobal(frameName);
				frameItem:Hide();
			end
		end
	end
end

-- Function that manages tooltips
function Necrosis_BuildTooltip(button, type, anchor)

	-- If tooltips are disabled, exit immediately!
	if not NecrosisConfig.NecrosisToolTip then
		return;
	end
	
	-- Check whether Fel Domination, Shadow Ward, or Curse Amplification are active (for tooltips)
	local start, duration, start2, duration2, start3, duration3
	if NECROSIS_SPELL_TABLE[15].ID then
		start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, BOOKTYPE_SPELL);
	else
		start = 1;
		duration = 1;
	end
	if NECROSIS_SPELL_TABLE[43].ID then
		start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, BOOKTYPE_SPELL);
	else
		start2 = 1;
		duration2 = 1;
	end
	if NECROSIS_SPELL_TABLE[42].ID then
		start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, BOOKTYPE_SPELL);
	else
		start3 = 1;
		duration3 = 1;
	end

	-- Create the tooltips....
	GameTooltip:SetOwner(button, anchor);
	GameTooltip:SetText(NecrosisTooltipData[type].Label);
	-- ..... for the main button
	if (type == "Main") then
		GameTooltip:AddLine(NecrosisTooltipData.Main.Soulshard..Soulshards);
		GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone..InfernalStone);
		GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone..DemoniacStone);
		GameTooltip:AddLine(NecrosisTooltipData.Main.Soulstone..NecrosisTooltipData[type].Stone[SoulstoneOnHand]);
		GameTooltip:AddLine(NecrosisTooltipData.Main.Healthstone..NecrosisTooltipData[type].Stone[HealthstoneOnHand]);
		-- Display the demon's name, show if it is enslaved, or "None" when no demon is present
		if (DemonType) then
			GameTooltip:AddLine(NecrosisTooltipData.Main.CurrentDemon..DemonType);
		elseif DemonEnslaved then
			GameTooltip:AddLine(NecrosisTooltipData.Main.EnslavedDemon);
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.NoCurrentDemon);
		end
	-- ..... for the stone buttons
	elseif (string.find(type, "stone")) then
		-- Soulstone
		if (type == "Soulstone") then
			-- On affiche le nom de la pierre et l'action que produira le clic sur le bouton
			-- Also grab the cooldown
			if SoulstoneMode == 1 or SoulstoneMode == 3 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(SoulstoneLocation[1], SoulstoneLocation[2]);
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText());
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[SoulstoneMode]);
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName);
			end
		-- Pierre de vie
		elseif (type == "Spellstone") then
			-- Idem
			if SpellstoneMode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(SpellstoneLocation[1], SpellstoneLocation[2]);
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[SpellstoneMode]);
			local itemName = tostring(NecrosisTooltipTextLeft7:GetText());
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName);
			end
		elseif (type == "Healthstone") then
			-- Idem
			if HealthstoneMode == 1 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(HealthstoneLocation[1], HealthstoneLocation[2]);
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText());
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[HealthstoneMode]);
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName);
			end
		-- Pierre de feu
		elseif (type == "Firestone") then
			if FirestoneMode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(FirestoneLocation[1], FirestoneLocation[2]);
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[FirestoneMode]);
		elseif (type == "Felstone") then
			if FelstoneMode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(FelstoneLocation[1], FelstoneLocation[2]);
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[FelstoneMode]);
		elseif (type == "Wrathstone") then
			if WrathstoneMode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(WrathstoneLocation[1], WrathstoneLocation[2]);
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[WrathstoneMode]);
		elseif (type == "Voidstone") then
			if VoidstoneMode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Mana.." Mana");
			end
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(VoidstoneLocation[1], VoidstoneLocation[2]);
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[VoidstoneMode]);
		end
	-- ..... for the timer button
	elseif (type == "SpellTimer") then
		Necrosis_MoneyToggle();
		NecrosisTooltip:SetBagItem(HearthstoneLocation[1], HearthstoneLocation[2]);
		local itemName = tostring(NecrosisTooltipTextLeft5:GetText());
		GameTooltip:AddLine(NecrosisTooltipData[type].Text);
		if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
			GameTooltip:AddLine(NECROSIS_TRANSLATION.Hearth.." - "..itemName);
		else
			GameTooltip:AddLine(NecrosisTooltipData[type].Right..GetBindLocation());
		end
		
	-- ..... for the Shadow Trance button
	elseif (type == "ShadowTrance") then
		local rank = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "Rank");
		GameTooltip:SetText(NecrosisTooltipData[type].Label.."          |CFF808080Rank "..rank.."|r");
	-- ..... for the other buffs and demons, the mana cost...
	elseif (type == "Enslave") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[35].Mana.." Mana");
		if Soulshards == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.Soulshard..Soulshards.."|r");
		end
	elseif (type == "Mount") then
		if NECROSIS_SPELL_TABLE[2].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[2].Mana.." Mana");
		elseif NECROSIS_SPELL_TABLE[1].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[1].Mana.." Mana");
		end
	elseif (type == "Armor") then
		if NECROSIS_SPELL_TABLE[31].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[31].Mana.." Mana");
		else
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[36].Mana.." Mana");
		end
	elseif (type == "Invisible") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[33].Mana.." Mana");
	elseif (type == "Aqua") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[32].Mana.." Mana");
	elseif (type == "Kilrogg") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[34].Mana.." Mana");
	elseif (type == "Banish") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[9].Mana.." Mana");
	elseif (type == "Weakness") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[23].Mana.." Mana");
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown);
		end
	elseif (type == "Agony") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[22].Mana.." Mana");
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown);
		end
	elseif (type == "Reckless") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[24].Mana.." Mana");
	elseif (type == "Tongues") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[25].Mana.." Mana");
	elseif (type == "Exhaust") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[40].Mana.." Mana");
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown);
		end
	elseif (type == "Elements") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[26].Mana.." Mana");
	elseif (type == "Shadow") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[27].Mana.." Mana");
	elseif (type == "Doom") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[16].Mana.." Mana");
	elseif (type == "Amplify") then
		if start3 > 0 and duration3 > 0 then
			local seconde = duration3 - ( GetTime() - start3)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)).." sec";
			else
				minute = tostring(floor(seconde/60))
				seconde = mod(seconde, 60);
				if seconde <= 9 then
					time = "0"..tostring(floor(seconde));
				else
					time = tostring(floor(seconde));
				end
				affiche = minute..":"..time;
			end
			GameTooltip:AddLine("Cooldown : "..affiche);
		end
	elseif (type == "TP") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[37].Mana.." Mana");
		if Soulshards == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.Soulshard..Soulshards.."|r");
		end
	elseif (type == "SoulLink") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[38].Mana.." Mana");
	elseif (type == "ShadowProtection") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[43].Mana.." Mana");
		if start2 > 0 and duration2 > 0 then
			local seconde = duration2 - ( GetTime() - start2)
			local affiche
			affiche = tostring(floor(seconde)).." sec";
			GameTooltip:AddLine("Cooldown : "..affiche);
		end
	elseif (type == "Domination") then
		if start > 0 and duration > 0 then
			local seconde = duration - ( GetTime() - start)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)).." sec";
			else
				minute = tostring(floor(seconde/60))
				seconde = mod(seconde, 60);
				if seconde <= 9 then
					time = "0"..tostring(floor(seconde));
				else
					time = tostring(floor(seconde));
				end
				affiche = minute..":"..time;
			end
			GameTooltip:AddLine("Cooldown : "..affiche);
		end
	elseif (type == "Imp") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[3].Mana.." Mana");
		if not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown);
		end
			
	elseif (type == "Void") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[4].Mana.." Mana");
		if Soulshards == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.Soulshard..Soulshards.."|r");
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown);
		end
	elseif (type == "Succubus") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[5].Mana.." Mana");
		if Soulshards == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.Soulshard..Soulshards.."|r");
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown);
		end
	elseif (type == "Fel") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[6].Mana.." Mana");
		if Soulshards == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.Soulshard..Soulshards.."|r");
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown);
		end
	elseif (type == "Infernal") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[8].Mana.." Mana");
		if InfernalStone == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.InfernalStone..InfernalStone.."|r");
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone..InfernalStone);
		end
	elseif (type == "Doomguard") then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[30].Mana.." Mana");
		if DemoniacStone == 0 then
			GameTooltip:AddLine("|c00FF4444"..NecrosisTooltipData.Main.DemoniacStone..DemoniacStone.."|r");
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone..DemoniacStone);
		end
	elseif (type == "Buff") and LastBuff ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell..NECROSIS_SPELL_TABLE[LastBuff].Name);
	elseif (type == "Curse") and LastCurse ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell..NECROSIS_SPELL_TABLE[LastCurse].Name);
	elseif (type == "Pet") and LastDemon ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell..NECROSIS_PET_LOCAL_NAME[(LastDemon - 2)]);
	elseif (type == "Stone") and LastStone ~= 0 then
		local stoneName = ""
		local stoneOnHand = false
		if LastStone == 1 and FelstoneOnHand then
			stoneName = NECROSIS_ITEM.Felstone;
			stoneOnHand = true
		elseif LastStone == 2 and WrathstoneOnHand then
			stoneName = NECROSIS_ITEM.Wrathstone;
			stoneOnHand = true
		elseif LastStone == 3 and VoidstoneOnHand then
			stoneName = NECROSIS_ITEM.Voidstone;
			stoneOnHand = true
		elseif LastStone == 4 and FirestoneOnHand then
			stoneName = NECROSIS_ITEM.Firestone;
			stoneOnHand = true
		end
		if stoneOnHand then
			GameTooltip:AddLine(NecrosisTooltipData.LastSpell..stoneName);
		end
	end
	-- And tada, show it!
	GameTooltip:Show();
end

-- Function that refreshes Necrosis buttons and reports Soulstone button state
function Necrosis_UpdateIcons()
	local mana = UnitMana("player");

	if LastStone == 0 then
		if FelstoneOnHand then
			LastStone = 1;
		elseif WrathstoneOnHand then
			LastStone = 2;
		elseif VoidstoneOnHand then
			LastStone = 3;
		elseif FirestoneOnHand then
			LastStone = 4;
		end
	end

	if LastStone == 1 and FelstoneOnHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Felstone", 2);
	elseif LastStone == 2 and WrathstoneOnHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Wrathstone", 2);
	elseif LastStone == 3 and VoidstoneOnHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Voidstone", 2);
	elseif LastStone == 4 and FirestoneOnHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "FirestoneButton", 2);
	else
		NecrosisStoneMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-01");
	end

	-- Soulstone
	-----------------------------------------------
	
	-- Determine whether a Soulstone was used by checking timers
	local SoulstoneInUse = false;
	if SpellTimer then
		for index = 1, table.getn(SpellTimer), 1 do
			if (SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name)  and SpellTimer[index].TimeMax > 0 then
				SoulstoneInUse = true;
				break;
			end
		end
	end

	-- If the stone was not used and none are in the inventory -> mode 1
	if not (SoulstoneOnHand or SoulstoneInUse) then
		SoulstoneMode = 1;
		SoulstoneWaiting = false;
		SoulstoneCooldown = false;
	end

	-- If the stone was not used and one is in the inventory
	if SoulstoneOnHand and (not SoulstoneInUse) then
		-- If the stone in the inventory still has a timer and we just relogged --> mode 4
		local start, duration = GetContainerItemCooldown(SoulstoneLocation[1],SoulstoneLocation[2]);
		if NecrosisRL and start > 0 and duration > 0 then
			SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone("Soulstone", start, duration, SpellGroup, SpellTimer, TimerTable);
			SoulstoneMode = 4;
			NecrosisRL = false;
			SoulstoneWaiting = false;
			SoulstoneCooldown = true;
		-- If the stone has no timer or we didn't just relog --> mode 2
		else
			SoulstoneMode = 2;
			NecrosisRL = false;
			SoulstoneWaiting = false;
			SoulstoneCooldown = false;
		end
	end

	-- If the stone was consumed and none remain in the inventory --> mode 3
	if (not SoulstoneOnHand) and SoulstoneInUse then
		SoulstoneMode = 3;
		SoulstoneWaiting = true;
		-- If the stone was just applied, announce it to the raid
			if SoulstoneAdvice and NECROSIS_SOULSTONE_ALERT_MESSAGE then
				local alertMessages = NECROSIS_SOULSTONE_ALERT_MESSAGE;
				local alertCount = table.getn(alertMessages);
				if alertCount > 0 then
					local tempnum = random(1, alertCount);
					if alertCount >= 2 then
						while tempnum == RezMess do
							tempnum = random(1, alertCount);
						end
					end
					RezMess = tempnum;
					local lines = alertMessages[tempnum];
					local lineCount = table.getn(lines);
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i], SoulstoneTarget), "WORLD");
					end
					SoulstoneAdvice = false;
				end
			end
	end

	-- If the stone was consumed but another is in the inventory
	if SoulstoneOnHand and SoulstoneInUse then
			SoulstoneAdvice = false;
			if not (SoulstoneWaiting or SoulstoneCooldown) then
				SpellTimer, TimerTable = Necrosis_RetraitTimerParNom(NECROSIS_SPELL_TABLE[11].Name, SpellTimer, TimerTable);
				SoulstoneMode = 2;
			else
				SoulstoneWaiting = false;
				SoulstoneCooldown = true;
				SoulstoneMode = 4;
			end
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisSoulstoneButton, "SoulstoneButton", SoulstoneMode);

	-- Pierre de sort
	-----------------------------------------------
	
	if (SpellstoneOnHand) then
		SpellstoneMode = 2;
	else
		SpellstoneMode = 1;
	end
	
	Necrosis_SetButtonTexture(NecrosisSpellstoneButton, "SpellstoneButton", SpellstoneMode);

	-- Pierre de vie
	-----------------------------------------------

	-- Mode "j'en ai une" (2) / "j'en ai pas" (1)
	if (HealthstoneOnHand) then
		HealthstoneMode = 2;
	else
		HealthstoneMode = 1;
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisHealthstoneButton, "HealthstoneButton", HealthstoneMode);

	-- Demon button
	-----------------------------------------------
	local ManaPet = {"1", "1", "1", "1", "1", "1"};

	-- Si cooldown de domination corrompue on grise
	if NECROSIS_SPELL_TABLE[15].ID and not DominationUp then
		local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell");
		if start > 0 and duration > 0 then
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3);
		else
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 1);
		end
	end

	-- Si cooldown de gardien de l'ombre on grise
	if NECROSIS_SPELL_TABLE[43].ID then
		local start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, "spell");
		if start2 > 0 and duration2 > 0 then
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3);
		else
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1);
		end
	end

	-- Gray out the button while Amplify Curse is on cooldown
	if NECROSIS_SPELL_TABLE[42].ID and not AmplifyUp then
		local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell");
		if start3 > 0 and duration3 > 0 then
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3);
		else
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 1);
		end
	end

	if mana ~= nil then
	-- Grey out the button when there is not enough mana
		if NECROSIS_SPELL_TABLE[3].ID then
			if NECROSIS_SPELL_TABLE[3].Mana > mana then
				for i = 1, 6, 1 do
					ManaPet[i] = "3";
				end
			elseif NECROSIS_SPELL_TABLE[4].ID then
				if NECROSIS_SPELL_TABLE[4].Mana > mana then
					for i = 2, 6, 1 do
						ManaPet[i] = "3";
					end
				elseif NECROSIS_SPELL_TABLE[8].ID then
					if NECROSIS_SPELL_TABLE[8].Mana > mana then
						for i = 5, 6, 1 do
							ManaPet[i] = "3";
						end
					elseif NECROSIS_SPELL_TABLE[30].ID then
						if NECROSIS_SPELL_TABLE[30].Mana > mana then
							ManaPet[6] = "3";
						end
					end
				end
			end
		end
	end

	-- Grey out the button when no stone is available for the summon
	if Soulshards == 0 then
		for i = 2, 4, 1 do
			ManaPet[i] = "3";
		end
	end
	if InfernalStone == 0 then
		ManaPet[5] = "3";
	end
	if DemoniacStone == 0 then
		ManaPet[6] = "3";
	end
	
	-- Apply textures to the pet buttons
	if DemonType == NECROSIS_PET_LOCAL_NAME[1] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", 2);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[2] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", 2);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[3] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", 2);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[4] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", 2);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[5] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", 2);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[6] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", 2);
	else
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1]);
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2]);
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3]);
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4]);
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5]);
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6]);
	end 
		

	-- Buff button
	-----------------------------------------------
	
	if mana ~= nil then
	-- Grey out the button when there is not enough mana
		if MountAvailable and not NecrosisMounted then
			if NECROSIS_SPELL_TABLE[2].ID then
				if NECROSIS_SPELL_TABLE[2].Mana > mana or PlayerCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3);
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1);
				end
			else
				if NECROSIS_SPELL_TABLE[1].Mana > mana or PlayerCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3);
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1);
				end
			end
		end
		if NECROSIS_SPELL_TABLE[35].ID then
			if NECROSIS_SPELL_TABLE[35].Mana > mana or Soulshards == 0 then
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 3);
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[31].ID then
			if NECROSIS_SPELL_TABLE[31].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1);
			end
		elseif NECROSIS_SPELL_TABLE[36].ID then
			if NECROSIS_SPELL_TABLE[36].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[32].ID then
			if NECROSIS_SPELL_TABLE[32].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[33].ID then
			if NECROSIS_SPELL_TABLE[33].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[34].ID then
			if NECROSIS_SPELL_TABLE[34].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[37].ID then
			if NECROSIS_SPELL_TABLE[37].Mana > mana or Soulshards == 0 then
				NecrosisBuffMenu5:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\TPButton-05");
			else
				NecrosisBuffMenu5:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\TPButton-01");
			end
		end
		if NECROSIS_SPELL_TABLE[38].ID then
			if NECROSIS_SPELL_TABLE[38].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[43].ID then
			if NECROSIS_SPELL_TABLE[43].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[9].ID then
			if NECROSIS_SPELL_TABLE[9].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 3);
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[44].ID then
			if (not UnitExists("Pet")) then
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 3);
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 1);
			end
		end

	end

	-- Curse button
	-----------------------------------------------
	
	if mana ~= nil then
	-- Grey out the button when there is not enough mana
		if NECROSIS_SPELL_TABLE[23].ID then
			if NECROSIS_SPELL_TABLE[23].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[22].ID then
			if NECROSIS_SPELL_TABLE[22].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[24].ID then
			if NECROSIS_SPELL_TABLE[24].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[25].ID then
			if NECROSIS_SPELL_TABLE[25].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[40].ID then
			if NECROSIS_SPELL_TABLE[40].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[26].ID then
			if NECROSIS_SPELL_TABLE[26].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[27].ID then
			if NECROSIS_SPELL_TABLE[27].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 1);
			end
		end
		if NECROSIS_SPELL_TABLE[16].ID then
			if NECROSIS_SPELL_TABLE[16].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 3);
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 1);
			end
		end
	end


	-- Timer button
	-----------------------------------------------
	if HearthstoneLocation[1] then
		local start, duration, enable = GetContainerItemCooldown(HearthstoneLocation[1], HearthstoneLocation[2]);
		if duration > 20 and start > 0 then
			NecrosisSpellTimerButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Cooldown");
		else
			NecrosisSpellTimerButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Normal");
		end
	end
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS DES PIERRES ET DES FRAGMENTS
------------------------------------------------------------------------------------------------------


-- T'AS QU'A SAVOIR OU T'AS MIS TES AFFAIRES !
function Necrosis_SoulshardSetup()
	SoulshardSlotID = 1;
	for slot=1, table.getn(SoulshardSlot), 1 do
		table.remove(SoulshardSlot, slot);
	end
	for slot=1, GetContainerNumSlots(NecrosisConfig.SoulshardContainer), 1 do
		table.insert(SoulshardSlot, nil);
	end
end


-- Function that inventories demonology items: stones, shards, summoning reagents
function Necrosis_BagExplore()
	local soulshards = Soulshards;
	Soulshards = 0;
	InfernalStone = 0;
	DemoniacStone = 0;
	SoulstoneOnHand = false;
	HealthstoneOnHand = false;
	FirestoneOnHand = false;
	SpellstoneOnHand = false;
	FelstoneOnHand = false;
	WrathstoneOnHand = false;
	VoidstoneOnHand = false;
	HearthstoneOnHand = false;
	ItemOnHand = false;
	-- Parcours des sacs
	for container=0, 4, 1 do
		-- Parcours des emplacements des sacs
		for slot=1, GetContainerNumSlots(container), 1 do
			Necrosis_MoneyToggle();
			NecrosisTooltip:SetBagItem(container, slot);
			local itemName = tostring(NecrosisTooltipTextLeft1:GetText());
			local itemSwitch = tostring(NecrosisTooltipTextLeft3:GetText());
			local itemSwitch2 = tostring(NecrosisTooltipTextLeft4:GetText());
			-- If this bag is marked as the shard container
			-- set the bag slot table entry to nil (no shard present)
			if (container == NecrosisConfig.SoulshardContainer) then
				if itemName ~= NECROSIS_ITEM.Soulshard then
					SoulshardSlot[slot] = nil;
				end
			end
			-- When the slot is not empty
			if itemName then
				-- On prend le nombre d'item en stack sur le slot
				local _, ItemCount = GetContainerItemInfo(container, slot);
				-- If it's a shard or infernal stone, add its quantity to the stone count
				if itemName == NECROSIS_ITEM.Soulshard then Soulshards = Soulshards + ItemCount; end
				if itemName == NECROSIS_ITEM.InfernalStone then InfernalStone = InfernalStone + ItemCount; end
				if itemName == NECROSIS_ITEM.DemoniacStone then DemoniacStone = DemoniacStone + ItemCount; end
				-- If it's a Soulstone, record its presence and location
				if string.find(itemName, NECROSIS_ITEM.Soulstone) then
					SoulstoneOnHand = true;
					SoulstoneLocation = {container,slot};
				end
				-- Do the same for a healthstone
				if string.find(itemName, NECROSIS_ITEM.Healthstone) then
					HealthstoneOnHand = true;
					HealthstoneLocation = {container,slot};
				end
				-- And again for the spellstone
				if string.find(itemName, NECROSIS_ITEM.Spellstone) then
					SpellstoneOnHand = true;
					SpellstoneLocation = {container,slot};
				end
				-- Now handle the firestone
				if string.find(itemName, NECROSIS_ITEM.Firestone) then
					FirestoneOnHand = true;
					FirestoneLocation = {container,slot};
				end
				-- Felstone
				if string.find(itemName, NECROSIS_ITEM.Felstone) then
					FelstoneOnHand = true;
					FelstoneLocation = {container,slot};
				end
				-- Wrathstone
				if string.find(itemName, NECROSIS_ITEM.Wrathstone) then
					WrathstoneOnHand = true;
					WrathstoneLocation = {container,slot};
				end
				-- Voidstone
				if string.find(itemName, NECROSIS_ITEM.Voidstone) then
					VoidstoneOnHand = true;
					VoidstoneLocation = {container,slot};
				end
				-- and finally the hearthstone
				if string.find(itemName, NECROSIS_ITEM.Hearthstone) then
					HearthstoneOnHand = true;
					HearthstoneLocation = {container,slot};
				end

				-- Also track whether off-hand items are present
				-- Later this will be used to automatically replace a missing stone
				if itemSwitch == NECROSIS_ITEM.Offhand or itemSwitch2 == NECROSIS_ITEM.Offhand then
					ItemOnHand = true;
					ItemswitchLocation = {container, slot};
				end
			end
		end
	end
	
	-- Affichage du bouton principal de Necrosis
	if NecrosisConfig.Circle == 1 then
		if (Soulshards <= 32) then
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\"..NecrosisConfig.NecrosisColor.."\\Shard"..Soulshards);
		else
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\"..NecrosisConfig.NecrosisColor.."\\Shard32");
		end
	elseif SoulstoneMode ==1 or SoulstoneMode == 2 then
		if (Soulshards <= 32) then
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard"..Soulshards);
		else
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard32");
		end
	end
	if NecrosisConfig.ShowCount then
		if NecrosisConfig.CountType == 2 then
			NecrosisShardCount:SetText(InfernalStone.." / "..DemoniacStone);
		elseif NecrosisConfig.CountType == 1 then
			if Soulshards < 10 then
				NecrosisShardCount:SetText("0"..Soulshards);
			else
				NecrosisShardCount:SetText(Soulshards);
			end
		end
	else
		NecrosisShardCount:SetText("");
	end
	-- And update all of it!
	Necrosis_UpdateIcons();

	-- If the shard bag is full, display a warning
	if (Soulshards > soulshards and Soulshards == GetContainerNumSlots(NecrosisConfig.SoulshardContainer)) then
		if (SoulshardDestroy) then
			Necrosis_Msg(NECROSIS_MESSAGE.Bag.FullPrefix..GetBagName(NecrosisConfig.SoulshardContainer)..NECROSIS_MESSAGE.Bag.FullDestroySuffix);
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Bag.FullPrefix..GetBagName(NecrosisConfig.SoulshardContainer)..NECROSIS_MESSAGE.Bag.FullSuffix);
		end
	end
end

-- Function that locates and tidies shards inside bags
function Necrosis_SoulshardSwitch(type)
	if (type == "CHECK") then
		SoulshardMP = 0;
		for container = 0, 4, 1 do
			for i = 1, 3, 1 do
				if GetBagName(container) == NECROSIS_ITEM.SoulPouch[i] then
					BagIsSoulPouch[container + 1] = true;
					break;
				else
					BagIsSoulPouch[container + 1] = false;
				end
			end
		end
	end
	for container = 0, 4, 1 do
		if BagIsSoulPouch[container+1] then break; end
		if container ~= NecrosisConfig.SoulshardContainer then
			for slot=1, GetContainerNumSlots(container), 1 do
				Necrosis_MoneyToggle();
				NecrosisTooltip:SetBagItem(container, slot);
				local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText());
				if itemInfo == NECROSIS_ITEM.Soulshard then
					if (type == "CHECK") then
						SoulshardMP = SoulshardMP + 1;
					elseif (type == "MOVE") then
						Necrosis_FindSlot(container, slot);
						SoulshardMP = SoulshardMP - 1;
					end
				end
			end
		end
	end
	-- After moving everything we need to find new slots for stones and so on...
	Necrosis_BagExplore();
end

-- While moving shards, find new slots for the displaced items :)
function Necrosis_FindSlot(shardIndex, shardSlot)
	local full = true;
	for slot=1, GetContainerNumSlots(NecrosisConfig.SoulshardContainer), 1 do
		Necrosis_MoneyToggle();
 		NecrosisTooltip:SetBagItem(NecrosisConfig.SoulshardContainer, slot);
 		local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText());
		if string.find(itemInfo, NECROSIS_ITEM.Soulshard) == nil then
			PickupContainerItem(shardIndex, shardSlot);
			PickupContainerItem(NecrosisConfig.SoulshardContainer, slot);
			SoulshardSlot[SoulshardSlotID] = slot;
			SoulshardSlotID = SoulshardSlotID + 1
			if (CursorHasItem()) then
				if shardIndex == 0 then 
					PutItemInBackpack();
				else
					PutItemInBag(19 + shardIndex);
				end
			end
			full = false;
			break;
		end
	end
	-- Destroy excess shards if the option is enabled
	if (full and NecrosisConfig.SoulshardDestroy) then
		PickupContainerItem(shardIndex, shardSlot);
		if (CursorHasItem()) then DeleteCursorItem(); end
	end
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS DES SORTS
------------------------------------------------------------------------------------------------------



-- Show or hide spell buttons each time a new spell is learned
function Necrosis_ButtonSetup()
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_NoDrag();
		Necrosis_UpdateButtonsScale();
	else
		HideUIPanel(NecrosisPetMenuButton);
		HideUIPanel(NecrosisBuffMenuButton);
		HideUIPanel(NecrosisCurseMenuButton);
		HideUIPanel(NecrosisStoneMenuButton);
		HideUIPanel(NecrosisMountButton);
		HideUIPanel(NecrosisSpellstoneButton);
		HideUIPanel(NecrosisHealthstoneButton);
		HideUIPanel(NecrosisSoulstoneButton);
		if (NecrosisConfig.StonePosition[StonePosHealthstone]) and StoneIDInSpellTable[2] ~= 0 then
			ShowUIPanel(NecrosisHealthstoneButton);
		end
		if (NecrosisConfig.StonePosition[StonePosSpellstone]) and StoneIDInSpellTable[3] ~= 0 then
			ShowUIPanel(NecrosisSpellstoneButton);
		end
		if (NecrosisConfig.StonePosition[StonePosSoulstone]) and StoneIDInSpellTable[1] ~= 0 then
			ShowUIPanel(NecrosisSoulstoneButton);
		end
		if (NecrosisConfig.StonePosition[StonePosBuffMenu]) and BuffMenuCreate ~= {} then
			ShowUIPanel(NecrosisBuffMenuButton);
		end
		if (NecrosisConfig.StonePosition[StonePosMount]) and MountAvailable then
			ShowUIPanel(NecrosisMountButton);
		end
		if (NecrosisConfig.StonePosition[StonePosPetMenu]) and PetMenuCreate ~= {} then
			ShowUIPanel(NecrosisPetMenuButton);
		end
		if (NecrosisConfig.StonePosition[StonePosCurseMenu]) and CurseMenuCreate ~= {} then
			ShowUIPanel(NecrosisCurseMenuButton);
		end
		if (NecrosisConfig.StonePosition[StonePosStoneMenu]) and StoneMenuCreate ~= {} then
			ShowUIPanel(NecrosisStoneMenuButton);
		end
	end
end



-- My favorite function! It lists the Warlock's known spells and sorts them by rank.
-- For stones, select the highest known rank
function Necrosis_SpellSetup()
	local StoneType = {NECROSIS_ITEM.Soulstone, NECROSIS_ITEM.Healthstone, NECROSIS_ITEM.Spellstone, NECROSIS_ITEM.Firestone, NECROSIS_ITEM.Felstone, NECROSIS_ITEM.Wrathstone, NECROSIS_ITEM.Voidstone};
	local StoneMaxRank = {0, 0, 0, 0, 0, 0, 0};

	local CurrentStone = {
		ID = {},
		Name = {},
		subName = {}
	};

	local CurrentSpells = {
		ID = {},
		Name = {},
		subName = {}
	};
	
	local spellID = 1;
	local Invisible = 0;
	local InvisibleID = 0;

	-- Iterate through every spell the Warlock knows
	while true do
		local spellName, subSpellName = GetSpellName(spellID, BOOKTYPE_SPELL);
		
		if not spellName then
			do break end
		end
		
		-- For spells with numbered ranks, compare each rank one by one
		-- Keep the highest rank
		if (string.find(subSpellName, NECROSIS_TRANSLATION.Rank)) then
			local found = false;
			local rank = tonumber(strsub(subSpellName, 6, strlen(subSpellName)));
			for index=1, table.getn(CurrentSpells.Name), 1 do
				if (CurrentSpells.Name[index] == spellName) then
			found = true;
					if (CurrentSpells.subName[index] < rank) then
						CurrentSpells.ID[index] = spellID;
						CurrentSpells.subName[index] = rank;
					end
					break;
				end
			end
			-- Insert the highest ranked version of every numbered spell into the table
			if (not found) then
				table.insert(CurrentSpells.ID, spellID);
				table.insert(CurrentSpells.Name, spellName);
				table.insert(CurrentSpells.subName, rank);
			end
		end
		
		-- Test Detect Invisibility's rank
		if spellName == NECROSIS_TRANSLATION.GreaterInvisible then
			Invisible = 3;
			InvisibleID = spellID;
		elseif spellName == NECROSIS_TRANSLATION.Invisible and Invisible ~= 3 then
			Invisible = 2;
			InvisibleID = spellID;
		elseif spellName == NECROSIS_TRANSLATION.LesserInvisible and Invisible ~= 3 and Invisible ~= 2 then
			Invisible = 1;
			InvisibleID = spellID;	
		end
		
		-- Stones do not have numbered ranks; the rank is part of the spell name
		-- Pour chaque type de pierre, on va donc faire....
		for stoneID=1, table.getn(StoneType), 1 do
			-- If the spell is the summon for this stone type and we have not
			-- and we have not already assigned its maximum rank
			if (string.find(spellName, StoneType[stoneID]))
				and StoneMaxRank[stoneID] ~= table.getn(NECROSIS_STONE_RANK)
				then
				-- Extract the end of the stone name that encodes its rank
				local stoneSuffix = string.sub(spellName, string.len(NECROSIS_CREATE[stoneID]) + 1);
				-- Next, find which rank it corresponds to
				for rankID=1, table.getn(NECROSIS_STONE_RANK), 1 do
					-- If the suffix matches a stone size, record the rank!
					if string.lower(stoneSuffix) == string.lower(NECROSIS_STONE_RANK[rankID]) then 
						-- Once we know the stone and its rank, check whether it is the strongest
						-- and if so, record it
						if rankID > StoneMaxRank[stoneID] then
							StoneMaxRank[stoneID] = rankID;
							CurrentStone.Name[stoneID] = spellName;
							CurrentStone.subName[stoneID] = NECROSIS_STONE_RANK[rankID];
							CurrentStone.ID[stoneID] = spellID;
						end
						break
					end
				end
			end
		end

		spellID = spellID + 1;
	end

	-- Insert the stones of the highest rank into the table
	for stoneID=1, table.getn(StoneType), 1 do
		if StoneMaxRank[stoneID] ~= 0 then
			table.insert(NECROSIS_SPELL_TABLE, {
				ID = CurrentStone.ID[stoneID],
				Name = CurrentStone.Name[stoneID],
				Rank = 0,
				CastTime = 0,
				Length = 0,
				Type = 0,
			});
			StoneIDInSpellTable[stoneID] = table.getn(NECROSIS_SPELL_TABLE);
		end
	end
	-- Refresh the spell list with the new ranks
	for spell=1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		for index = 1, table.getn(CurrentSpells.Name), 1 do
			if (NECROSIS_SPELL_TABLE[spell].Name == CurrentSpells.Name[index])
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[1]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[2]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[3]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[4]
				then
					NECROSIS_SPELL_TABLE[spell].ID = CurrentSpells.ID[index];
					NECROSIS_SPELL_TABLE[spell].Rank = CurrentSpells.subName[index];
			end
		end
	end

	-- Update each spell duration based on its rank
	for index=1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if (index == 9) then -- si Bannish
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 10 + 10;
			end
		end
		if (index == 13)  then -- si Fear
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 5 + 5;
			end
		end
		if (index == 14) then -- si Corruption
			if NECROSIS_SPELL_TABLE[index].ID ~= nil and NECROSIS_SPELL_TABLE[index].Rank <= 2 then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 3 + 9;		
			end
		end
	end

	for spellID=1, MAX_SPELLS, 1 do
        local spellName, subSpellName = GetSpellName(spellID, "spell");
		if (spellName) then
			for index=1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if NECROSIS_SPELL_TABLE[index].Name == spellName then
					Necrosis_MoneyToggle();
					NecrosisTooltip:SetSpell(spellID, 1);
					local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)");
					if not NECROSIS_SPELL_TABLE[index].ID then
						NECROSIS_SPELL_TABLE[index].ID = spellID;
					end
					NECROSIS_SPELL_TABLE[index].Mana = tonumber(ManaCost);
				end
			end
		end
	end
	if NECROSIS_SPELL_TABLE[1].ID or NECROSIS_SPELL_TABLE[2].ID then
		MountAvailable = true;
	else
		MountAvailable = false;
	end

	-- Insert the highest known rank of Detect Invisibility
	if Invisible >= 1 then
		NECROSIS_SPELL_TABLE[33].ID = InvisibleID;
		NECROSIS_SPELL_TABLE[33].Rank = 0;
		NECROSIS_SPELL_TABLE[33].CastTime = 0;
		NECROSIS_SPELL_TABLE[33].Length = 0;
		Necrosis_MoneyToggle();
		NecrosisTooltip:SetSpell(InvisibleID, 1);
		local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)");
		NECROSIS_SPELL_TABLE[33].Mana = tonumber(ManaCost);
	end
end

-- Function that extracts spell attributes
-- F(type=string, string, int) -> Spell=table
function Necrosis_FindSpellAttribute(type, attribute, array)
	for index=1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if string.find(NECROSIS_SPELL_TABLE[index][type], attribute) then return NECROSIS_SPELL_TABLE[index][array]; end
	end
	return nil;
end

-- Function to cast Shadow Bolt from the Shadow Trance button
-- The shard must use the highest rank
function Necrosis_CastShadowBolt()
	local spellID = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "ID");
	if (spellID) then
		CastSpell(spellID, "spell");
	else
		Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.NoBoltSpell, "USER");
	end
end

------------------------------------------------------------------------------------------------------
-- FONCTIONS DIVERSES
------------------------------------------------------------------------------------------------------

-- Function that determines whether a unit is affected by an effect
-- F(string, string)->bool
function Necrosis_UnitHasEffect(unit, effect)
	local index = 1;
	while UnitDebuff(unit, index) do
		Necrosis_MoneyToggle();
		NecrosisTooltip:SetUnitDebuff(unit, index);
		local DebuffName = tostring(NecrosisTooltipTextLeft1:GetText());
   		if (string.find(DebuffName, effect)) then
			return true;
		end
		index = index+1;
	end
	return false;
end

-- Function to check the presence of a buff on the unit.
-- Strictly identical to UnitHasEffect, but as WoW distinguishes Buff and DeBuff, so we have to.
function Necrosis_UnitHasBuff(unit, effect)
	local index = 1;
	while UnitBuff(unit, index) do
	-- Here we'll cheat a little. checking a buff or debuff return the internal spell name, and not the name we give at start
		-- So we use an API widget that will use the internal name to return the known name.
		-- For example, the "Curse of Agony" spell is internaly known as "Spell_Shadow_CurseOfSargeras". Much easier to use the first one than the internal one.
		Necrosis_MoneyToggle();
		NecrosisTooltip:SetUnitBuff(unit, index);
		local BuffName = tostring(NecrosisTooltipTextLeft1:GetText());
   		if (string.find(BuffName, effect)) then
			return true;
		end
		index = index+1;
	end
	return false;
end


-- Detects when the player gains Nightfall / Shadow Trance
function Necrosis_UnitHasTrance()
	local ID = -1;
	for buffID = 0, 24, 1 do
		local buffTexture = GetPlayerBuffTexture(buffID);
		if buffTexture == nil then break end
		if strfind(buffTexture, "Spell_Shadow_Twilight") then
			ID = buffID;
			break
		end
	end
	ShadowTranceID = ID;
end

-- Function handling button click actions for Necrosis
function Necrosis_UseItem(type,button)
	Necrosis_MoneyToggle();
	NecrosisTooltip:SetBagItem("player", 17);
	local rightHand = tostring(NecrosisTooltipTextLeft1:GetText());

	-- Function that uses a hearthstone from the inventory
	-- if one is in the inventory and it was a right-click
	if type == "Hearthstone" and button == "RightButton" then
		if (HearthstoneOnHand) then
		-- use it
		UseContainerItem(HearthstoneLocation[1], HearthstoneLocation[2]);
		-- or, if none are in the inventory, show an error message
		else
		Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHearthStone, "USER");
		end
	end

	-- When clicking the Soulstone button
	-- Update the button to indicate the current mode
	if (type == "Soulstone") then
		Necrosis_UpdateIcons();
		-- If mode = 2 (stone in inventory, none in use)
		-- alors on l'utilise
		if (SoulstoneMode == 2) then
			-- If a player is targeted, cast on them (with alert message)
			-- If no player is targeted, cast on the Warlock (without a message)
			if UnitIsPlayer("target") then
				SoulstoneUsedOnTarget = true;
			else
				SoulstoneUsedOnTarget = false;
				TargetUnit("player");
			end
			UseContainerItem(SoulstoneLocation[1], SoulstoneLocation[2]);
			-- Now that timers persist across the session, we no longer reset when relogging
			NecrosisRL = false;
			-- And there we go, refresh the button display :)
			Necrosis_UpdateIcons();
		-- if no Soulstone is in the inventory, create the highest-rank Soulstone :)
		elseif (SoulstoneMode == 1) or (SoulstoneMode == 3) then
				if StoneIDInSpellTable[1] ~= 0 then
					CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].ID, "spell");
				else
					Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSoulStoneSpell, "USER");
				end
			
		end
	-- When clicking the Healthstone button:
	elseif (type == "Healthstone") then
		-- or there is one in the inventory
		if HealthstoneOnHand then
			-- If a friendly player is targeted, give them the stone
			-- Otherwise use it
			if NecrosisTradeRequest then
				PickupContainerItem(HealthstoneLocation[1], HealthstoneLocation[2]);
				ClickTradeButton(1);
				NecrosisTradeRequest = false;
				Trading = true;
				TradingNow = 3;
				return;
			elseif (UnitExists("target") and UnitIsPlayer("target") and (not UnitCanAttack("player", "target")) and UnitName("target") ~= UnitName("player")) then
				PickupContainerItem(HealthstoneLocation[1], HealthstoneLocation[2]);
	        		if ( CursorHasItem() ) then
	            			DropItemOnUnit("target");
					Trading = true;
					TradingNow = 3;
				end
				return;
			end
			if (UnitHealth("player") == UnitHealthMax("player")) then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.FullHealth, "USER");
			else
				SpellStopCasting();
				UseContainerItem(HealthstoneLocation[1], HealthstoneLocation[2]);

				-- Inserts a timer for the Healthstone if not already present
				local HealthstoneInUse = false
				if Necrosis_TimerExisteDeja(NECROSIS_COOLDOWN.Healthstone, SpellTimer) then
					HealthstoneInUse = true;
				end
				if not HealthstoneInUse then
					SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone(type, nil, nil, SpellGroup, SpellTimer, TimerTable);
				end

				-- Healthstone shares its cooldown with Spellstone, so we add both timers at the same time, but only if Spellstone is known
				local SpellstoneInUse = false
				if Necrosis_TimerExisteDeja(NECROSIS_COOLDOWN.Spellstone, SpellTimer) then
					SpellstoneInUse = true;
				end
				if not SpellstoneInUse and StoneIDInSpellTable[3] ~= 0 then
					SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone("Spellstone", nil, nil, SpellGroup, SpellTimer, TimerTable);
				end
			end
		-- or, if none are in the inventory, create the highest rank stone
		else
			if StoneIDInSpellTable[2] ~= 0 then
					CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].ID, "spell");
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHealthStoneSpell, "USER");
			end
		end
	-- When clicking the Spellstone button
	elseif (type == "Spellstone") then
		if SpellstoneOnHand then
			local start, duration, enabled = GetContainerItemCooldown(SpellstoneLocation[1], SpellstoneLocation[2]);
			if start > 0 then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.SpellStoneIsOnCooldown, "USER");
			else
				SpellStopCasting();
				UseContainerItem(SpellstoneLocation[1], SpellstoneLocation[2]);

				local SpellstoneInUse = false;
				if Necrosis_TimerExisteDeja(NECROSIS_COOLDOWN.Spellstone, SpellTimer) then
					SpellstoneInUse = true;
				end
				if not SpellstoneInUse then
					SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone(type, nil, nil, SpellGroup, SpellTimer, TimerTable);
				end

				local HealthstoneInUse = false;
				if Necrosis_TimerExisteDeja(NECROSIS_COOLDOWN.Healthstone, SpellTimer) then
					HealthstoneInUse = true;
				end
				if not HealthstoneInUse and StoneIDInSpellTable[2] ~= 0 then
					SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone("Healthstone", nil, nil, SpellGroup, SpellTimer, TimerTable);
				end
			end
		else
			if StoneIDInSpellTable[3] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].ID, "spell");
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSpellStoneSpell, "USER");
			end
		end

	-- When clicking the mount button
	elseif (type == "Mount") then
		-- Or it is the epic mount
		if NECROSIS_SPELL_TABLE[2].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[2].ID, "spell");
			Necrosis_OnUpdate();
		-- Either it is the normal mount
		elseif NECROSIS_SPELL_TABLE[1].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[1].ID, "spell");
			Necrosis_OnUpdate();
		-- (Or it is nothing at all :) )
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Error.NoRiding, "USER");
		end
	end
end

-- Function that swaps the equipped off-hand item with one from the inventory
function Necrosis_SwitchOffHand(type)
	if (type == "Spellstone") then
		if SpellstoneMode == 3 then
			if ItemOnHand then
				Necrosis_Msg("Equipe "..GetContainerItemLink(ItemswitchLocation[1],ItemswitchLocation[2])..NECROSIS_MESSAGE.SwitchMessage..GetInventoryItemLink("player",17), "USER");
				PickupInventoryItem(17);
				PickupContainerItem(ItemswitchLocation[1],ItemswitchLocation[2]);
			end
			return;
		else
			PickupContainerItem(SpellstoneLocation[1], SpellstoneLocation[2]);
			PickupInventoryItem(17);
			if Necrosis_TimerExisteDeja(NECROSIS_COOLDOWN.Spellstone, SpellTimer) then
				SpellTimer, TimerTable = Necrosis_RetraitTimerParNom(NECROSIS_COOLDOWN.Spellstone, SpellTimer, TimerTable);
			end
			SpellGroup, SpellTimer, TimerTable = Necrosis_InsertTimerStone(type, nil, nil, SpellGroup, SpellTimer, TimerTable);
			return;
		end
	end
	if (type == "OffHand") and UnitClass("player") == NECROSIS_UNIT_WARLOCK then
		if ItemswitchLocation[1] ~= nil and ItemswitchLocation[2] ~= nil then
			PickupContainerItem(ItemswitchLocation[1],ItemswitchLocation[2]);
			PickupInventoryItem(17);
		end
	end
end

function Necrosis_MoneyToggle()
	for index=1, 10 do
		local text = getglobal("NecrosisTooltipTextLeft"..index);
			text:SetText(nil);
			text = getglobal("NecrosisTooltipTextRight"..index);
			text:SetText(nil);
	end
	NecrosisTooltip:Hide();
	NecrosisTooltip:SetOwner(WorldFrame, "ANCHOR_NONE"); 
end

function Necrosis_GameTooltip_ClearMoney()
    -- Intentionally empty; don't clear money while we use hidden tooltips
end


-- Function that positions the buttons around Necrosis (and scales the interface)
function Necrosis_UpdateButtonsScale()
	local NBRScale = (100 + (NecrosisConfig.NecrosisButtonScale - 85)) / 100;
	if NecrosisConfig.NecrosisButtonScale <= 95 then
		NBRScale = 1.1;
	end
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_ClearAllPoints();
		HideUIPanel(NecrosisPetMenuButton);
		HideUIPanel(NecrosisBuffMenuButton);
		HideUIPanel(NecrosisCurseMenuButton);
		HideUIPanel(NecrosisStoneMenuButton);
		HideUIPanel(NecrosisMountButton);
		HideUIPanel(NecrosisSpellstoneButton);
		HideUIPanel(NecrosisHealthstoneButton);
		HideUIPanel(NecrosisSoulstoneButton);
		local indexScale = -36;
		for index=1, 8, 1 do
			if NecrosisConfig.StonePosition[index] then
				if index == StonePosHealthstone and StoneIDInSpellTable[2] ~= 0 then
					NecrosisHealthstoneButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisHealthstoneButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosSpellstone and StoneIDInSpellTable[3] ~= 0 then
					NecrosisSpellstoneButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisSpellstoneButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosSoulstone and StoneIDInSpellTable[1] ~= 0 then
					NecrosisSoulstoneButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisSoulstoneButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosBuffMenu and BuffMenuCreate ~= {} then
					NecrosisBuffMenuButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisBuffMenuButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosMount and MountAvailable then
					NecrosisMountButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisMountButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosPetMenu and PetMenuCreate ~= {} then
					NecrosisPetMenuButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisPetMenuButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosCurseMenu and CurseMenuCreate ~= {} then
					NecrosisCurseMenuButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisCurseMenuButton);
					indexScale = indexScale + 36;
				end
				if index == StonePosStoneMenu and StoneMenuCreate ~= {} then
					NecrosisStoneMenuButton:SetPoint("CENTER", "NecrosisButton", "CENTER", ((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle-indexScale)), ((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle-indexScale)));
					ShowUIPanel(NecrosisStoneMenuButton);
					indexScale = indexScale + 36;
				end
			end
		end
	end
end 



-- (XML) function that restores default button anchors
function Necrosis_ClearAllPoints()
	NecrosisSpellstoneButton:ClearAllPoints();
	NecrosisHealthstoneButton:ClearAllPoints();
	NecrosisSoulstoneButton:ClearAllPoints();
	NecrosisMountButton:ClearAllPoints();
	NecrosisPetMenuButton:ClearAllPoints();
	NecrosisBuffMenuButton:ClearAllPoints();
	NecrosisCurseMenuButton:ClearAllPoints();
	NecrosisStoneMenuButton:ClearAllPoints();
end

-- (XML) function to extend the main button's NoDrag() property to every child button
function Necrosis_NoDrag()
	NecrosisSpellstoneButton:RegisterForDrag("");
	NecrosisHealthstoneButton:RegisterForDrag("");
	NecrosisSoulstoneButton:RegisterForDrag("");
	NecrosisMountButton:RegisterForDrag("");
	NecrosisPetMenuButton:RegisterForDrag("");
	NecrosisBuffMenuButton:RegisterForDrag("");
	NecrosisCurseMenuButton:RegisterForDrag("");
	NecrosisStoneMenuButton:RegisterForDrag("");
end

-- (XML) counterpart of the function above
function Necrosis_Drag()
	NecrosisSpellstoneButton:RegisterForDrag("LeftButton");
	NecrosisHealthstoneButton:RegisterForDrag("LeftButton");
	NecrosisSoulstoneButton:RegisterForDrag("LeftButton");
	NecrosisMountButton:RegisterForDrag("LeftButton");
	NecrosisPetMenuButton:RegisterForDrag("LeftButton");
	NecrosisBuffMenuButton:RegisterForDrag("LeftButton");
	NecrosisCurseMenuButton:RegisterForDrag("LeftButton");
	NecrosisStoneMenuButton:RegisterForDrag("LeftButton");
end

-- Opening the buff menu
function Necrosis_BuffMenu(button)
	if button == "MiddleButton" and LastBuff ~= 0 then
		Necrosis_BuffCast(LastBuff);
		return;
	end
	BuffMenuShow = not BuffMenuShow;
	if not BuffMenuShow then
		BuffShow = false;
		BuffVisible = false;
		NecrosisBuffMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-01");
		BuffMenuCreate[1]:ClearAllPoints();
		BuffMenuCreate[1]:SetPoint("CENTER", "NecrosisBuffMenuButton", "CENTER", 3000, 3000);
		AlphaBuffMenu = 1;
	else
		BuffShow = true;
		NecrosisBuffMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-02");
		-- Si clic droit, le menu de buff reste ouvert
		if button == "RightButton" then
			BuffVisible = true;
		end
		-- S'il n'existe aucun buff on ne fait rien
		if BuffMenuCreate == nil then
			return;
		end
		-- Otherwise display the icons
		NecrosisBuffMenu1:SetAlpha(1);
		NecrosisBuffMenu2:SetAlpha(1);
		NecrosisBuffMenu3:SetAlpha(1);
		NecrosisBuffMenu4:SetAlpha(1);
		NecrosisBuffMenu5:SetAlpha(1);
		NecrosisBuffMenu6:SetAlpha(1);
		NecrosisBuffMenu7:SetAlpha(1);
		NecrosisBuffMenu8:SetAlpha(1);
		NecrosisBuffMenu9:SetAlpha(1);
		BuffMenuCreate[1]:ClearAllPoints();		
		BuffMenuCreate[1]:SetPoint("CENTER", "NecrosisBuffMenuButton", "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31) , 26);
		AlphaPetVar = GetTime() + 3;
		AlphaBuffVar = GetTime() + 6;
		AlphaCurseVar = GetTime() + 6;
	end
end

-- Opening the curse menu
function Necrosis_CurseMenu(button)
	if button == "MiddleButton" and LastCurse ~= 0 then
		Necrosis_CurseCast(LastCurse, LastCurseClick);
		return;
	end
	-- S'il n'existe aucune curse on ne fait rien
	if CurseMenuCreate[1] == nil then
		return;
	end
	CurseMenuShow = not CurseMenuShow;
	if not CurseMenuShow then
		CurseShow = false;
		CurseVisible = false;
		NecrosisCurseMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-01");
		CurseMenuCreate[1]:ClearAllPoints();
		CurseMenuCreate[1]:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		AlphaCurseMenu = 1;
	else
		CurseShow = true;
		NecrosisCurseMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-02");
		-- Si clic droit, le menu de curse reste ouvert
		if button == "RightButton" then
			CurseVisible = true;
		end
		-- Otherwise display the icons
		NecrosisCurseMenu1:SetAlpha(1);
		NecrosisCurseMenu2:SetAlpha(1);
		NecrosisCurseMenu3:SetAlpha(1);
		NecrosisCurseMenu4:SetAlpha(1);
		NecrosisCurseMenu5:SetAlpha(1);
		NecrosisCurseMenu6:SetAlpha(1);
		NecrosisCurseMenu7:SetAlpha(1);
		NecrosisCurseMenu8:SetAlpha(1);
		NecrosisCurseMenu9:SetAlpha(1);
		CurseMenuCreate[1]:ClearAllPoints();		
		CurseMenuCreate[1]:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31) , -26);
		AlphaPetVar = GetTime() + 3;
		AlphaBuffVar = GetTime() + 6;
		AlphaCurseVar = GetTime() + 6;
	end
end

-- Opening the demon menu
function Necrosis_PetMenu(button)
	if button == "MiddleButton" and LastDemon ~= 0 then
		Necrosis_PetCast(LastDemon);
		return;
	end
	-- S'il n'existe aucun sort d'invocation on ne fait rien
	if PetMenuCreate[1] == nil then
		return;
	end
	PetMenuShow = not PetMenuShow;
	if not PetMenuShow then
		PetShow = false;
		PetVisible = false;
		NecrosisPetMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-01");
		PetMenuCreate[1]:ClearAllPoints();
		PetMenuCreate[1]:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", 3000, 3000);
		AlphaPetMenu = 1;
	else
		PetShow = true;
		NecrosisPetMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-02");
		-- Si clic droit, le menu de pet reste ouvert
		if button == "RightButton" then
			PetVisible = true;
		end
		-- Otherwise display the icons (move them onto the screen)
		NecrosisPetMenu1:SetAlpha(1);
		NecrosisPetMenu2:SetAlpha(1);
		NecrosisPetMenu3:SetAlpha(1);
		NecrosisPetMenu4:SetAlpha(1);
		NecrosisPetMenu5:SetAlpha(1);
		NecrosisPetMenu6:SetAlpha(1);
		NecrosisPetMenu7:SetAlpha(1);
		NecrosisPetMenu8:SetAlpha(1);
		NecrosisPetMenu9:SetAlpha(1);
		PetMenuCreate[1]:ClearAllPoints();		
		PetMenuCreate[1]:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31) , 26);
		AlphaPetVar = GetTime() + 3;
	end
end

-- Opening the stone menu
function Necrosis_StoneMenu(button)
	if button == "MiddleButton" and LastStone ~= 0 then
		Necrosis_StoneCast(LastStone, LastStoneClick);
		return;
	end
	-- S'il n'existe aucune stone on ne fait rien
	if StoneMenuCreate[1] == nil then
		return;
	end
	StoneMenuShow = not StoneMenuShow;
	if not StoneMenuShow then
		StoneShow = false;
		StoneVisible = false;
		Necrosis_UpdateIcons();
		StoneMenuCreate[1]:ClearAllPoints();
		StoneMenuCreate[1]:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", 3000, 3000);
		AlphaStoneMenu = 1;
	else
		StoneShow = true;
		Necrosis_UpdateIcons();
		-- Si clic droit, le menu de stone reste ouvert
		if button == "RightButton" then
			StoneVisible = true;
		end
		-- Otherwise display the icons
		NecrosisStoneMenu1:SetAlpha(1);
		NecrosisStoneMenu2:SetAlpha(1);
		NecrosisStoneMenu3:SetAlpha(1);
		StoneMenuCreate[1]:ClearAllPoints();
		StoneMenuCreate[1]:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", ((36 / NecrosisConfig.StoneMenuPos) * 31) , -26);
		AlphaStoneVar = GetTime() + 6;
	end
end

-- Each time the spellbook changes, at mod startup, or when the menu direction flips, rebuild the spell menus
function Necrosis_CreateMenu()
	PetMenuCreate = {};
	CurseMenuCreate = {};
	BuffMenuCreate = {};
	StoneMenuCreate = {};
	local menuVariable = nil;
	local PetButtonPosition = 0;
	local BuffButtonPosition = 0;
	local CurseButtonPosition = 0;
	local StoneButtonPosition = 0;
	
	-- Hide every demon icon
	for i = 1, 9, 1 do
		menuVariable = getglobal("NecrosisPetMenu"..i);
		menuVariable:Hide();
	end
	-- On cache toutes les icones des sorts
	for i = 1, 9, 1 do
		menuVariable = getglobal("NecrosisBuffMenu"..i);
		menuVariable:Hide();
	end
	-- On cache toutes les icones des curses
	for i = 1, 9, 1 do
		menuVariable = getglobal("NecrosisCurseMenu"..i);
		menuVariable:Hide();
	end

	
	-- If Fel Domination exists, show its button in the pet menu
	if NECROSIS_SPELL_TABLE[15].ID then
		menuVariable = getglobal("NecrosisPetMenu1");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", 3000, 3000);
		PetButtonPosition = 1;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation du Diablotin existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[3].ID then
		menuVariable = getglobal("NecrosisPetMenu2");
		menuVariable:ClearAllPoints();
		if PetButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		end
		PetButtonPosition = 2;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation du Marcheur existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[4].ID then
		menuVariable = getglobal("NecrosisPetMenu3");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 3;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation du Succube existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[5].ID then
		menuVariable = getglobal("NecrosisPetMenu4");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 4;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation du Felhunter existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[6].ID then
		menuVariable = getglobal("NecrosisPetMenu5");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 5;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation de l'Infernal existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[8].ID then
		menuVariable = getglobal("NecrosisPetMenu6");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 6;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'invocation du Doomguard existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[30].ID then
		menuVariable = getglobal("NecrosisPetMenu7");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 7;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- Si l'asservissement existe, on affiche le bouton dans le menu des pets
	if NECROSIS_SPELL_TABLE[35].ID then
		menuVariable = getglobal("NecrosisPetMenu8");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 8;
		table.insert(PetMenuCreate, menuVariable);
	end
	-- If Demonic Sacrifice exists, show its button in the pet menu
	if NECROSIS_SPELL_TABLE[44].ID then
		menuVariable = getglobal("NecrosisPetMenu9");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisPetMenu"..PetButtonPosition, "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 0);
		PetButtonPosition = 9;
		table.insert(PetMenuCreate, menuVariable);
	end

	
	-- With all pet buttons lined up off-screen, reveal the ones that are available
	for i = 1, table.getn(PetMenuCreate), 1 do
		ShowUIPanel(PetMenuCreate[i]);
	end

	-- If Demon Armor exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[31].ID or NECROSIS_SPELL_TABLE[36].ID then
		menuVariable = getglobal("NecrosisBuffMenu1");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenuButton", "CENTER", 3000, 3000);
		BuffButtonPosition = 1;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Unending Breath exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[32].ID then
		menuVariable = getglobal("NecrosisBuffMenu2");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 2;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Detect Invisibility is known, show its highest-rank button in the buff menu
	if NECROSIS_SPELL_TABLE[33].ID then
		menuVariable = getglobal("NecrosisBuffMenu3");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 3;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Unending Breath exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[34].ID then
		menuVariable = getglobal("NecrosisBuffMenu4");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 4;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- Si l'invocation de joueur existe, on affiche le bouton dans le menu des buffs
	if NECROSIS_SPELL_TABLE[37].ID then
		menuVariable = getglobal("NecrosisBuffMenu5");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 5;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Sense Demons exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[39].ID then
		menuVariable = getglobal("NecrosisBuffMenu6");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 6;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Soul Link exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[38].ID then
		menuVariable = getglobal("NecrosisBuffMenu7");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 7;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Shadow Ward exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[43].ID then
		menuVariable = getglobal("NecrosisBuffMenu8");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 8;
		table.insert(BuffMenuCreate, menuVariable);
	end
	-- If Banish exists, show its button in the buff menu
	if NECROSIS_SPELL_TABLE[9].ID then
		menuVariable = getglobal("NecrosisBuffMenu9");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisBuffMenu"..BuffButtonPosition, "CENTER", ((36 / NecrosisConfig.BuffMenuPos) * 31), 0);
		BuffButtonPosition = 9;
		table.insert(BuffMenuCreate, menuVariable);
	end

	-- With all buff buttons lined up off-screen, reveal the ones that are available
	for i = 1, table.getn(BuffMenuCreate), 1 do
		ShowUIPanel(BuffMenuCreate[i]);
	end

	-- If Amplify Curse exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[42].ID then
		menuVariable = getglobal("NecrosisCurseMenu1");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		CurseButtonPosition = 1;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Weakness exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[23].ID then
		menuVariable = getglobal("NecrosisCurseMenu2");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 2;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Agony exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[22].ID then
		menuVariable = getglobal("NecrosisCurseMenu3");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 3;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Recklessness exists, show its highest rank in the curse menu
	if NECROSIS_SPELL_TABLE[24].ID then
		menuVariable = getglobal("NecrosisCurseMenu4");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 4;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Tongues exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[25].ID then
		menuVariable = getglobal("NecrosisCurseMenu5");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 5;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Exhaustion exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[40].ID then
		menuVariable = getglobal("NecrosisCurseMenu6");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 6;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of the Elements exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[26].ID then
		menuVariable = getglobal("NecrosisCurseMenu7");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 7;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Shadow exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[27].ID then
		menuVariable = getglobal("NecrosisCurseMenu8");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 8;
		table.insert(CurseMenuCreate, menuVariable);
	end
	-- If Curse of Doom exists, show its button in the curse menu
	if NECROSIS_SPELL_TABLE[16].ID then
		menuVariable = getglobal("NecrosisCurseMenu9");
		menuVariable:ClearAllPoints();
		if CurseButtonPosition == 0 then 
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisCurseMenu"..CurseButtonPosition, "CENTER", ((36 / NecrosisConfig.CurseMenuPos) * 31), 0);
		end
		CurseButtonPosition = 9;
		table.insert(CurseMenuCreate, menuVariable);
	end

	-- With all curse buttons lined up off-screen, reveal the ones that are available
	for i = 1, table.getn(CurseMenuCreate), 1 do
		ShowUIPanel(CurseMenuCreate[i]);
	end

	-- Si la Felstone existe, on affiche le bouton dans le menu des stones
	if NECROSIS_SPELL_TABLE[45].ID then
		menuVariable = getglobal("NecrosisStoneMenu1");
		menuVariable:ClearAllPoints();
		menuVariable:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", 3000, 3000);
		Necrosis_SetButtonTexture(menuVariable, "Felstone", 2);
		StoneButtonPosition = 1;
		table.insert(StoneMenuCreate, menuVariable);
	end
	-- If the Wrathstone exists, show its button in the stone menu
	if NECROSIS_SPELL_TABLE[46].ID then
		menuVariable = getglobal("NecrosisStoneMenu2");
		menuVariable:ClearAllPoints();
		if StoneButtonPosition == 0 then
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenu"..StoneButtonPosition, "CENTER", ((36 / NecrosisConfig.StoneMenuPos) * 31), 0);
		end
		Necrosis_SetButtonTexture(menuVariable, "Wrathstone", 2);
		StoneButtonPosition = 2;
		table.insert(StoneMenuCreate, menuVariable);
	end
	-- Si la Voidstone existe, on affiche le bouton dans le menu des stones
	if NECROSIS_SPELL_TABLE[47].ID then
		menuVariable = getglobal("NecrosisStoneMenu3");
		menuVariable:ClearAllPoints();
		if StoneButtonPosition == 0 then
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenu"..StoneButtonPosition, "CENTER", ((36 / NecrosisConfig.StoneMenuPos) * 31), 0);
		end
		Necrosis_SetButtonTexture(menuVariable, "Voidstone", 2);
		StoneButtonPosition = 3;
		table.insert(StoneMenuCreate, menuVariable);
	end
	-- Si la Firestone existe, on affiche le bouton dans le menu des stones
	if StoneIDInSpellTable[4] ~= 0 then
		menuVariable = getglobal("NecrosisStoneMenu4");
		menuVariable:ClearAllPoints();
		if StoneButtonPosition == 0 then
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenuButton", "CENTER", 3000, 3000);
		else
			menuVariable:SetPoint("CENTER", "NecrosisStoneMenu"..StoneButtonPosition, "CENTER", ((36 / NecrosisConfig.StoneMenuPos) * 31), 0);
		end
		Necrosis_SetButtonTexture(menuVariable, "FirestoneButton", 2);
		StoneButtonPosition = 4;
		table.insert(StoneMenuCreate, menuVariable);
	end

	-- With all stone buttons lined up off-screen, reveal the ones that are available
	for i = 1, table.getn(StoneMenuCreate), 1 do
		ShowUIPanel(StoneMenuCreate[i]);
	end
end

-- Handle casts triggered from the buff menu
function Necrosis_BuffCast(type)
	local TargetEnemy = false;
	if UnitCanAttack("player","target") and type ~= 9 then
		TargetUnit("player");
		TargetEnemy = true;
	end
	-- If the Warlock has Demon Skin but not Demon Armor
	if not NECROSIS_SPELL_TABLE[type].ID then
		CastSpell(NECROSIS_SPELL_TABLE[36].ID, "spell");
	else
		if (type ~= 44) or (type == 44 and UnitExists("Pet")) then
			CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell");
		end
	end
	LastBuff = type;
	if TargetEnemy then TargetLastTarget(); end
	AlphaBuffMenu = 1;
	AlphaBuffVar = GetTime() + 3;
end

-- Handle casts triggered from the curse menu
function Necrosis_CurseCast(type, click)
	if (UnitIsFriend("player","target")) and (not UnitCanAttack("player","target")) then
		AssistUnit("target");
	end
	if (UnitCanAttack("player","target")) and (UnitName("target") ~= nil) then
		if (type == 23 or type == 22 or type == 40) then
			if (click == "RightButton") and (NECROSIS_SPELL_TABLE[42].ID ~= nil) then
				local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell");
				if not (start3 > 0 and duration3 > 0) then
					CastSpell(NECROSIS_SPELL_TABLE[42].ID, "spell");
					SpellStopCasting(NECROSIS_SPELL_TABLE[42].Name);
				end
			end
		end
		CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell");
		LastCurse = type;
		LastCurseClick = click;
		if (click == "MiddleButton") and (UnitExists("Pet")) then
			PetAttack();
		end
	end
	AlphaCurseMenu = 1;
	AlphaCurseVar = GetTime() + 3;
end

-- Handle casts triggered from the stone menu
function Necrosis_StoneCast(type, click)
	if type == 1 then -- Felstone
		if FelstoneOnHand then
			SpellStopCasting();
			UseContainerItem(FelstoneLocation[1], FelstoneLocation[2]);
			return;
		else
			local spellID = StoneIDInSpellTable[5];
			if spellID and NECROSIS_SPELL_TABLE[spellID] and NECROSIS_SPELL_TABLE[spellID].ID then
				if NECROSIS_SPELL_TABLE[spellID].Mana > UnitMana("player") then Necrosis_Msg(NECROSIS_MESSAGE.Error.NoMana, "USER"); return; end
				CastSpell(NECROSIS_SPELL_TABLE[spellID].ID, "spell");
				LastStone = type; LastStoneClick = click;
			end
		end
	elseif type == 2 then -- Wrathstone
		if WrathstoneOnHand then
			SpellStopCasting();
			UseContainerItem(WrathstoneLocation[1], WrathstoneLocation[2]);
			return;
		else
			local spellID = StoneIDInSpellTable[6];
			if spellID and NECROSIS_SPELL_TABLE[spellID] and NECROSIS_SPELL_TABLE[spellID].ID then
				if NECROSIS_SPELL_TABLE[spellID].Mana > UnitMana("player") then Necrosis_Msg(NECROSIS_MESSAGE.Error.NoMana, "USER"); return; end
				CastSpell(NECROSIS_SPELL_TABLE[spellID].ID, "spell");
				LastStone = type; LastStoneClick = click;
			end
		end
	elseif type == 3 then -- Voidstone
		if VoidstoneOnHand then
			SpellStopCasting();
			UseContainerItem(VoidstoneLocation[1], VoidstoneLocation[2]);
			return;
		else
			local spellID = StoneIDInSpellTable[7];
			if spellID and NECROSIS_SPELL_TABLE[spellID] and NECROSIS_SPELL_TABLE[spellID].ID then
				if NECROSIS_SPELL_TABLE[spellID].Mana > UnitMana("player") then Necrosis_Msg(NECROSIS_MESSAGE.Error.NoMana, "USER"); return; end
				CastSpell(NECROSIS_SPELL_TABLE[spellID].ID, "spell");
				LastStone = type; LastStoneClick = click;
			end
		end
	elseif type == 4 then -- Firestone
		if FirestoneOnHand then
			SpellStopCasting();
			UseContainerItem(FirestoneLocation[1], FirestoneLocation[2]);
			return;
		else
			if StoneIDInSpellTable[4] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].ID, "spell");
				LastStone = type; LastStoneClick = click;
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoFireStoneSpell, "USER");
			end
		end
	end
	AlphaStoneMenu = 1;
	AlphaStoneVar = GetTime() + 3;
end

-- Handle casts triggered from the demon menu
function Necrosis_PetCast(type, click)
	if type == 8 and InfernalStone == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.InfernalStoneNotPresent, "USER");
		return;
	elseif type == 30 and DemoniacStone == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.DemoniacStoneNotPresent, "USER");
		return;
	elseif type ~= 15 and type ~= 3 and type ~= 8 and type ~= 30 and Soulshards == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.SoulShardNotPresent, "USER");
		return;
	end
	if (type == 3 or type == 4 or type == 5 or type == 6) then 
		LastDemon = type;
		if (click == "RightButton") and (NECROSIS_SPELL_TABLE[15].ID ~= nil) then
			local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell");
			if not (start > 0 and duration > 0) then
				CastSpell(NECROSIS_SPELL_TABLE[15].ID, "spell");
				SpellStopCasting(NECROSIS_SPELL_TABLE[15].Name);
			end
		end
		if NecrosisConfig.DemonSummon and NecrosisConfig.ChatMsg and not NecrosisConfig.SM then
				if NecrosisConfig.PetName[(type - 2)] == " " and NECROSIS_PET_MESSAGE[5] then
					local genericMessages = NECROSIS_PET_MESSAGE[5];
					local genericCount = table.getn(genericMessages);
					if genericCount > 0 then
						local tempnum = random(1, genericCount);
						if genericCount >= 2 then
							while tempnum == PetMess do
								tempnum = random(1, genericCount);
							end
						end
						PetMess = tempnum;
						local lines = genericMessages[tempnum];
						local lineCount = table.getn(lines);
						for i = 1, lineCount, 1 do
							Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY");
						end
					end
				elseif NECROSIS_PET_MESSAGE[(type - 2)] then
					local specificMessages = NECROSIS_PET_MESSAGE[(type - 2)];
					local specificCount = table.getn(specificMessages);
					if specificCount > 0 then
						local tempnum = random(1, specificCount);
						if specificCount >= 2 then
							while tempnum == PetMess do
								tempnum = random(1, specificCount);
							end
						end
						PetMess = tempnum;
						local lines = specificMessages[tempnum];
						local lineCount = table.getn(lines);
						for i = 1, lineCount, 1 do
							Necrosis_Msg(Necrosis_MsgReplace(lines[i], nil , type - 2), "SAY");
						end
					end
				end
		end
	end
	CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell");
	AlphaPetMenu = 1;
	AlphaPetVar = GetTime() + 3;
end

-- Function that shows the different configuration pages
function NecrosisGeneralTab_OnClick(id)
	local TabName;
	for index=1, 5, 1 do
		TabName = getglobal("NecrosisGeneralTab"..index);
		if index == id then
			TabName:SetChecked(1);
		else
			TabName:SetChecked(nil);
		end
	end
	if id == 1 then
		ShowUIPanel(NecrosisShardMenu);
		HideUIPanel(NecrosisMessageMenu);
		HideUIPanel(NecrosisButtonMenu);
		HideUIPanel(NecrosisTimerMenu);
		HideUIPanel(NecrosisGraphOptionMenu);
		NecrosisGeneralIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
		NecrosisGeneralPageText:SetText(NECROSIS_CONFIGURATION.Menu1);
	elseif id == 2 then
		HideUIPanel(NecrosisShardMenu);
		ShowUIPanel(NecrosisMessageMenu);
		HideUIPanel(NecrosisButtonMenu);
		HideUIPanel(NecrosisTimerMenu);
		HideUIPanel(NecrosisGraphOptionMenu);
		NecrosisGeneralIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
		NecrosisGeneralPageText:SetText(NECROSIS_CONFIGURATION.Menu2);
	elseif id == 3 then
		HideUIPanel(NecrosisShardMenu);
		HideUIPanel(NecrosisMessageMenu);
		ShowUIPanel(NecrosisButtonMenu);
		HideUIPanel(NecrosisTimerMenu);
		HideUIPanel(NecrosisGraphOptionMenu);
		NecrosisGeneralIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
		NecrosisGeneralPageText:SetText(NECROSIS_CONFIGURATION.Menu3);
	elseif id == 4 then
		HideUIPanel(NecrosisShardMenu);
		HideUIPanel(NecrosisMessageMenu);
		HideUIPanel(NecrosisButtonMenu);
		ShowUIPanel(NecrosisTimerMenu);
		HideUIPanel(NecrosisGraphOptionMenu);
		NecrosisGeneralIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
		NecrosisGeneralPageText:SetText(NECROSIS_CONFIGURATION.Menu4);
	elseif id == 5 then
		HideUIPanel(NecrosisShardMenu);
		HideUIPanel(NecrosisMessageMenu);
		HideUIPanel(NecrosisButtonMenu);
		HideUIPanel(NecrosisTimerMenu);
		ShowUIPanel(NecrosisGraphOptionMenu);
		NecrosisGeneralIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
		NecrosisGeneralPageText:SetText(NECROSIS_CONFIGURATION.Menu5);
	end
end



-- To support timers on instant spells I had to take inspiration from Cosmos
-- I did not want the mod to depend on Sea, so I reimplemented its helpers
-- Apparently the stand-alone version of ShardTracker did the same :) :)
Necrosis_Hook = function (orig,new,type)
	if(not type) then type = "before"; end
	if(not Hx_Hooks) then Hx_Hooks = {}; end
	if(not Hx_Hooks[orig]) then
		Hx_Hooks[orig] = {}; Hx_Hooks[orig].before = {}; Hx_Hooks[orig].before.n = 0; Hx_Hooks[orig].after = {}; Hx_Hooks[orig].after.n = 0; Hx_Hooks[orig].hide = {}; Hx_Hooks[orig].hide.n = 0; Hx_Hooks[orig].replace = {}; Hx_Hooks[orig].replace.n = 0; Hx_Hooks[orig].orig = getglobal(orig);
	else
		for key,value in Hx_Hooks[orig][type] do if(value == getglobal(new)) then return; end end
	end
	Necrosis_Push(Hx_Hooks[orig][type],getglobal(new)); setglobal(orig,function(...) Necrosis_HookHandler(orig,arg); end);
end

Necrosis_HookHandler = function (name,arg)
	local called = false; local continue = true; local retval;
	for key,value in Hx_Hooks[name].hide do
		if(type(value) == "function") then if(not value(unpack(arg))) then continue = false; end called = true; end
	end
	if(not continue) then return; end
	for key,value in Hx_Hooks[name].before do
		if(type(value) == "function") then value(unpack(arg)); called = true; end
	end
	continue = false;
	local replacedFunction = false;
	for key,value in Hx_Hooks[name].replace do
		if(type(value) == "function") then
			replacedFunction = true; if(value(unpack(arg))) then continue = true; end called = true;
		end
	end
	if(continue or (not replacedFunction)) then retval = Hx_Hooks[name].orig(unpack(arg)); end
	for key,value in Hx_Hooks[name].after do
		if(type(value) == "function") then value(unpack(arg)); called = true;end
	end
	if(not called) then setglobal(name,Hx_Hooks[name].orig); Hx_Hooks[name] = nil; end
	return retval;
end

function Necrosis_Push (table,val)
	if(not table or not table.n) then return nil; end
	table.n = table.n+1;
	table[table.n] = val;
end

function Necrosis_UseAction(id, number, onSelf)
	Necrosis_MoneyToggle();
	NecrosisTooltip:SetAction(id);
	local tip = tostring(NecrosisTooltipTextLeft1:GetText());
	if tip then
		SpellCastName = tip;
		SpellTargetName = UnitName("target");
		if not SpellTargetName then
			SpellTargetName = "";
		end
		SpellTargetLevel = UnitLevel("target");
		if not SpellTargetLevel then
			SpellTargetLevel = "";
		end
	end
end

function Necrosis_CastSpell(spellId, spellbookTabNum)
	local Name, Rank = GetSpellName(spellId, spellbookTabNum);
	if Rank ~= nil then
    		local _, _, Rank2 = string.find(Rank, "(%d+)");
        	SpellCastRank = tonumber(Rank2);
	end
	SpellCastName = Name;
	
	SpellTargetName = UnitName("target");
	if not SpellTargetName then
		SpellTargetName = "";
	end
	SpellTargetLevel = UnitLevel("target");
	if not SpellTargetLevel then
		SpellTargetLevel = "";
	end
end

function Necrosis_CastSpellByName(Spell)
	local _, _, Name = string.find(Spell, "(.+)%(");
	local _, _, Rank = string.find(Spell, "([%d]+)");
	
	if Rank ~= nil then
    		local _, _, Rank2 = string.find(Rank, "(%d+)");
        	SpellCastRank = tonumber(Rank2);
	end

	if not Name then
		_, _, Name = string.find(Spell, "(.+)");
	end
	SpellCastName = Name;
	
	SpellTargetName = UnitName("target");
	if not SpellTargetName then
		SpellTargetName = "";
	end
	SpellTargetLevel = UnitLevel("target");
	if not SpellTargetLevel then
		SpellTargetLevel = "";
	end
end

function NecrosisTimer(nom, duree)
	local Cible = UnitName("target");
	local Niveau = UnitLevel("target");
	local truc = 6;
	if not Cible then
		Cible = "";
		truc = 2;
	end
	if not Niveau then
		Niveau = "";
	end

	SpellGroup, SpellTimer, TimerTable = NecrosisTimerX(nom, duree, truc, Cible, Niveau, SpellGroup, SpellTimer, TimerTable);
end

function NecrosisSpellCast(name)
	if string.find(name, "coa") then
		SpellCastName = NECROSIS_SPELL_TABLE[22].Name;
		SpellTargetName = UnitName("target");
		if not SpellTargetName then
			SpellTargetName = "";
		end
		SpellTargetLevel = UnitLevel("target");
		if not SpellTargetLevel then
			SpellTargetLevel = "";
		end
		CastSpell(NECROSIS_SPELL_TABLE[22].ID, "spell");
	end	
end
