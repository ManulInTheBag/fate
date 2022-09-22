semiramis_binding_chains = class({})

LinkLuaModifier("modifier_binding_chains", "abilities/semiramis/modifiers/modifier_binding_chains", LUA_MODIFIER_MOTION_NONE)

function semiramis_binding_chains:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local bind_duration = self:GetSpecialValueFor("duration")

	local magic_res = target:GetMagicalArmorValue()

	bind_duration = bind_duration * (1 - magic_res)
	
	target:AddNewModifier(caster, self, "modifier_binding_chains", { Duration = bind_duration })
end