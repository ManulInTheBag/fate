modifier_love_spot_charmed = class({})

function modifier_love_spot_charmed:RemoveOnDeath()
	return true 
end

function modifier_love_spot_charmed:IsHidden()
	return true
end

function modifier_love_spot_charmed:IsDebuff()
	return true
end

function modifier_love_spot_charmed:OnCreated(args)
	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_love_spot_charmed:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		caster:StopSound("Hero_Warlock.ShadowWord")
	end
end

function modifier_love_spot_charmed:OnIntervalThink()
	local target = self:GetParent()
	local caster = self:GetCaster()
	local forcemove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION ,
		Position = nil
	}
	giveUnitDataDrivenModifier(caster, target, "silenced",0.25)
	giveUnitDataDrivenModifier(caster, target, "disarmed",0.25)
	forcemove.UnitIndex = target:entindex()
	forcemove.Position = caster:GetAbsOrigin() 
	target:Stop()
	ExecuteOrderFromTable(forcemove) 
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())

end