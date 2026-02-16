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
		target:SetDayTimeVisionRange(self:GetSpecialValueFor("target_vision"))
		target:SetNightTimeVisionRange(self:GetSpecialValueFor("target_vision"))
		caster:SetDayTimeVisionRange(50)
		caster:SetNightTimeVisionRange(50)
		--target:AddNewModifier(caster, self, "modifier_silence", {duration = 3})
		giveUnitDataDrivenModifier(caster, target, "revoked", self:GetSpecialValueFor("revoke_duration"))
		giveUnitDataDrivenModifier(caster, caster, "revoked", self:GetSpecialValueFor("revoke_duration"))
		target:AddNewModifier(caster, self, "modifier_muted", {duration = self:GetSpecialValueFor("mute_duration")})
		--ApplyStrongDispel(target)
		target:AddNewModifier(caster, self, "modifier_okada_mark", {duration = self:GetSpecialValueFor("vision_duration")})
		caster:AddNewModifier(caster, self, "modifier_okada_mark", {duration = self:GetSpecialValueFor("vision_duration")})
	end
end



modifier_okada_mark = class({})
function modifier_okada_mark:IsHidden() return false end
function modifier_okada_mark:IsDebuff() return true end
function modifier_okada_mark:RemoveOnDeath() return true end

function modifier_okada_mark:OnCreated()
	local particle = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_overhead_okada_mark.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:SetParticleShouldCheckFoW(particle, false)
    self:AddParticle(particle, true, false, -1, false, true)

end

function modifier_okada_mark:OnDestroy()
	
	self:GetParent():SetDayTimeVisionRange(1000)
	self:GetParent():SetNightTimeVisionRange(1000)
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
		   
           }
end

