-----------------------------
--    Modifier: Assault Skillswap   --
-----------------------------

modifier_assault_skillswap_3 = class({})

if IsServer() then
	function modifier_assault_skillswap_3:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("lu_bu_rage", "lu_bu_relentless_assault_three", false, true)
	end

	function modifier_assault_skillswap_3:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("lu_bu_rage", "lu_bu_relentless_assault_three", true, false)
	end
end

function modifier_assault_skillswap_3:IsHidden()
	return true
end

function modifier_assault_skillswap_3:RemoveOnDeath()
	return false
end