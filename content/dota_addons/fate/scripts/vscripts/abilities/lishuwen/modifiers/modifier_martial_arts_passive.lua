modifier_martial_arts_passive = class({})

function modifier_martial_arts_passive:OnCreated(keys)
	self.ManaBurnAmount = keys.ManaBurnAmount
end

function modifier_martial_arts_passive:DeclareFunctions()
	local funcs = {	--MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
	return funcs
end

function modifier_martial_arts_passive:OnAttackLanded(keys)	
	if IsServer() then
		if keys.attacker ~= self:GetParent() then return end
		local caster = self:GetParent()
		local target = keys.target

		--if caster:FindAbilityByName("lishuwen_no_second_strike"):IsCooldownReady() then return end

		DoDamage(caster, target, self.ManaBurnAmount, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
		
		target:EmitSound("Hero_Antimage.ManaBreak")

		if target:GetName() == "npc_dota_hero_juggernaut" then
			self:BurnTargetMana(target, 25)
		else
			self:BurnTargetMana(target, self.ManaBurnAmount)
		end
	end
end

function modifier_martial_arts_passive:BurnTargetMana(target, amount)
	if target:GetMana() - amount > 0 then
		target:SetMana(target:GetMana() - amount)
	else
		target:SetMana(0)
	end
end


function modifier_martial_arts_passive:IsHidden()
	return false
end

function modifier_martial_arts_passive:IsDebuff()
	return false
end

function modifier_martial_arts_passive:RemoveOnDeath()
	return false
end

function modifier_martial_arts_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
