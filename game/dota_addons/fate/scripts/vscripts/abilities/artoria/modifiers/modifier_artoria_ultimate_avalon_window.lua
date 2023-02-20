-----------------------------
--    Modifier: Ultimate Avalon Window    --
-----------------------------

modifier_artoria_ultimate_avalon_window = class({})

if IsServer() then
	function modifier_artoria_ultimate_avalon_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("artoria_avalon", "artoria_ultimate_avalon", false, true)
	end

	function modifier_artoria_ultimate_avalon_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("artoria_avalon", "artoria_ultimate_avalon", true, false)
	end
end

function modifier_artoria_ultimate_avalon_window:IsHidden()
	return true
end

function modifier_artoria_ultimate_avalon_window:RemoveOnDeath()
	return true 
end