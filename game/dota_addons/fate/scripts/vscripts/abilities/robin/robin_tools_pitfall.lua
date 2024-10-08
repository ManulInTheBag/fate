-----------------------------
--    Pitfall    --
-----------------------------

robin_tools_pitfall = class({})

LinkLuaModifier( "modifier_generic_custom_indicator", "abilities/robin/modifiers/modifier_generic_custom_indicator", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_tools_pitfall", "abilities/robin/modifiers/modifier_robin_tools_pitfall", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_tools_pitfall_debuff", "abilities/robin/modifiers/modifier_robin_tools_pitfall_debuff", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_tools_pitfall_thinker", "abilities/robin/modifiers/modifier_robin_tools_pitfall_thinker", LUA_MODIFIER_MOTION_NONE )

function robin_tools_pitfall:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 300
	else
		return 400
	end
end

function robin_tools_pitfall:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 20
	else
		return 25
	end
end

--------------------------------------------------------------------------------
-- init bramble locations
local locations = {}
local inner = Vector( 200, 0, 0 )
local outer = Vector( 500, 0, 0 )
outer = RotatePosition( Vector(0,0,0), QAngle( 0, 45, 0 ), outer )

-- real men use 0-based
for i=0,3 do
	locations[i] = RotatePosition( Vector(0,0,0), QAngle( 0, 90*i, 0 ), inner )
	locations[i+4] = RotatePosition( Vector(0,0,0), QAngle( 0, 90*i, 0 ), outer )
end
robin_tools_pitfall.locations = locations

--------------------------------------------------------------------------------
-- Passive Modifier
function robin_tools_pitfall:GetIntrinsicModifierName()
	return "modifier_generic_custom_indicator"
end

--------------------------------------------------------------------------------
-- Ability Cast Filter (For custom indicator)
function robin_tools_pitfall:CastFilterResultLocation( vLoc )
	-- Custom indicator block start
	if IsClient() then
		-- check custom indicator
		if self.custom_indicator then
			-- register cursor position
			self.custom_indicator:Register( vLoc )
		end
	end
	-- Custom indicator block end

	return UF_SUCCESS
end

--------------------------------------------------------------------------------
-- Ability Custom Indicator
function robin_tools_pitfall:CreateCustomIndicator()
	-- references
	local particle_cast = "particles/custom/robin/robin_pitfall_rangefinder.vpcf"

	-- get data
	local radius = self:GetSpecialValueFor( "placement_range" )

	-- create particle
	self.effect_indicator = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl( self.effect_indicator, 1, Vector( radius, radius, radius ) )
end

function robin_tools_pitfall:UpdateCustomIndicator( loc )
	-- update particle position
	ParticleManager:SetParticleControl( self.effect_indicator, 0, loc )
	for i=0,7 do
		ParticleManager:SetParticleControl( self.effect_indicator, 2 + i, loc + self.locations[i] )
	end
end

function robin_tools_pitfall:DestroyCustomIndicator()
	-- destroy particle
	ParticleManager:DestroyParticle( self.effect_indicator, false )
	ParticleManager:ReleaseParticleIndex( self.effect_indicator )
end

--------------------------------------------------------------------------------
-- Ability Start
function robin_tools_pitfall:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	caster:EmitSound("robin_pitfall")

	-- create thinker
	CreateModifierThinker(
		caster, -- player source
		self, -- ability source
		"modifier_robin_tools_pitfall_thinker", -- modifier name
		{}, -- kv
		point,
		self:GetCaster():GetTeamNumber(),
		false
	)
	
	if not caster:HasModifier("modifier_robin_tools_attribute") then
		local ability = caster:FindAbilityByName("robin_tools")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))	
		ability:StartCooldown( self:GetCooldown(self:GetLevel()))
	end
end