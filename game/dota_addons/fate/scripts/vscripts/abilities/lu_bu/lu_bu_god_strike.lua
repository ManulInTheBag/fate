
--------------------------------------------------------------------------------
lu_bu_god_strike = class({})
LinkLuaModifier( "modifier_lu_bu_god_strike", "abilities/lu_bu/modifiers/modifier_lu_bu_god_strike", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_lu_bu_god_strike_arc", "abilities/lu_bu/modifiers/modifier_lu_bu_god_strike_arc", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_assault_skillswap_3", "abilities/lu_bu/modifiers/modifier_assault_skillswap_3", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function lu_bu_god_strike:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Cast Filter
function lu_bu_god_strike:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function lu_bu_god_strike:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return "#dota_hud_error_nothing_to_toss"
end

--------------------------------------------------------------------------------
-- Helper
function lu_bu_god_strike:FindEnemies()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor( "grab_radius" )

	-- find unit around tiny
	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		caster:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		FIND_CLOSEST,	-- int, order filter
		false	-- bool, can grow cache
	)

	local target
	for _,unit in pairs(units) do
		local filter1 = (unit~=caster) and (not unit:IsAncient()) and (not unit:FindModifierByName( 'modifier_lu_bu_god_strike' ))
		local filter2 = (unit:GetTeamNumber()==caster:GetTeamNumber()) or (not unit:IsInvisible())
		if filter1 then
			if filter2 then
				target = unit
				break
			end
		end
	end

	return target
end

--------------------------------------------------------------------------------
-- Ability Phase Start
function lu_bu_god_strike:OnAbilityPhaseInterrupted()

end
function lu_bu_god_strike:OnAbilityPhaseStart()
	return self:FindEnemies()
	-- return true -- if success
end

--------------------------------------------------------------------------------
-- Ability Start
function lu_bu_god_strike:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- local point = self:GetCursorPosition()

	-- get victim
	local victim = self:FindEnemies()
	
	if victim == nil then
		return 
	end

	-- add modifier
	victim:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_lu_bu_god_strike", -- modifier name
		{
			target = target:entindex(),
		} -- kv
	)
	
	caster:EmitSound("lu_bu_generic_2")
	
	ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)
	local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_armistice_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blastFx, false )
		ParticleManager:ReleaseParticleIndex( blastFx )
	end)
	
	local relentless_assault = caster:FindModifierByNameAndCaster( "modifier_lu_bu_relentless_assault", caster )
	local assault_stack = caster:GetModifierStackCount("modifier_lu_bu_relentless_assault", caster)
	
	if caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack < 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		relentless_assault:SetStackCount(assault_stack + 1)
	elseif caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack >= 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		caster:AddNewModifier(caster, self, "modifier_assault_skillswap_3", {})
		caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker", {})
	end
end

function lu_bu_god_strike:OnUpgrade()
    local relentless_assault = self:GetCaster():FindAbilityByName("lu_bu_relentless_assault_three")
    relentless_assault:SetLevel(self:GetLevel())
end