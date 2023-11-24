lu_bu_relentless_assault_three = class({})
LinkLuaModifier( "modifier_lu_bu_relentless_assault_three", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_three", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function lu_bu_relentless_assault_three:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local bDuration = self:GetSpecialValueFor("duration")
	
	StartAnimation(caster, {duration = 5.0, activity=ACT_DOTA_CAST_ABILITY_6, rate = 1.0})
	
	caster:RemoveModifierByName("modifier_assault_skillswap_3")
	caster:RemoveModifierByName("modifier_relentless_assault_blocker")
	local relentless_assault = caster:FindModifierByName("modifier_lu_bu_relentless_assault")
	relentless_assault:SetStackCount(1)
	
	caster:EmitSound("lu_bu_relentless_assault_three")

	-- Add modifier
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_lu_bu_relentless_assault_three", -- modifier name
		{ duration = bDuration } -- kv
	)
end