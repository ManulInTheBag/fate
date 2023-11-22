modifier_lu_bu_restless_soul_active = class({})

LinkLuaModifier("modifier_lu_bu_restless_soul_cooldown", "abilities/lu_bu/modifiers/modifier_lu_bu_restless_soul_cooldown", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_lu_bu_restless_soul_active:OnDestroy()
		local caster = self:GetCaster()

		caster:AddNewModifier(caster, ability, "modifier_lu_bu_restless_soul_cooldown", { Duration = 100})
	end
end

function modifier_lu_bu_restless_soul_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
end

function modifier_lu_bu_restless_soul_active:GetModifierSpellAmplify_Percentage()
	return 30
end

function modifier_lu_bu_restless_soul_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end