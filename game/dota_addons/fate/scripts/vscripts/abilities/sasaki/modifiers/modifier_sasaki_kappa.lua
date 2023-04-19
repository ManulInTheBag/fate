LinkLuaModifier("modifier_sasaki_kappa_cd", "abilities/sasaki/modifiers/modifier_sasaki_kappa", LUA_MODIFIER_MOTION_NONE)

modifier_sasaki_kappa = class({})

function modifier_sasaki_kappa:IsHidden()
	return false
end

function modifier_sasaki_kappa:IsDebuff()
	return false
end

function modifier_sasaki_kappa:RemoveOnDeath()
	return true
end

function modifier_sasaki_kappa:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sasaki_kappa:GetTexture()
	return "custom/false_assassin_minds_eye"
end

function modifier_sasaki_kappa:OnCreated(keys)
	if IsServer() then
		local caster = self:GetParent()
		caster:Stop()
		caster:AddNewModifier(caster, self:GetAbility(), "modifier_sasaki_kappa_cd", {duration = 120})
		
		self.Break = false
		self.BreakDelay = 1
	end
end

function modifier_sasaki_kappa:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = true, }
end

function modifier_sasaki_kappa:DeclareFunctions()
	local funcs = {	MODIFIER_EVENT_ON_ATTACK_START,
					MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
					MODIFIER_EVENT_ON_UNIT_MOVED}
	return funcs
end

function modifier_sasaki_kappa:OnAttackStart(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.attacker ~= caster then return end
		self:Destroy()
	end	
end

function modifier_sasaki_kappa:OnAbilityFullyCast(keys)
	if IsServer() then
		local caster = self:GetParent()
		
		if keys.unit == caster then 
			 if keys.ability:GetName() ~= "false_assassin_presence_concealment" then
                self:Destroy()
            end
		end
	end	
end

function modifier_sasaki_kappa:OnTakeDamage(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit ~= caster then return end
		self:Destroy()
	end	
end

function modifier_sasaki_kappa:OnUnitMoved(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit ~= caster then return end

		if not self.Break then
			self:StartIntervalThink(self.BreakDelay)
			self.Break = true
		end
	end
end

function modifier_sasaki_kappa:OnIntervalThink()
	self:Destroy()
end

function modifier_sasaki_kappa:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()

	    if caster:HasModifier("modifier_sasaki_kappa_cd") then
	    	caster:RemoveModifierByName("modifier_sasaki_kappa_cd")
	    end
	end
end

function modifier_sasaki_kappa:IsHidden()
	return false
end

function modifier_sasaki_kappa:IsDebuff()
	return false
end

function modifier_sasaki_kappa:RemoveOnDeath()
	return true
end

function modifier_sasaki_kappa:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sasaki_kappa:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_sasaki_kappa:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_sasaki_kappa_cd = class({})

function modifier_sasaki_kappa_cd:IsHidden()
	return true
end

function modifier_sasaki_kappa_cd:IsDebuff()
	return false
end

function modifier_sasaki_kappa_cd:RemoveOnDeath()
	return true
end

function modifier_sasaki_kappa_cd:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sasaki_kappa_cd:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1)
	end
end

function modifier_sasaki_kappa_cd:OnIntervalThink()
	local caster = self:GetCaster()

	if caster == nil then return end

	for i = 0,5 do
		local ability = caster:GetAbilityByIndex(i)
		local cooldown = ability:GetCooldownTimeRemaining()

		if not ability:IsCooldownReady() then
			ability:EndCooldown()
			ability:StartCooldown(cooldown - 1)
		end
	end
end