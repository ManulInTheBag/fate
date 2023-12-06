
--------------------------------------------------------------------------------
modifier_lu_bu_rebellious_spirit = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lu_bu_rebellious_spirit:IsHidden()
	return false
end

function modifier_lu_bu_rebellious_spirit:IsDebuff()
	return false
end

function modifier_lu_bu_rebellious_spirit:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lu_bu_rebellious_spirit:OnCreated( kv )
	local caster = self:GetParent()
	-- references
	self.max_mr = self:GetAbility():GetSpecialValueFor( "maximum_resistance" )
	self.max_mana = self:GetAbility():GetSpecialValueFor( "maximum_mana_regen" )/100
	self.max_threshold = self:GetAbility():GetSpecialValueFor( "hp_threshold_max" )
	self.range = 100-self.max_threshold
	self.max_size = 35

	-- effects
	self:PlayEffects()
end

function modifier_lu_bu_rebellious_spirit:OnRefresh( kv )
	local caster = self:GetParent()
	-- references
	self.max_mr = self:GetAbility():GetSpecialValueFor( "maximum_resistance" )
	self.max_mana = self:GetAbility():GetSpecialValueFor( "maximum_mana_regen" )/100
	self.max_threshold = self:GetAbility():GetSpecialValueFor( "hp_threshold_max" )	
	self.range = 100-self.max_threshold
end

function modifier_lu_bu_rebellious_spirit:OnRemoved()
end

function modifier_lu_bu_rebellious_spirit:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_lu_bu_rebellious_spirit:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		--MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}

	return funcs
end

function modifier_lu_bu_rebellious_spirit:GetModifierMagicalResistanceBonus()
	-- interpolate missing health
	local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)
	return (1-pct)*self.max_mr
end

function modifier_lu_bu_rebellious_spirit:GetModifierConstantManaRegen()
	-- interpolate missing health
	local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)
	return (1-pct)*self.max_mana*self:GetParent():GetMaxMana()
end

--[[function modifier_lu_bu_rebellious_spirit:GetModifierModelScale()
	if IsServer() then
		local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)

		-- set dynamic effects
		ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( (1-pct)*100,0,0 ) )

		return (1-pct)*self.max_size
	end
end]]
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_lu_bu_rebellious_spirit:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_huskar/huskar_berserkers_blood_glow.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end