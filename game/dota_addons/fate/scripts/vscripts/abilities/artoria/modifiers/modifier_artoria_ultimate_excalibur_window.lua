-----------------------------
--    Modifier: Ultimate Excalibur Window    --
-----------------------------

modifier_artoria_ultimate_excalibur_window = class({})

if IsServer() then
	function modifier_artoria_ultimate_excalibur_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("artoria_excalibur", "artoria_ultimate_excalibur", false, true)
	end

	function modifier_artoria_ultimate_excalibur_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("artoria_excalibur", "artoria_ultimate_excalibur", true, false)
	end
end

function modifier_artoria_ultimate_excalibur_window:IsHidden()
	return true
end

function modifier_artoria_ultimate_excalibur_window:RemoveOnDeath()
	return true 
end