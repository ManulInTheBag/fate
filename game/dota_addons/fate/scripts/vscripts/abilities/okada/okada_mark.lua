LinkLuaModifier("modifier_okada_mark", "abilities/okada/okada_mark", LUA_MODIFIER_MOTION_NONE)
okada_mark = class({})



function okada_mark:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function okada_mark:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	local rCooldown = 0
	
	if not IsSpellBlocked(target) then
		--target:AddNewModifier(caster, self, "modifier_silence", {duration = 3})
		giveUnitDataDrivenModifier(caster, target, "revoked", self:GetSpecialValueFor("revoke_duration"))
		giveUnitDataDrivenModifier(caster, caster, "revoked", self:GetSpecialValueFor("revoke_duration"))
		--ApplyStrongDispel(target)
		target:AddNewModifier(caster, self, "modifier_okada_mark", {duration = self:GetSpecialValueFor("vision_duration")})
		caster:AddNewModifier(caster, self, "modifier_okada_mark", {duration = self:GetSpecialValueFor("vision_duration")})
	end
end



modifier_okada_mark = class({})
function modifier_okada_mark:IsHidden() return false end
function modifier_okada_mark:IsDebuff() return false end
function modifier_okada_mark:RemoveOnDeath() return true end


function modifier_okada_mark:GetEffectName()
	return "particles/zlodemon/zlodemon_overhead_okada_mark.vpcf"
end

function modifier_okada_mark:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


function modifier_okada_mark:CheckState()
	return {					[MODIFIER_STATE_INVISIBLE] = false,}
end

function modifier_okada_mark:GetModifierProvidesFOWVision()
    return  1
end
function modifier_okada_mark:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION  
           }
end

function modifier_okada_mark:GetFixedDayVision()
    return  0
end
function modifier_okada_mark:GetFixedNightVision()
    return  0
end