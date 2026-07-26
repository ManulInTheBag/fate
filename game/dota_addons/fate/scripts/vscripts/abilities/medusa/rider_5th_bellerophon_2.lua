-- rider_5th_bellerophon_2 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medusa/medusa_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

rider_5th_bellerophon_2 = class({})

LinkLuaModifier("modifier_bellerophon_2_cooldown", "abilities/medusa/rider_5th_bellerophon_2", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/rider_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBelle2Cast, OnBelle2Interrupt, OnBelle2Start, OnBelle2Hit

OnBelle2Cast = function( keys )
	local caster = keys.caster
	local chargeFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_invoker/invoker_emp_charge.vpcf", PATTACH_ABSORIGIN, caster )
	local eyeFxIndex = ParticleManager:CreateParticle( "particles/items_fx/dust_of_appearance_true_sight.vpcf", PATTACH_ABSORIGIN, caster )
	Timers:CreateTimer( 0.7, function()
		EmitGlobalSound("Leroy")
	end
	)
	Timers:CreateTimer( 2.5, function()
			ParticleManager:DestroyParticle( chargeFxIndex, false )
			ParticleManager:DestroyParticle( eyeFxIndex, false )
			ParticleManager:ReleaseParticleIndex( chargeFxIndex )
			ParticleManager:ReleaseParticleIndex( eyeFxIndex )
		end
	)
end

OnBelle2Interrupt = function( keys )
	local caster = keys.caster

    StopGlobalSound("Leroy")
end

OnBelle2Start = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	local bloodfortAbility = caster:FindAbilityByName("rider_5th_bloodfort_andromeda")
	local bloodfortCooldown = bloodfortAbility:GetCooldown(bloodfortAbility:GetLevel())
	bloodfortAbility:StartCooldown(bloodfortCooldown)

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_bellerophon_2_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	
	local belle2 = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = 99999,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = keys.Range,
        fStartRadius = keys.Width,
        fEndRadius = keys.Width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 1.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 99999
	}
	ParticleManager:CreateParticle("particles/custom/screen_lightblue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	EmitGlobalSound("medusa_bellerophon_alt") 
	Timers:CreateTimer(2.0, function()
		EmitGlobalSound("Jenkins")
	end)
	local projectile = ProjectileManager:CreateLinearProjectile(belle2)
	
	-- Create Particle for projectile
	local belle2FxIndex = ParticleManager:CreateParticle( "particles/custom/rider/rider_bellerophon_2_beam_charge.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( belle2FxIndex, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( belle2FxIndex, 1, Vector( keys.Width, keys.Width, keys.Width ) )
	ParticleManager:SetParticleControl( belle2FxIndex, 2, caster:GetForwardVector() * 5000 )
	ParticleManager:SetParticleControl( belle2FxIndex, 6, Vector( 2, 0, 0 ) )
			
	Timers:CreateTimer( 0.5, function()
		ParticleManager:DestroyParticle( belle2FxIndex, false )
		ParticleManager:ReleaseParticleIndex( belle2FxIndex )
	end)

	locationDelta = caster:GetForwardVector() * keys.Range
	newLocation = caster:GetAbsOrigin() + locationDelta
	for i=1, 20 do
		if GridNav:IsBlocked(newLocation) or not GridNav:IsTraversable(newLocation) then
			--locationDelta =  caster:GetForwardVector() * (keys.Range - 100)
			newLocation = caster:GetAbsOrigin() + caster:GetForwardVector() * (20 - i) * 100
			if not IsInSameRealm(caster:GetAbsOrigin(), newLocation) then
				newLocation.y = caster:GetAbsOrigin().y
			end
		else
			break
		end
	end 
	caster:SetAbsOrigin(newLocation) 
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

OnBelle2Hit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	if caster.IsRidingAcquired then 
		keys.Damage = keys.Damage + 450 + (caster:GetAgility() * 10)
	end 
	DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	target:AddNewModifier(caster, ability, "modifier_stunned", { Duration = 2 })
end


function rider_5th_bellerophon_2:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function rider_5th_bellerophon_2:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBelle2Cast
	OnBelle2Cast({ caster = caster, ability = self, target = caster })
	return true
end

function rider_5th_bellerophon_2:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBelle2Interrupt
	OnBelle2Interrupt({ caster = caster, ability = self, target = caster })
end

function rider_5th_bellerophon_2:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBelle2Start
	OnBelle2Start({
		caster = caster,
		ability = self,
		target = caster,
		Range = self:GetSpecialValueFor("range"),
		Width = self:GetSpecialValueFor("width")
	})
end

function rider_5th_bellerophon_2:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBelle2Hit
	OnBelle2Hit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage")
	})
	return false
end

modifier_bellerophon_2_cooldown = class({})

function modifier_bellerophon_2_cooldown:IsDebuff() return true end
function modifier_bellerophon_2_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
