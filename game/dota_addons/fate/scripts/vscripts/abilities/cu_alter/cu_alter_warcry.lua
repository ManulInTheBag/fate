-- D : War Cry
-- Active  : self-buff for a short time granting bonus armor, magic resistance, health regen and
--           move speed. When it ends, Cú Chulainn Alter gains a barrier.
-- Passive : his attack speed is fixed (cannot be raised), but each of his attacks briefly
--           stuns the target and shoves it a spear-length forward. Toggling autocast on the
--           ability keeps the stun but disables that shove (pin the target in place instead).
--
-- The barrier reuses the shared modifiers/modifier_barrier_new.lua.

cu_alter_warcry = cu_alter_warcry or class({})

LinkLuaModifier("modifier_cu_alter_warcry_buff",    "abilities/cu_alter/cu_alter_warcry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_warcry_passive", "abilities/cu_alter/cu_alter_warcry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barrier_new",             "modifiers/modifier_barrier_new",     LUA_MODIFIER_MOTION_NONE)

-- passive is intrinsic (auto-applied once the ability has a level)
function cu_alter_warcry:GetIntrinsicModifierName()
	return "modifier_cu_alter_warcry_passive"
end

function cu_alter_warcry:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("cu_alter_vo_warcry")	-- "It's time to kill."
	caster:EmitSound("cu_alter_sfx_buff")	-- power-up SFX
	StartAnimation(caster, { duration = 0.4, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.0 })

	local castFx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle(castFx, false)
		ParticleManager:ReleaseParticleIndex(castFx)
	end)

	caster:AddNewModifier(caster, self, "modifier_cu_alter_warcry_buff", { duration = self:GetSpecialValueFor("buff_duration") })
end

-- called by modifier_barrier_new:OnDestroy when the barrier is consumed/expires
function cu_alter_warcry:OptionalDestroy(parent)
	-- nothing extra to clean up for now
end

---------------------------------------------------------------------------------------------------
-- Active buff : +armor, +magic resist, +HP regen, +move speed, barrier on expire.
modifier_cu_alter_warcry_buff = modifier_cu_alter_warcry_buff or class({})

function modifier_cu_alter_warcry_buff:IsHidden()      return false end
function modifier_cu_alter_warcry_buff:IsDebuff()      return false end
function modifier_cu_alter_warcry_buff:IsPurgable()    return false end
function modifier_cu_alter_warcry_buff:RemoveOnDeath() return true end

function modifier_cu_alter_warcry_buff:OnCreated()
	self.ability = self:GetAbility()
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusMres  = self.ability:GetSpecialValueFor("bonus_magic_resist")
	self.bonusRegen = self.ability:GetSpecialValueFor("bonus_health_regen")
	self.moveSpeed  = self.ability:GetSpecialValueFor("move_speed_bonus")
	self.dmgTaken   = 0
end

function modifier_cu_alter_warcry_buff:OnRefresh()
	self:OnCreated()
end

function modifier_cu_alter_warcry_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

-- attribute Ríastrad: remember how much damage was taken during the buff
function modifier_cu_alter_warcry_buff:OnTakeDamage(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	if not self:GetParent().CuAlterAttr1Acquired then return end
	self.dmgTaken = (self.dmgTaken or 0) + keys.damage
end

function modifier_cu_alter_warcry_buff:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_cu_alter_warcry_buff:GetModifierMagicalResistanceBonus()
	return self.bonusMres
end

function modifier_cu_alter_warcry_buff:GetModifierConstantHealthRegen()
	return self.bonusRegen
end

function modifier_cu_alter_warcry_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.moveSpeed
end

function modifier_cu_alter_warcry_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_cu_alter_warcry_buff:StatusEffectPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_cu_alter_warcry_buff:OnDestroy()
	if IsServer() then
		local parent  = self:GetParent()
		local ability = self:GetAbility()
		if parent:IsAlive() then
			local shield = ability:GetSpecialValueFor("barrier_amount")
			-- attribute Ríastrad: add a capped share of the damage taken during the buff
			if parent.CuAlterAttr1Acquired then
				local bonus = (self.dmgTaken or 0) * ability:GetSpecialValueFor("barrier_dmg_pct") / 100
				shield = shield + math.min(bonus, ability:GetSpecialValueFor("barrier_dmg_cap"))
			end
			parent:AddNewModifier(parent, ability, "modifier_barrier_new", {
				duration              = ability:GetSpecialValueFor("barrier_duration"),
				shield_amount         = shield,
				decreaseDamageOnProck = 0,
				beforeBScroll         = false,
				ShouldEndChannel      = false,
				HasCounter            = false,
			})
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Passive : fixed attack rate + on-attack stun & shove.
modifier_cu_alter_warcry_passive = modifier_cu_alter_warcry_passive or class({})

function modifier_cu_alter_warcry_passive:IsHidden()      return true end
function modifier_cu_alter_warcry_passive:IsDebuff()      return false end
function modifier_cu_alter_warcry_passive:IsPurgable()    return false end
function modifier_cu_alter_warcry_passive:RemoveOnDeath() return false end

function modifier_cu_alter_warcry_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

-- lock the base attack time regardless of agility / attack speed sources
function modifier_cu_alter_warcry_passive:GetModifierFixedAttackRate()
	return self:GetAbility():GetSpecialValueFor("fixed_attack_rate")
end

function modifier_cu_alter_warcry_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if keys.attacker ~= caster then return end

	local target = keys.target
	if not IsNotNull(target) or target == caster then return end
	if target:GetTeamNumber() == caster:GetTeamNumber() then return end
	if target:IsBuilding() or target:IsOther() then return end

	local ability = self:GetAbility()

	target:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("attack_stun_duration") })

	-- Autocast toggles the shove OFF (the stun always stays): with autocast on he pins the target in
	-- place instead of knocking it to the tip of his spear.
	if ability:GetAutoCastState() then return end

	-- Shove the target out to exactly the tip of the spear (attack range): push distance =
	-- attack range - current distance. If the target already stands at/beyond max range it is
	-- NOT pushed, so a stationary enemy can be pinned and finished off.
	if not IsKnockbackImmune(target) then
		local dist  = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
		local range = caster:Script_GetAttackRange() + ability:GetSpecialValueFor("attack_push_beyond")
		local push  = range - dist
		if push > 0 then
			local dir = (target:GetAbsOrigin() - caster:GetAbsOrigin())
			dir.z = 0
			dir = dir:Normalized()
			local knockback = {
				should_stun        = false,
				knockback_duration = ability:GetSpecialValueFor("attack_push_duration"),
				duration           = ability:GetSpecialValueFor("attack_push_duration"),
				knockback_distance = push,
				knockback_height   = 0,
				-- push away from the caster along the caster->target line
				center_x           = caster:GetAbsOrigin().x,
				center_y           = caster:GetAbsOrigin().y,
				center_z           = caster:GetAbsOrigin().z,
			}
			target:RemoveModifierByName("modifier_knockback")
			target:AddNewModifier(caster, ability, "modifier_knockback", knockback)
		end
	end
end
