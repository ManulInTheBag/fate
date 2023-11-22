-----------------------------
--    Modifier:Sky Piercer Window    --
-----------------------------

modifier_lu_bu_sky_piercer_window = class({})

if IsServer() then
	function modifier_lu_bu_sky_piercer_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("lu_bu_god_force", "lu_bu_sky_piercer", false, true)
	end

	function modifier_lu_bu_sky_piercer_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("lu_bu_god_force", "lu_bu_sky_piercer", true, false)
	end
end

function modifier_lu_bu_sky_piercer_window:IsHidden()
	return true
end

function modifier_lu_bu_sky_piercer_window:RemoveOnDeath()
	return true 
end