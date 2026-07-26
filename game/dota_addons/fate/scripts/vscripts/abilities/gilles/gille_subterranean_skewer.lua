-- gille_subterranean_skewer — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_abyssal_contract.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gille_subterranean_skewer = class({})

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSubSkewerStart, OnSubSkewerHit

OnSubSkewerStart = function(keys)
	local caster = keys.caster
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = keys.ability:GetCursorPosition()
	local diff = (targetPoint - casterLoc):Normalized()
	local frontward = caster:GetForwardVector()
	local skewer = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = 3000,
        vSpawnOrigin = casterLoc - frontward*100,
        fDistance = 1000 + 100,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 3000
	}
	--local projectile = ProjectileManager:CreateLinearProjectile(skewer)
	Timers:CreateTimer(1.0, function()
		local projectile = ProjectileManager:CreateLinearProjectile(skewer)
		caster:EmitSound("Hero_Lion.Impale")
		print("generated projectile")
	end)

	local tentacleCounter1 = 0
	Timers:CreateTimer(1.0, function()
		if tentacleCounter1 > 10 then return end
		
		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(tentacleFx, 0, casterLoc + diff * 110 * tentacleCounter1 )
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( tentacleFx, false )
			ParticleManager:ReleaseParticleIndex( tentacleFx )
		end)
		tentacleCounter1 = tentacleCounter1 + 1
		return 0.033
	end)
end

OnSubSkewerHit = function(keys)
	local target = keys.target
	local caster = keys.caster
	print("hit something")
	ApplyAirborne(caster, target, keys.StunDuration)
	DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

end


function gille_subterranean_skewer:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: gille_ability / OnSubSkewerStart
	OnSubSkewerStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT"
	})
	EmitSoundOn("ZC.Tentacle1", caster)
end

function gille_subterranean_skewer:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: gille_ability / OnSubSkewerHit
	OnSubSkewerHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		StunDuration = self:GetSpecialValueFor("stun_duration")
	})
	return false
end
