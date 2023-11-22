-----------------------------
--    Modifier: Assault Skillswap   --
-----------------------------

modifier_assault_skillswap_4 = class({})

if IsServer() then
	function modifier_assault_skillswap_4:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("lu_bu_god_force", "lu_bu_relentless_assault_four", false, true)
	end

	function modifier_assault_skillswap_4:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("lu_bu_god_force", "lu_bu_relentless_assault_four", true, false)
	end
end

function modifier_assault_skillswap_4:IsHidden()
	return true
end

function modifier_assault_skillswap_4:RemoveOnDeath()
	return false
end