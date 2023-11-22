-----------------------------
--    Modifier: Assault Skillswap   --
-----------------------------

modifier_assault_skillswap_1 = class({})

if IsServer() then
	function modifier_assault_skillswap_1:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("lu_bu_armistice", "lu_bu_relentless_assault_one", false, true)
	end

	function modifier_assault_skillswap_1:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("lu_bu_armistice", "lu_bu_relentless_assault_one", true, false)
	end
end

function modifier_assault_skillswap_1:IsHidden()
	return true
end

function modifier_assault_skillswap_1:RemoveOnDeath()
	return false
end