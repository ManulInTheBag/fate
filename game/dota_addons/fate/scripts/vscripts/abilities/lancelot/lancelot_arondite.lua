lancelot_arondite = class({})

LinkLuaModifier("modifier_eternal_flame_shred", "abilities/lancelot/modifiers/modifier_eternal_flame_shred", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arondite", "abilities/lancelot/modifiers/modifier_arondite", LUA_MODIFIER_MOTION_NONE)

function lancelot_arondite:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function lancelot_arondite:GetCastPoint()
	return self:GetSpecialValueFor("cast_point")
end

function lancelot_arondite:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("lancelot_arthur_" .. math.random(1,3))

	return true
end

function lancelot_arondite:OnSpellStart()
	local caster = self:GetCaster()
    local ability = self
   
    local groundcrack = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    local warp = ParticleManager:CreateParticle("particles/custom/lancelot/lancelot_arondite_aoe_warp.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(warp,0, caster:GetAbsOrigin())
	EmitZlodemonTrueSound("moskes_lanc_r" .. math.random(1,3),caster)
    caster:EmitSound("Hero_Sven.GodsStrength")

    -- Destroy particle after delay
    Timers:CreateTimer( 2.0, function()
        ParticleManager:DestroyParticle( groundcrack, false )
        ParticleManager:ReleaseParticleIndex( groundcrack )
        FxDestroyer(warp,false)
    end)

    local bonus_damage = self:GetSpecialValueFor("bonus_damage")
    local bonus_stats = self:GetSpecialValueFor("bonus_allstat")

    if caster:HasModifier("modifier_kotl_attribute") then
    	bonus_damage = bonus_damage*1.5
    	bonus_stats = bonus_stats * 1.5
    end

    caster:AddNewModifier(caster, self, "modifier_arondite", {	Duration = self:GetSpecialValueFor("duration"),
    															StrengthBonus = bonus_stats,
    															AgilityBonus = bonus_stats,
    															IntelligenceBonus = bonus_stats,
    															BonusDamage = bonus_damage,
    															KotlAttribute = caster:HasModifier("modifier_kotl_attribute") })

    caster:Heal(self:GetSpecialValueFor("activate_heal"), caster)

    -- Timers:CreateTimer(0, function()
    -- 	if caster:HasModifier("modifier_arondite") then
    -- 	print(caster:IsMagicImmune())
    -- 	return 0.1
    -- end
    -- end)
end

function lancelot_arondite:CreateFireProjectile()
	local caster = self:GetCaster()
	local shootProjectile = true

	if not caster:HasModifier("modifier_eternal_flame_attribute") then
		if caster:GetMana() < 40 then
			shootProjectile = false
		else
			caster:SetMana(caster:GetMana() - 40)
		end
	end
	
	if shootProjectile then
	    local flame = 
		{
			Ability = self,
			EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
			iMoveSpeed = 1000,
			vSpawnOrigin = caster:GetAbsOrigin(),
			fDistance = 300,
			fStartRadius = 100,
			fEndRadius = 200,
			Source = caster,
			bHasFrontalCone = true,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_ALL,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = false,
			vVelocity = caster:GetForwardVector() * 1000
	    }
		ProjectileManager:CreateLinearProjectile(flame)
		caster:EmitSound("Hero_Phoenix.FireSpirits.Launch")
	end
end

function lancelot_arondite:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("fire_damage")

	if not hTarget:IsMagicImmune() then
		DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

		--if hCaster:HasModifier("modifier_eternal_flame_attribute") then
		--	hTarget:AddNewModifier(hCaster, self, "modifier_eternal_flame_shred", { Duration = self:GetSpecialValueFor("ef_dur") })
		--end
	end
end