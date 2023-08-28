LinkLuaModifier("modifier_okita_weak_constitution","abilities/okita/okita_weak_constitution", LUA_MODIFIER_MOTION_NONE)

okita_weak_constitution = class({})

--[[function okita_weak_constitution:GetIntrinsicModifierName()
	return "modifier_okita_weak_constitution"
end]]

function okita_weak_constitution:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("dark_willow_sylph_move_pain_01")

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if (caster:GetAbilityByIndex(5):GetName()=="okita_sandanzuki") and caster:FindAbilityByName("okita_sandanzuki"):IsCooldownReady() and caster:FindAbilityByName("okita_zekken"):IsCooldownReady() then
			if not caster:HasModifier("modifier_okita_window") then
				caster:SwapAbilities("okita_zekken", "okita_sandanzuki", true, false)
				caster:AddNewModifier(caster, self, "modifier_okita_window", {duration = 4})
				Timers:CreateTimer(4, function()
					caster:SwapAbilities("okita_zekken", "okita_sandanzuki", false, true)
				end)
			end
		end
	end
end

modifier_okita_weak_constitution = class({})
function modifier_okita_weak_constitution:IsHidden() return true end
function modifier_okita_weak_constitution:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,}
end
function modifier_okita_weak_constitution:GetModifierIncomingDamage_Percentage()
	if self:GetParent().IsSummerMadnessAcquired then
		return 0
	end
	return self:GetAbility():GetSpecialValueFor("hp_loss_percent")
end
function modifier_okita_weak_constitution:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

okita_weak_constitution_summer = class({})