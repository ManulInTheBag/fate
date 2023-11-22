-----------------------------
--    Modifier: Assault Skillswap   --
-----------------------------

modifier_assault_skillswap_2 = class({})

if IsServer() then
	function modifier_assault_skillswap_2:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("lu_bu_halberd_throw", "lu_bu_relentless_assault_two", false, true)
	end

	function modifier_assault_skillswap_2:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("lu_bu_halberd_throw", "lu_bu_relentless_assault_two", true, false)
	end
end

function modifier_assault_skillswap_2:IsHidden()
	return true
end

function modifier_assault_skillswap_2:RemoveOnDeath()
	return false
end