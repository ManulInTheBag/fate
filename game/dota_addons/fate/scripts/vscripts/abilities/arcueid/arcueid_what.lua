LinkLuaModifier("modifier_arcueid_what", "abilities/arcueid/arcueid_what", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_what_buff", "abilities/arcueid/arcueid_what", LUA_MODIFIER_MOTION_NONE)

arcueid_what = class({})

function arcueid_what:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local enemy = self:GetCursorTarget()

	local sound_cast = "Hero_LifeStealer.OpenWounds.Cast"
	local sound_target = "Hero_LifeStealer.OpenWounds"
	EmitSoundOn( sound_cast, caster )
	EmitSoundOn( sound_target, enemy )
	
	enemy:AddNewModifier(caster, self, "modifier_arcueid_what", {duration = self:GetSpecialValueFor("duration")})
	--StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=1.0})
end

modifier_arcueid_what = class({})

function modifier_arcueid_what:IsHidden() return false end
function modifier_arcueid_what:IsDebuff() return false end
function modifier_arcueid_what:RemoveOnDeath() return true end

function modifier_arcueid_what:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.damage = self.ability:GetSpecialValueFor("damage")

		self.hp = self.caster:GetHealth()

		self:StartIntervalThink(FrameTime())
		self.tick = 0
	end
end

function modifier_arcueid_what:OnRefresh()
	if IsServer() then
		self.tick = 0
	end
end

function modifier_arcueid_what:OnIntervalThink()
	if IsServer() then
		self.hp = self.caster:GetHealth()
		local caster = self.caster
		self.tick = self.tick + 1
		if (self.tick == 1) then
			DoDamage(caster, self.parent, self.damage , DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			caster:FindAbilityByName("arcueid_impulses"):Pepeg(self.parent)
		end
	end
end

function modifier_arcueid_what:OnAttackStart(args)
	if IsServer() then
		if args.target ~= self:GetParent() then return end

		if not self:GetCaster().MonstrousStrengthAcquired then return end

		args.attacker:AddNewModifier(self.caster, self.ability, "modifier_arcueid_what_buff", {duration = 1.5})
	end
end

function modifier_arcueid_what:OnAttackLanded(args)
	if IsServer() then
		if args.target ~= self:GetParent() then return end

		if not self:GetCaster().MonstrousStrengthAcquired then return end

		self:IncrementStackCount()
		DoDamage(args.attacker, self.parent, self:GetStackCount()*self:GetAbility():GetSpecialValueFor("attribute_damage"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
end

function modifier_arcueid_what:OnTakeDamage(args)
	if IsServer() then
		if args.unit ~= self:GetParent() then return end

		args.attacker:Heal(args.damage*self.ability:GetSpecialValueFor("lifesteal")/100, self.ability)
		self:PlayEffects(args.attacker)
	end
end

function modifier_arcueid_what:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_arcueid_what:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("slow_percent")
end

function modifier_arcueid_what:GetEffectName()
	return "particles/units/heroes/hero_life_stealer/life_stealer_open_wounds.vpcf"
end

function modifier_arcueid_what:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_arcueid_what:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/generic_gameplay/generic_lifesteal.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	-- ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
	-- ParticleManager:SetParticleControlEnt(
	-- 	effect_cast,
	-- 	iControlPoint,
	-- 	hTarget,
	-- 	PATTACH_NAME,
	-- 	"attach_name",
	-- 	vOrigin, -- unknown
	-- 	bool -- unknown, true
	-- )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end



modifier_arcueid_what_buff = class({})

function modifier_arcueid_what_buff:IsHidden() return true end
function modifier_arcueid_what_buff:IsDebuff() return false end
function modifier_arcueid_what_buff:RemoveOnDeath() return true end
function modifier_arcueid_what_buff:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_arcueid_what_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_arcueid_what_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attribute_attack_speed")
end