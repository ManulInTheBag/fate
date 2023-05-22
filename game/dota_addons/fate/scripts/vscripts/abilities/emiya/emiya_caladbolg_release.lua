emiya_caladbolg_release = emiya_caladbolg_release or class({})

 


function emiya_caladbolg_release:OnSpellStart()
	local caster=  self:GetCaster()
	caster:RemoveModifierByNameAndCaster("modifier_emiya_caladbolg", caster)
end
