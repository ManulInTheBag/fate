-----------------------------
--    Modifier: Faceless King Active    --
-----------------------------

modifier_robin_faceless_king_active = class({})

LinkLuaModifier("modifier_robin_faceless_king_cooldown", "abilities/robin/modifiers/modifier_robin_faceless_king_cooldown", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_robin_faceless_king_active:OnDestroy()
		local caster = self:GetCaster()
		local ability = caster:FindAbilityByName("robin_faceless_king")

		caster:AddNewModifier(caster, ability, "modifier_robin_faceless_king_cooldown", { Duration = 100})
		ability:StartCooldown(100)
	end
end

function modifier_robin_faceless_king_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end