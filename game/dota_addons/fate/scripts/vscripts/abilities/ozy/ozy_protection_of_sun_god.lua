ozy_protection_of_sun_god = class({})
LinkLuaModifier("modifier_barrier_new","modifiers/modifier_barrier_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_barrier_prock","abilities/ozy/ozy_protection_of_sun_god", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_barrier_particle","abilities/ozy/ozy_protection_of_sun_god", LUA_MODIFIER_MOTION_NONE)
function ozy_protection_of_sun_god:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

IsNotNull = function(hScript)
    local sType = type(hScript)
    if sType ~= "nil" then
        if sType == "table" 
            and type(hScript.IsNull) == "function" then
            return not hScript:IsNull()
        end
        return true
    end
    return false
end

function ozy_protection_of_sun_god:OptionalDestroy(parent)
	Timers:CreateTimer(FrameTime() * 2, function() 
		if not IsNotNull(parent:FindModifierByNameAndCaster("modifier_barrier_new", self:GetCaster())) then
			parent:RemoveModifierByName("modifier_ozy_barrier_particle")
		end

	end)
end

function ozy_protection_of_sun_god:Counter(parent)
	local targets = FindUnitsInRadius(self:GetCaster():GetTeam(), parent:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
 		DoDamage(parent, v, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)
		v:AddNewModifier(self:GetCaster(), self, "modifier_ozy_barrier_prock", { Duration =  self:GetSpecialValueFor("slow_duration")})            
	end
	EmitSoundOn("ozy_protection_explosion", parent)
	if IsNotNull(parent:FindModifierByName("modifier_ozy_barrier_particle")) then
		if not IsNotNull(parent:FindModifierByNameAndCaster("modifier_barrier_new", self:GetCaster())) then
			parent:RemoveModifierByName("modifier_ozy_barrier_particle")
		end
	end
	local FlashParticle = ParticleManager:CreateParticle("particles/ozy/ozy_flash_barrier.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl(FlashParticle, 0, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(FlashParticle)
	
end

function ozy_protection_of_sun_god:OnSpellStart()
	local targetPoint = self:GetCursorPosition()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local shield_amount = self:GetSpecialValueFor("barrier")

	if caster.ozySa4Acquired then
		 EmitSoundOn("ozy_protection", caster)
		caster:AddNewModifier(caster, self, "modifier_ozy_barrier_particle", { Duration =  self:GetSpecialValueFor("duration")})            
		caster:AddNewModifier(caster, self, "modifier_barrier_new", { Duration =  self:GetSpecialValueFor("duration"), decreaseDamageOnProck = 0, beforeBScroll = true, ShouldEndChannel = false, debuff_immune = false, shield_amount =shield_amount, HasCounter = true })            
	end
		
	local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

	for k,v in pairs(targets) do
		v:AddNewModifier(caster, self, "modifier_ozy_barrier_particle", { Duration =  self:GetSpecialValueFor("duration")})            
		EmitSoundOn("ozy_protection", v)
		
		v:AddNewModifier(caster, self, "modifier_barrier_new", { Duration =  self:GetSpecialValueFor("duration"), decreaseDamageOnProck = 0, beforeBScroll = true, ShouldEndChannel = false, debuff_immune = false, shield_amount =shield_amount, HasCounter = true })            
	end


end

modifier_ozy_barrier_prock = class({})

function modifier_ozy_barrier_prock:IsHidden() return false end
function modifier_ozy_barrier_prock:IsDebuff() return true end



function modifier_ozy_barrier_prock:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_MISS_PERCENTAGE 
			}
end
function modifier_ozy_barrier_prock:GetModifierMoveSpeedBonus_Percentage()
	return  -self:GetAbility():GetSpecialValueFor("slow_percentage")
end

function modifier_ozy_barrier_prock:GetModifierMiss_Percentage()
	return  self:GetAbility():GetSpecialValueFor("blind")
end

function modifier_ozy_barrier_prock:GetEffectName()
    return "particles/ozy/ozy_blind.vpcf"
end
function modifier_ozy_barrier_prock:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end

modifier_ozy_barrier_particle = class({})

function modifier_ozy_barrier_particle:IsHidden() return true end
function modifier_ozy_barrier_particle:IsDebuff() return false end



function modifier_ozy_barrier_particle:GetEffectName()
    return "particles/ozy/sun_god_barrier.vpcf"
end
function modifier_ozy_barrier_particle:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end