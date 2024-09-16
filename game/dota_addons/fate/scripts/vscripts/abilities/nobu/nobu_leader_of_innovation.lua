LinkLuaModifier("modifier_nobu_innovation_aura", "abilities/nobu/nobu_leader_of_innovation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_innovation", "abilities/nobu/nobu_leader_of_innovation", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_nobu_innovation_ms", "abilities/nobu/nobu_leader_of_innovation", LUA_MODIFIER_MOTION_NONE) 
nobu_leader_of_innovation = class({})

function nobu_leader_of_innovation:OnSpellStart()
    local hCaster = self:GetCaster()
	hCaster:EmitSound("nobu_innovation_cast")
    hCaster:AddNewModifier(hCaster, self, "modifier_nobu_innovation_aura", {duration = self:GetSpecialValueFor("duration")} )
end
 
 

modifier_nobu_innovation_aura = class({})

function modifier_nobu_innovation_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end


function modifier_nobu_innovation_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_nobu_innovation_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_nobu_innovation_aura:GetAuraRadius()
 
		return self:GetAbility():GetSpecialValueFor("aura_radius")  
 
end

function modifier_nobu_innovation_aura:GetEffectName()
    return "particles/units/heroes/hero_legion_commander/legion_commander_press.vpcf"
end


function modifier_nobu_innovation_aura:GetModifierAura()
	return "modifier_nobu_innovation"
end

function modifier_nobu_innovation_aura:IsHidden()
	return true
end

function modifier_nobu_innovation_aura:RemoveOnDeath()
	return true
end

function modifier_nobu_innovation_aura:IsDebuff()
	return false 
end

function modifier_nobu_innovation_aura:IsAura()
 		return true
end

function modifier_nobu_innovation_aura:GetAttributes()
    return   MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
 

modifier_nobu_innovation = class({})

function modifier_nobu_innovation:OnCreated()
	if(self:GetParent() == self:GetCaster()) then
		self:GetCaster().IsReadyToHeal = true  
	end

end

function modifier_nobu_innovation:IsHidden() return false end
function modifier_nobu_innovation:IsDebuff() return false end
 

 

function modifier_nobu_innovation:OnTakeDamage(args)
    local parent =self:GetParent()
    local caster = self:GetCaster()
    if(  args.attacker == caster   )then
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("aura_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			v:AddNewModifier(caster, self:GetAbility(), "modifier_nobu_innovation_ms", { Duration = self:GetAbility():GetSpecialValueFor("ms_duration") })
			v:SetHealth(v:GetHealth() + self:GetAbility():GetSpecialValueFor("health_base") + caster:GetStrength())
		end
	 
		 
		return 
	end
	if(  args.attacker:GetTeamNumber() == caster:GetTeamNumber() and caster.IsReadyToHeal)then
		caster.IsReadyToHeal = false
		caster:SetHealth(caster:GetHealth() + self:GetAbility():GetSpecialValueFor("health_base") + caster:GetStrength())
		Timers:CreateTimer(1, function()
		caster.IsReadyToHeal = true
		end)

	end
end


modifier_nobu_innovation_ms = class({})
 
function modifier_nobu_innovation_ms:IsHidden() return false end
function modifier_nobu_innovation_ms:IsDebuff() return false end
 
function modifier_nobu_innovation_ms:DeclareFunctions()
	return { 
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		 
				}
end
function modifier_nobu_innovation_ms:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end
