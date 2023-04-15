modifier_perfect_agony_penalty = class({})

LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)

function modifier_perfect_agony_penalty:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

function modifier_perfect_agony_penalty:OnAttackLanded(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()
		local target = args.target

		if caster:GetMana() > 25 then
			local stacks = 0
			if target:HasModifier("modifier_weakening_venom") then 
				stacks = target:GetModifierStackCount("modifier_weakening_venom", ability)
			end		

			local dirkAbility = caster:FindAbilityByName("true_assassin_dirk")
			local fPoisonDamage = dirkAbility:GetSpecialValueFor("poison_dot")
				
			target:RemoveModifierByName("modifier_weakening_venom") 
			target:AddNewModifier(caster, dirkAbility, "modifier_weakening_venom", { duration = 12 })
			target:SetModifierStackCount("modifier_weakening_venom", dirkAbility, stacks + 1)

			local modifier = target:AddNewModifier(caster, dirkAbility, "modifier_dirk_poison", {	Duration = dirkAbility:GetSpecialValueFor("duration"),
																		PoisonDamage = fPoisonDamage,
																		PoisonSlow = dirkAbility:GetSpecialValueFor("poison_slow") })

			if not dirkAbility:IsCooldownReady() then
				local dirkCooldown = dirkAbility:GetCooldownTimeRemaining()
				dirkAbility:EndCooldown()

				if dirkCooldown > 1 then
					dirkAbility:StartCooldown(dirkCooldown - 1)
				end
			end
		end
	end
end

function modifier_perfect_agony_penalty:IsHidden()
	return false
end

function modifier_perfect_agony_penalty:IsDebuff()
	return false
end

function modifier_perfect_agony_penalty:RemoveOnDeath()
	return false
end

function modifier_perfect_agony_penalty:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_perfect_agony_penalty:GetTexture()
	return "custom/true_assassin_attribute_weakening_venom"
end