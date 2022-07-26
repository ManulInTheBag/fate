modifier_calydonian_hunt_sight = class({})

--[[function modifier_calydonian_hunt_sight:OnCreated(table)
	self:GetParent()
end]]

function modifier_calydonian_hunt_sight:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

--function modifier_calydonian_hunt_sight:CheckState()
--end

function modifier_calydonian_hunt_sight:GetModifierProvidesFOWVision()
	if self:GetParent():HasModifier("modifier_murderer_mist_in") then
		return 0
	end
    return 1
end

function modifier_calydonian_hunt_sight:IsDebuff()
    return true
end

function modifier_calydonian_hunt_sight:RemoveOnDeath()
    return true
end

function modifier_calydonian_hunt_sight:GetTexture()
    return "custom/atalanta_calydonian_hunt"
end

-----------------------

modifier_calydonian_hunt_pepe = class({})

function modifier_calydonian_hunt_pepe:IsDebuff()
    return true
end

function modifier_calydonian_hunt_pepe:IsHidden()
    return true
end

function modifier_calydonian_hunt_pepe:RemoveOnDeath()
    return true
end

function modifier_calydonian_hunt_pepe:GetTexture()
    return "custom/atalanta_calydonian_hunt"
end

--------------------------

modifier_calydonian_hunt_sight_2 = class({})

--[[function modifier_calydonian_hunt_sight:OnCreated(table)
    self:GetParent()
end]]

function modifier_calydonian_hunt_sight_2:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_calydonian_hunt_sight_2:OnCreated()
    self.hp_perc = self:GetParent():GetHealthPercent()
    self:StartIntervalThink(FrameTime()*2)
end

function modifier_calydonian_hunt_sight_2:OnIntervalThink()
    self:Destroy()
end
--function modifier_calydonian_hunt_sight:CheckState()
--end

function modifier_calydonian_hunt_sight_2:GetModifierProvidesFOWVision()
    if self:GetParent():HasModifier("modifier_murderer_mist_in") then
        return 0
    end
    if self.hp_perc <= 60 then
        return 1
    end
    return 0
end

function modifier_calydonian_hunt_sight_2:IsHidden() --somehow does not actually work because of gaben, visibility depends only on modifier duration, how - no actual idea
    --[[if self:GetParent():HasModifier("modifier_murderer_mist_in") then
        return 1
    end
    if self.hp_perc <= 60 then
        return 0
    end]]
    return true
end

function modifier_calydonian_hunt_sight_2:IsDebuff()
    return true
end

function modifier_calydonian_hunt_sight_2:RemoveOnDeath()
    return true
end

function modifier_calydonian_hunt_sight_2:GetTexture()
    return "custom/atalanta_calydonian_hunt"
end

-----------made this non aura because fuck volvo

LinkLuaModifier("modifier_calydonian_hunt_sight_2", "abilities/atalanta/modifiers/modifier_calydonian_hunt_sight", LUA_MODIFIER_MOTION_NONE)

modifier_calydonian_hunt_aura = class({})

function modifier_calydonian_hunt_aura:OnCreated()
    self:StartIntervalThink(FrameTime())
end

function modifier_calydonian_hunt_aura:OnIntervalThink()
    local caster = self:GetParent()
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetAbility():GetSpecialValueFor("passive_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for _,v in pairs(targets) do
        v:RemoveModifierByName("modifier_calydonian_hunt_sight_2")
        v:AddNewModifier(caster, self:GetAbility(), "modifier_calydonian_hunt_sight_2", {duration = FrameTime()*2})
    end
end

function modifier_calydonian_hunt_aura:IsHidden()
    return true
end

function modifier_calydonian_hunt_aura:RemoveOnDeath()
    return false
end

function modifier_calydonian_hunt_aura:IsDebuff()
    return false 
end