-----------------------------
--    Modifier: Pitfall Debuff    --
-----------------------------

modifier_robin_tools_pitfall_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_robin_tools_pitfall_debuff:IsHidden()
	return false
end

function modifier_robin_tools_pitfall_debuff:IsDebuff()
	return true
end

function modifier_robin_tools_pitfall_debuff:IsStunDebuff()
	return false
end

function modifier_robin_tools_pitfall_debuff:IsPurgable()
	return true
end

function modifier_robin_tools_pitfall_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_robin_tools_pitfall_debuff:OnCreated( kv )

	if not IsServer() then return end
	-- references
	local duration = kv.duration
	local damage = kv.damage
	local interval = 0.1

	-- set dps
	local instances = duration/interval
	local dps = damage/instances

	-- precache damage
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = dps,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(), --Optional.
	}
	-- ApplyDamage(damageTable)

	-- Start interval
	self:StartIntervalThink( interval )

	-- play effects
	local sount_cast1 = "Hero_DarkWillow.Bramble.Target"
	local sount_cast2 = "Hero_DarkWillow.Bramble.Target.Layer"
	EmitSoundOn( sount_cast1, self:GetParent() )
	EmitSoundOn( sount_cast2, self:GetParent() )
end

function modifier_robin_tools_pitfall_debuff:OnRefresh( kv )
	
end

function modifier_robin_tools_pitfall_debuff:OnRemoved()
end

function modifier_robin_tools_pitfall_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_robin_tools_pitfall_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_robin_tools_pitfall_debuff:OnIntervalThink()
	-- apply damage
	ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_robin_tools_pitfall_debuff:GetEffectName()
	return "particles/custom/robin/robin_pitfall_debuff.vpcf"
end

function modifier_robin_tools_pitfall_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end