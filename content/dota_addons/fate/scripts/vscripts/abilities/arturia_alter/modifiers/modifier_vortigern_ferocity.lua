modifier_vortigern_ferocity = class({})

function modifier_vortigern_ferocity:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = caster:FindAbilityByName("saber_alter_vortigern")

		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
	end
end

function modifier_vortigern_ferocity:IsHidden()
	return false
end

function modifier_vortigern_ferocity:IsDebuff()
	return false
end

function modifier_vortigern_ferocity:RemoveOnDeath()
	return true
end

function modifier_vortigern_ferocity:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_vortigern_ferocity:GetTexture()
	return "custom/saber_alter_vortigern"
end
