LinkLuaModifier("modifier_jeanne_witch_aura", "abilities/jeanne_alter/jeanne_witch", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_witch", "abilities/jeanne_alter/jeanne_witch", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_witch_checker", "abilities/jeanne_alter/jeanne_witch", LUA_MODIFIER_MOTION_NONE)

jeanne_witch = class({})

function jeanne_witch:GetIntrinsicModifierName()
	return "modifier_jeanne_witch_aura"
end

function jeanne_witch:GetAOERadius()
	return self:GetSpecialValueFor("aura_radius")
end

function jeanne_witch:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_jeanne_witch_checker", {duration = self:GetSpecialValueFor("duration")})
end

--

modifier_jeanne_witch_aura = class({})

function modifier_jeanne_witch_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_jeanne_witch_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_jeanne_witch_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_jeanne_witch_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_jeanne_witch_aura:GetModifierAura()
	return "modifier_jeanne_witch"
end

function modifier_jeanne_witch_aura:IsHidden()
	return true
end

function modifier_jeanne_witch_aura:RemoveOnDeath()
	return false
end

function modifier_jeanne_witch_aura:IsDebuff()
	return false 
end

function modifier_jeanne_witch_aura:IsAura()
	return true 
end

function modifier_jeanne_witch_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--

modifier_jeanne_witch = class({})

function modifier_jeanne_witch:IsHidden() return false end
function modifier_jeanne_witch:IsDebuff() return false end
function modifier_jeanne_witch:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end
function modifier_jeanne_witch:GetModifierTotalDamageOutgoing_Percentage()
	if self:GetAbility():GetCaster():HasModifier("modifier_jeanne_witch_checker") then
		return self:GetAbility():GetSpecialValueFor("improved_value")
	end
	return self:GetAbility():GetSpecialValueFor("base_value")
end

function modifier_jeanne_witch:GetTexture()
    return "custom/jeanne_alter/jeanne_dragon"
end

--

modifier_jeanne_witch_checker = class({})

function modifier_jeanne_witch_checker:IsHidden()
	return false 
end

function modifier_jeanne_witch_checker:RemoveOnDeath()
	return false
end

function modifier_jeanne_witch_checker:IsDebuff()
	return false 
end



LinkLuaModifier("modifier_jalter_model_swap", "abilities/jeanne_alter/jeanne_witch", LUA_MODIFIER_MOTION_NONE)
--NOTE: Function to handle swapping between models in-game.
if IsServer() then
    if type(jalter_abilities_chat_event) == "number" then
        StopListeningToGameEvent(jalter_abilities_chat_event)
    end
    --===--
    _G.jalter_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
        local nPlayerID = tEventTable.playerid
        local sText     = tEventTable.text
        local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
        if not (hHero:GetName() == "npc_dota_hero_razor") then
            return
        end
        if IsNotNull(hHero) then
            if sText == "-jalter1" then
                hHero:RemoveModifierByName("modifier_jalter_model_swap")
            end
            if sText == "-jalter2" then
                if GameRules:GetDOTATime(false, false) <= 300 then --300
                    hHero:AddNewModifier(hHero, nil, "modifier_jalter_model_swap", {})
                end
            end
        end
    end, nil)
end


modifier_jalter_model_swap = modifier_jalter_model_swap or class({})

function modifier_jalter_model_swap:IsHidden()                                                                       return true end
function modifier_jalter_model_swap:IsDebuff()                                                                       return false end
function modifier_jalter_model_swap:IsPurgable()                                                                     return false end
function modifier_jalter_model_swap:IsPurgeException()                                                               return false end
function modifier_jalter_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_jalter_model_swap:IsDimensionException()                                                           return true end
function modifier_jalter_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_jalter_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_jalter_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_jalter_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_jalter_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if IsServer() then
        self.sModelName = "models/zlodemon/alter_jaba/jeanne_alter.vmdl"
    end
end
function modifier_jalter_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end

--========================================--
