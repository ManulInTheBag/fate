modifier_mass_recall = class({})

if IsServer() then
	function modifier_mass_recall:OnDestroy()
		if self:GetParent():IsAlive() then
			local caster = self:GetCaster()
			local parent = self:GetParent()

			parent:SetAbsOrigin(caster:GetAbsOrigin() + RandomVector(100))
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
		end
	end
end

function modifier_mass_recall:GetEffectName()
	return "particles/units/heroes/hero_chen/chen_teleport.vpcf"
end

function modifier_mass_recall:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mass_recall:IsHidden()
	return false
end

function modifier_mass_recall:IsDebuff()
	return false
end

function modifier_mass_recall:RemoveOnDeath()
	return true 
end
