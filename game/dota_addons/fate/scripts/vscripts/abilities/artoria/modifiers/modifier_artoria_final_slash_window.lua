-----------------------------
--    Modifier: Final Slash Window    --
-----------------------------

modifier_artoria_final_slash_window = class({})

if IsServer() then
	function modifier_artoria_final_slash_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("artoria_excalibur", "artoria_final_slash", false, true)
	end

	function modifier_artoria_final_slash_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("artoria_excalibur", "artoria_final_slash", true, false)
	end
end

function modifier_artoria_final_slash_window:IsHidden()
	return true
end

function modifier_artoria_final_slash_window:RemoveOnDeath()
	return true 
end