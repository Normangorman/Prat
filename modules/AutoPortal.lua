--[[
Name: Prat_AutoPotal
Revision: $Revision: 16019 $
Author(s): Normangorman
Description: Module for Prat that automatically invites someone to your group if they are asking for a portal, and sends them a whisper saying you will port them.
Dependencies: Prat

Credit goes to: CleanChat
]]

local L = AceLibrary("AceLocale-2.2"):new("PratAutoPortal")

L:RegisterTranslations("enUS", function() return {
    ["AutoPortal"] = true,
    ["Automatically invites someone to your group if they're asking for a portal."] = true,
    ["Toggle"] = true,
    ["Toggle the module on and off."] = true,
} end)

Prat_AutoPortal = Prat:NewModule("AutoPortal")

function Prat_AutoPortal:OnInitialize()
    self.db = Prat:AcquireDBNamespace("AutoPortal")
    Prat:RegisterDefaults("AutoPortal", "profile", {
        on = true,
        show = {true, false, false, false, false, false, false},
		showmode = "INDIVIDUAL",
        showall = false,
        nickname = "",
        activeZones = {
            ["Stormwind City"]=true,
            ["City of Ironforge"]=true,
            ["Darnassus"]=true,
            ["Orgrimmar"]=true,
            ["Undercity"]=true
        }
    })
    Prat.Options.args.AutoPortal = {
        name = L["AutoPortal"],
        desc = L["Automatically invites someone to your group if they're asking for a portal."],
        type = "group",
        args = {
            Toggle = {
                type = "toggle",
                name = L["Toggle"],
                desc = L["Toggle the module on and off."],
                get = function() return self.db.profile.on end,
                set = function(v) self.db.profile.on = Prat:ToggleModuleActive("AutoPortal") end
            }     
        }        
    }
end

function Prat_AutoPortal:OnEnable()
    DEFAULT_CHAT_FRAME:AddMessage("AutoPortal engaged.")

    --for i=1,NUM_CHAT_WINDOWS do
	--	self:SetFrameStatus(i)
    --end
    
    for i=1,NUM_CHAT_WINDOWS do
        local frame = getglobal("ChatFrame"..i)

        if self.db.profile.show[i] then
            if not self:IsHooked(frame, "AddMessage") then self:SecureHook(frame, "AddMessage") end
        else
            if self:IsHooked(frame, "AddMessage") then self:Unhook(frame, "AddMessage") end
        end
    end

    self.playerName = UnitName("player");
end

function Prat_AutoPortal:OnDisable()
end

function Prat_AutoPortal:SetFrameStatus(id)
	local frame = getglobal("ChatFrame"..id)

    if self.db.profile.show[id] then
    	if not self:IsHooked(frame, "AddMessage") then self:SecureHook(frame, "AddMessage") end
    else
        if self:IsHooked(frame, "AddMessage") then self:Unhook(frame, "AddMessage") end
    end
end

function Prat_AutoPortal:AddMessage(frame, text, r, g, b, id)
    if not text then
        return
    elseif string.len(text) < 10 then
        return
    elseif GetNumPartyMembers() ~= 0 or GetNumRaidMembers() ~= 0 then
        --DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: Not alone so ignoring message.")
        return
    elseif not self.db.profile.activeZones[GetZoneText()] then
        --DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: Not in an active zone so ignoring message.")
        return
    elseif string.find(text, "AutoPortal") then
        -- Prevents this function being recursively called
        return
    end

    local chatMsgNum = string.sub(text, 2, 2)
    if chatMsgNum ~= "1" and chatMsgNum ~= "2" and chatMsgNum ~= "3" and chatMsgNum ~= "Y" then
        --DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: Message is not general/trade/world/yell so ignoring.")
        return
    end

    local triggerWords = {["wtb"]=true, ["lf"]=true, ["need"]=true} -- the first word in the message must be one of these words
    local keywords = {
        ["mage"]=true,
        ["port"]=true,
        ["portal"]=true,
        ["darn"]=true,
        ["darna"]=true,
        ["darnassus"]=true,
        ["darnasus"]=true,
        ["sw"]=true,
        ["stormwind"]=true,
        ["1g"]=true
    }
    local keywordCount = 0
    local keywordThreshold = 2 -- at least this many keywords must be in the message

    local chatMsg = string.gsub(text, ".*>: ", "") -- TODO: This only works for angled bracket messages
    local chatMsgWords = Prat.stringTokenize(string.lower(chatMsg), "[^%s%p]+")

    local firstChatWord = chatMsgWords[1]
    if not triggerWords[firstChatWord] then
        --DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: First word ("..firstChatWord..") is not trigger word.")
        return
    else
        for i=2, table.getn(chatMsgWords) do
            local chatWord = chatMsgWords[i]
            if keywords[chatWord] then
                keywordCount = keywordCount + 1
            end
        end

        DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: keywordCount "..keywordCount)
    end

    local playerName = string.gsub(text, ".*|Hplayer:(.-)|h.*", "%1")
    if keywordCount >= keywordThreshold and playerName and playerName ~= self.playerName then
        PlaySound("FriendJoinGame");
        DEFAULT_CHAT_FRAME:AddMessage("AutoPortal: Player "..playerName.." wants portal (keyword count "..keywordCount..")")
        InviteByName(playerName)
        SendChatMessage("I can port you.", "WHISPER", nil, playerName)
    end
end
