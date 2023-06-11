lancelot_double_edge = class({})
modifier_arondite_overload_window = class({})

LinkLuaModifier("modifier_arondite_overload_window", "abilities/lancelot/lancelot_double_edge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_double_edge", "abilities/lancelot/modifiers/modifier_double_edge", LUA_MODIFIER_MOTION_NONE)

function lancelot_double_edge:OnSpellStart()
	local caster = self:GetCaster()
	EmitZlodemonTrueSound("moskes_lanc_w",caster)
	caster:EmitSound("Hero_Sven.WarCry")

	caster:AddNewModifier(caster, self, "modifier_double_edge", { Duration = self:GetSpecialValueFor("duration"),
																  AttackSpeed = self:GetSpecialValueFor("base_att_spd"),
																  Movespeed = self:GetSpecialValueFor("base_mov_spd"),
																  DamageAmp = self:GetSpecialValueFor("base_dmg_amp"),
																  MaxAttackSpeed = self:GetSpecialValueFor("max_att_spd"),
																  MaxMovespeed = self:GetSpecialValueFor("max_mov_spd"),
																  MaxDamageAmp = self:GetSpecialValueFor("max_dmg_amp"),
																  BaseAttackSpeed = self:GetSpecialValueFor("base_att_spd"),
																  BaseMovementSpeed = self:GetSpecialValueFor("base_mov_spd"),
																  BaseDamageAmp = self:GetSpecialValueFor("base_dmg_amp"),
																  BaseDamageAmpSelf = self:GetSpecialValueFor("base_dmg_amp_self")})

	--[[if caster:GetStrength() > 59.1 and caster:GetAgility() > 59.1 and caster:GetIntellect() > 59.1 and caster:HasModifier("modifier_arondite") then
		if caster:FindAbilityByName("lancelot_combo_arondite_overload"):IsCooldownReady() 
			and caster:FindAbilityByName("lancelot_nuke"):IsCooldownReady() then
				caster:AddNewModifier(caster, self, "modifier_arondite_overload_window", { Duration = 3 })
		end
	end]]
end

if IsServer() then 
	function modifier_arondite_overload_window:OnCreated(args)
		self:GetParent():SwapAbilities("lancelot_combo_arondite_overload", "lancelot_knight_of_honor", true, false)
	end

	function modifier_arondite_overload_window:OnDestroy()
		self:GetParent():SwapAbilities("lancelot_combo_arondite_overload", "lancelot_knight_of_honor", false, true)
	end
end