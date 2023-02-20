-----------------------------
--    Modifier: Shirou Avalon    --
-----------------------------

modifier_artoria_ultimate_shirou_avalon = class({})

function modifier_artoria_ultimate_shirou_avalon:OnCreated()
		range = self:GetAbility():GetSpecialValueFor("range")
		damage = self:GetAbility():GetSpecialValueFor("damage")
		damage_threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
		stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
		ability = self:GetAbility()
		
	if not IsServer() then return end
end

function modifier_artoria_ultimate_shirou_avalon:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_artoria_ultimate_shirou_avalon:OnTakeDamage(args)
	local caster = self:GetParent() 
	local attacker = args.attacker
	
	local caster_position = caster:GetAbsOrigin()
	local attacker_position = attacker:GetAbsOrigin()
	local damage_taken = args.damage
	
	local currentHealth = caster:GetHealth()
	
	caster:SetHealth(currentHealth + args.damage)
end

function modifier_artoria_ultimate_shirou_avalon:IsHidden()
	return false
end

function modifier_artoria_ultimate_shirou_avalon:RemoveOnDeath()
	return true
end

function modifier_artoria_ultimate_shirou_avalon:IsDebuff()
	return false 
end

function modifier_artoria_ultimate_shirou_avalon:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artoria_ultimate_shirou_avalon:GetEffectName()
	return "particles/custom/artoria/ultimate_avalon_buff.vpcf"
end

function modifier_artoria_ultimate_shirou_avalon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end