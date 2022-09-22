modifier_kuro_crane_tracker = class({})

if IsServer() then
	function modifier_kuro_crane_tracker:OnCreated(args)	
		self:SetStackCount(math.min(args.Charges or 1, 3))

		EmitGlobalSound("chloe_crane_" .. self:GetStackCount())

		if self:GetStackCount() == 3 then
			self:SwapCraneWings()
		end
	end

	function modifier_kuro_crane_tracker:OnRefresh(args)	
		args.Charges = self:GetStackCount() + 1
		self:OnCreated(args)
	end

	function modifier_kuro_crane_tracker:OnDestroy()
		local caster = self:GetParent()

		if caster:GetAbilityByIndex(0):GetName() ~= "kuro_kanshou_byakuya" then
			caster:SwapAbilities("kuro_kanshou_byakuya", caster:GetAbilityByIndex(0):GetName(), true, false)
		end
	end

	function modifier_kuro_crane_tracker:SwapCraneWings()
		local caster = self:GetCaster()
		local kanshou = caster:FindAbilityByName("kuro_kanshou_byakuya")

		--[[if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 
			and not caster:FindModifierByName("modifier_triple_linked_cooldown") then 
			caster:SwapAbilities("kuro_kanshou_byakuya", "kuro_crane_wings_combo", false, true)
			caster:FindAbilityByName("kuro_crane_wings_combo"):StartCooldown(kanshou:GetCooldownTimeRemaining())
		else]]
			caster:SwapAbilities("kuro_kanshou_byakuya", "kuro_crane_wings", false, true)
			caster:FindAbilityByName("kuro_crane_wings"):StartCooldown(kanshou:GetCooldownTimeRemaining())
		--end
	end
end

function modifier_kuro_crane_tracker:IsHidden()
	return false
end

function modifier_kuro_crane_tracker:IsDebuff()
	return false
end

function modifier_kuro_crane_tracker:RemoveOnDeath()
	return true
end

function modifier_kuro_crane_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_kuro_crane_tracker:GetTexture()
	return "custom/archer_5th_kanshou_bakuya"
end