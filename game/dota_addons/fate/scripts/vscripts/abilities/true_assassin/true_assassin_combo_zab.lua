-- true_assassin_combo_zab — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/true_assassin/ta_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

true_assassin_combo_zab = class({})

-- Логика перенесена из scripts/vscripts/ta_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDIZabStart, OnDIZabHit

OnDIZabStart = function(keys)
	local caster = keys.caster
	local target = keys.target

	local info = {
		Target = target,
		Source = caster,
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = caster,
		iMoveSpeed = 700
	}
	ProjectileManager:CreateTrackingProjectile(info)
	local smokeFx = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
	local smokeFx3 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(smokeFx3, 0, caster:GetAbsOrigin())

	EmitGlobalSound("TA.Darkness")
	caster:EmitSound("Hero_PhantomAssassin.Dagger.Cast")

	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( smokeFx, false )
			ParticleManager:ReleaseParticleIndex( smokeFx )
			ParticleManager:DestroyParticle( smokeFx3, false )
			ParticleManager:ReleaseParticleIndex( smokeFx3 )
			return nil
	end)
end

OnDIZabHit = function(keys)
	local caster = keys.caster
	local ply = keys.caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local comboAbility = hero:FindAbilityByName("true_assassin_combo")
	local damage = hero:FindAbilityByName("true_assassin_zabaniya"):GetLevel() * comboAbility:GetSpecialValueFor("bonus_damage")
				 + comboAbility:GetSpecialValueFor("base_damage")
	if hero.IsShadowStrikeAcquired then
		damage = damage + 100
	end
	keys.target:EmitSound("Hero_PhantomAssassin.Dagger.Target")
	DoDamage(hero, keys.target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end


function true_assassin_combo_zab:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: ta_ability / OnDIZabStart
	OnDIZabStart({ caster = caster, ability = self, target = target })
end

function true_assassin_combo_zab:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: ta_ability / OnDIZabHit
	OnDIZabHit({ caster = caster, ability = self, target = target })
	return true
end
