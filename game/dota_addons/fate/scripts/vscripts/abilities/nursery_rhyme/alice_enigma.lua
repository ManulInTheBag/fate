LinkLuaModifier("modifier_alice_enigma", "abilities/nursery_rhyme/alice_enigma", LUA_MODIFIER_MOTION_NONE)

alice_enigma = class({})

function alice_enigma:OnSpellStart()
	local caster = self:GetCaster()

	local enigmaProjectile = 
	{
		caster = caster,
		source = caster,
		ability = self,
        EffectName = "particles/alice/alice_enigma_projectile.vpcf",
        sourceLoc = caster:GetAbsOrigin(),
        direction = caster:GetForwardVector(),
        speed = 1500,
        distance = 1175,
        startRadius = 200,
    	endRadius = 200,
    	iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		DeleteOnHit = false,

		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = 300
	}	

	local projectile = FATE_ProjectileManager:CreateLinearProjectile(enigmaProjectile)
	caster:EmitSound("Hero_Tusk.IceShards.Projectile")
	--caster:EmitSound("Hero_Tusk.IceShards.Cast")
	Timers:CreateTimer(1.0, function()
		caster:StopSound("Hero_Tusk.IceShards.Projectile")
	end)
end

function alice_enigma:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if not hTarget then return end

	local caster = self:GetCaster()
	local target = hTarget
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")
	local stun_duration = self:GetSpecialValueFor("stun_duration")

	target:AddNewModifier(caster, self, "modifier_stunned", { duration = stun_duration })
	target:AddNewModifier(caster, self, "modifier_alice_enigma",  { duration = duration })

	SpawnAttachedVisionDummy(caster, target, 300, 3, false)
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	target:EmitSound("Hero_Tusk.IceShards")
end

modifier_alice_enigma = class({})

function modifier_alice_enigma:IsDebuff() return true end

function modifier_alice_enigma:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_alice_enigma:GetModifierMoveSpeedBonus_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_alice_enigma:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	
	self:StartIntervalThink(0.25)
end

function modifier_alice_enigma:OnIntervalThink()
	if not IsServer() then return end

	local damage = self.ability:GetSpecialValueFor("perc_damage_per_second")*0.25
	damage = damage*self.parent:GetHealth()/100

	DoDamage(self.caster, self.parent, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end