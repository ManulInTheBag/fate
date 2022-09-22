lishuwen_presence_concealment = class({})

LinkLuaModifier("modifier_pc_invis", "abilities/lishuwen/modifiers/modifier_pc_invis", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pc_nss_cooldown_recovery", "abilities/lishuwen/modifiers/modifier_pc_nss_cooldown_recovery", LUA_MODIFIER_MOTION_NONE)

function lishuwen_presence_concealment:GetTexture()
	return "custom/lishuwen_presence_concealment"
end

function lishuwen_presence_concealment:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	ProjectileManager:ProjectileDodge(caster)

	local stopOrder = {
		UnitIndex = caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
	}
	ExecuteOrderFromTable(stopOrder) 
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk")
	
	caster:AddNewModifier(caster, ability, "modifier_pc_invis", { BreakDelay = self:GetSpecialValueFor("break_delay"),
																HealthRegenPct = self:GetSpecialValueFor("health_regen"),
																ManaRegenPct = self:GetSpecialValueFor("mana_regen"),
																BonusDamage = self:GetSpecialValueFor("bonus_damage"), 
																AttackBuffDuration = self:GetSpecialValueFor("atk_buff_duration"),
																AttackCount = self:GetSpecialValueFor("number_attacks")})

	if caster.bIsMartialArtsImproved then
		caster:AddNewModifier(caster, ability, "modifier_pc_nss_cooldown_recovery", {})
	end
end