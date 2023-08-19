arash_star_arrow_release = arash_star_arrow_release or class({})

 


function arash_star_arrow_release:OnSpellStart()
	local caster=  self:GetCaster()
	local abil = caster:FindAbilityByName("arash_star_arrow")
	local vector = -(caster:GetAbsOrigin() - self:GetCursorPosition()):Normalized()
	abil:ReleaseArrow(vector)
	caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
	--caster:RemoveModifierByNameAndCaster("modifier_arash_star_arrow", caster)
end
