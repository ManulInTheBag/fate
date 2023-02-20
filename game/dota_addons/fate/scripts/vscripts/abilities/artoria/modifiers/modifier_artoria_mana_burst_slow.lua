-----------------------------
--    Modifier: Mana Burst Slow    --
-----------------------------

modifier_artoria_mana_burst_slow = class({})

-- Classification --
function modifier_artoria_mana_burst_slow:OnCreated( kv )
	if IsServer() then
		local target = self:GetParent()
		slow_amount = self:GetAbility():GetSpecialValueFor("slow_amount")

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_arcane_bolt_birds.vpcf", PATTACH_POINT_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(particle,	0,	target,	PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 300), true)
		ParticleManager:SetParticleControlEnt(particle,	1,	target,	PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 300), true)
		ParticleManager:SetParticleControlEnt(particle,	2,	target,	PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 300), true)
		ParticleManager:SetParticleControlEnt(particle,	3,	target,	PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 300), true)
    	self:AddParticle(particle, false, false, -1, false, false)
	end
end

function modifier_artoria_mana_burst_slow:IsHidden()
	return true
end

function modifier_artoria_mana_burst_slow:IsDebuff()
	return true
end

function modifier_artoria_mana_burst_slow:IsStunDebuff()
	return false
end

function modifier_artoria_mana_burst_slow:IsPurgable()
	return true
end

function modifier_artoria_mana_burst_slow:RemoveOnDeath()
    return true
end

-- Modifier Effects --
function modifier_artoria_mana_burst_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_artoria_mana_burst_slow:GetModifierMoveSpeedBonus_Percentage()
	return slow_amount
end