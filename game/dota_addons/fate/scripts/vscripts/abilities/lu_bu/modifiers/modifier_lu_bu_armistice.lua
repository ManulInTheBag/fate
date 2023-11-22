modifier_lu_bu_armistice = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lu_bu_armistice:IsHidden()
	return false
end

function modifier_lu_bu_armistice:IsDebuff()
	return false
end

function modifier_lu_bu_armistice:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lu_bu_armistice:OnCreated( kv )
	-- references
	bonus = self:GetAbility():GetSpecialValueFor( "totem_damage_percentage" ) -- special value
	bonus_attack_range	= self:GetAbility():GetSpecialValueFor("bonus_attack_range")
	
	if IsServer() then
		self:PlayEffects()
	end
end

function modifier_lu_bu_armistice:OnRefresh( kv )
	-- references
	bonus = self:GetAbility():GetSpecialValueFor( "totem_damage_percentage" ) -- special value
end

function modifier_lu_bu_armistice:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_lu_bu_armistice:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
--		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
	}

	return funcs
end

function modifier_lu_bu_armistice:GetActivityTranslationModifiers()
	return "enchant_totem"
end

-- disabled
function modifier_lu_bu_armistice:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function modifier_lu_bu_armistice:GetModifierBaseDamageOutgoing_Percentage()
	return bonus
end

function modifier_lu_bu_armistice:GetModifierProcAttack_Feedback( params )
	if IsServer() then
		EmitSoundOn( "Hero_EarthShaker.Totem.Attack", params.target )

		self:Destroy()
	end
end

function modifier_lu_bu_armistice:GetModifierAttackRangeBonus()
	return bonus_attack_range
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_lu_bu_armistice:CheckState()
	local state = {
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_lu_bu_armistice:PlayEffects()
	-- Get Resources
	local particle_cast = self:GetParent().enchant_totem_buff_pfx or "particles/units/heroes/hero_earthshaker/earthshaker_totem_buff.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetParent() )

	local attach = "attach_attack1"
	if self:GetCaster():ScriptLookupAttachment( "attach_totem" )~=0 then attach = "attach_totem" end
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		attach,
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	local effect_cast = ParticleManager:CreateParticle( self:GetParent().enchant_totem_cast_pfx or "particles/units/heroes/hero_earthshaker/earthshaker_totem_cast.vpcf", PATTACH_ABSORIGIN, self:GetParent() )
	ParticleManager:ReleaseParticleIndex(effect_cast)
end