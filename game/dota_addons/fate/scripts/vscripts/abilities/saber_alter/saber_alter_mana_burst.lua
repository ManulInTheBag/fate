-- saber_alter_mana_burst — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber_alter/saber_alter_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_alter_mana_burst = class({})

-- Логика перенесена из scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMBStart, OnManaBlastHit

OnMBStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local stunDuration = 0.2

	if caster.IsManaBlastAcquired then
		keys.Damage = keys.Damage + (caster:GetMana() * 0.1)
		caster:SpendMana(caster:GetMana() * 0.1, ability)
		stunDuration = 0.5
		keys.Radius = keys.Radius + 200 
	end

	caster:EmitSound("Saber_Alter.ManaBurst") 
	caster:EmitSound("saber_alter_attack_03")
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	
	local info = {
		Target = nil,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/items2_fx/skadi_projectile.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 500
	}
	
	if caster.IsManaBlastAcquired and #targets ~= 0 then
		-- Force remove all particles
		while caster:HasModifier( "modifier_derange_mana_catalyst_VFX" ) do
			caster:RemoveModifierByName( "modifier_derange_mana_catalyst_VFX" )
		end

		while caster:GetModifierStackCount("modifier_catalyst", self) ~= 0 do
			info.Target = targets[math.random(#targets)]
			ProjectileManager:CreateTrackingProjectile(info) 
			caster:SetModifierStackCount("modifier_catalyst", self, caster:GetModifierStackCount("modifier_catalyst", self) - 1)
		end
	end

	-- 1.24c particle fix
	-- Slight fix to make the particle size respect the actual AoE after obtaining SA
	local mbParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(mbParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(mbParticle, 1, Vector(keys.Radius, 0, 0))
	ParticleManager:SetParticleControl(mbParticle, 2, Vector(1.0, 0, 0))

	for k,v in pairs(targets) do
	    DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	    v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stunDuration})
	end

	-- modifier_mana_burst_VFX: DD-объявление закомментировано в KV ещё до порта,
	-- применять нечего (вызов был no-op, в ability_lua он падал)
end

OnManaBlastHit = function(keys)
	DoDamage(keys.caster, keys.target, 100 , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end


function saber_alter_mana_burst:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function saber_alter_mana_burst:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	return true
end

function saber_alter_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_mana_burst_VFX")
	-- DD RunScript: saber_alter_ability / OnMBStart
	OnMBStart({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("damage"),
		Radius = self:GetSpecialValueFor("radius")
	})
end

function saber_alter_mana_burst:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: saber_alter_ability / OnManaBlastHit
	OnManaBlastHit({ caster = caster, ability = self, target = target })
	return true
end
