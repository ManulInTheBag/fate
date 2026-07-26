IWActive = false

LinkLuaModifier("modifier_minds_eye_attribute", "abilities/sasaki/modifiers/modifier_minds_eye_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ganryu_attribute", "abilities/sasaki/modifiers/modifier_ganryu_attribute", LUA_MODIFIER_MOTION_NONE)

-- Create Gate keeper's particles
function GKParticleStart( keys )
	local caster = keys.caster
	if caster.fa_gate_keeper_particle ~= nil then
		return
	end
	
	caster.fa_gate_keeper_particle = ParticleManager:CreateParticle( "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( caster.fa_gate_keeper_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
	ParticleManager:SetParticleControl( caster.fa_gate_keeper_particle, 1, Vector( 100, 100, 100 ) )
end

-- Destroy Gate keeper's particles
function GKParticleDestroy( keys )
	local caster = keys.caster
	if caster.fa_gate_keeper_particle ~= nil then
		ParticleManager:DestroyParticle( caster.fa_gate_keeper_particle, false )
		ParticleManager:ReleaseParticleIndex( caster.fa_gate_keeper_particle )
		caster.fa_gate_keeper_particle = nil
	end
end

function OnHeartStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()

	if caster.IsVitrificationAcquired then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_heart_of_harmony_invisible", {})
	--[[else
		-- set global cooldown
		-- Global cooldown removed as of 1.24c
		caster:FindAbilityByName("false_assassin_gate_keeper"):StartCooldown(keys.GCD) 
		caster:FindAbilityByName("false_assassin_windblade"):StartCooldown(keys.GCD) 
		caster:FindAbilityByName("false_assassin_tsubame_gaeshi"):StartCooldown(keys.GCD) ]]
	end
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_heart_of_harmony", {})
	caster:EmitSound("Hero_Abaddon.AphoticShield.Cast")
end

function OnHeartLevelUp(keys)
	local caster = keys.caster
	--caster.ArmorPen = keys.ArmorPen
end

function OnHeartAttackLanded(keys)
	PrintTable(keys)
	local caster = keys.caster
	-- Process armor pen
	local target = keys.target
	--local multiplier = GetPhysicalDamageReduction(target:GetPhysicalArmorValue(false)) * caster.ArmorPen / 100
	--DoDamage(caster, target, caster:GetAttackDamage() * multiplier , DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	

end

function OnHeartDamageTaken(keys)
	-- process counter
	local caster = keys.caster
	local target = keys.attacker
	local ability = keys.ability
	local cdr = 15-- keys.Cdr
	local damageTaken = keys.DamageTaken

	if damageTaken > keys.Threshold and caster:GetHealth() ~= 0 and (caster:GetAbsOrigin()-target:GetAbsOrigin()):Length2D() < 3000 and not target:IsInvulnerable() and caster:GetTeam() ~= target:GetTeam() then

		local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
		local position = target:GetAbsOrigin() - diff*100
		FindClearSpaceForUnit(caster, position, true)		
		target:AddNewModifier(caster, target, "modifier_stunned", {Duration = keys.StunDuration})
		--local multiplier = GetPhysicalDamageReduction(target:GetPhysicalArmorValue(false)) * caster.ArmorPen / 100
		--local damage = caster:GetAttackDamage() * keys.Damage/100
		--DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		caster:RemoveModifierByName("modifier_heart_of_harmony")
		caster:RemoveModifierByName("modifier_heart_of_harmony_invisible")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_heart_of_harmony_movespeed_bonus", {})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_heart_of_harmony_resistance_linger", {})
		caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0})
		-- cooldown
		ReduceCooldown(caster:FindAbilityByName("false_assassin_gate_keeper"), cdr)
		ReduceCooldown(caster:FindAbilityByName("false_assassin_windblade"), cdr)
		ReduceCooldown(caster:FindAbilityByName("false_assassin_tsubame_gaeshi"), cdr)

		local counter = 0
		Timers:CreateTimer(function()
			if counter == keys.AttackCount or not caster:IsAlive() then return end 
			caster:PerformAttack( target, true, true, true, true, false, false, false )
			caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0})
			CreateSlashFx(caster, target:GetAbsOrigin()+RandomVector(500), target:GetAbsOrigin()+RandomVector(500))
			counter = counter+1
			return 0.1
		end)

		local cleanseCounter = 0
		Timers:CreateTimer(function()
			if cleanseCounter >= 10 then return end
			HardCleanse(caster)
			cleanseCounter = cleanseCounter + 1
			return 0.05
		end)


		target:EmitSound("FA.Omigoto")
		EmitGlobalSound("FA.Quickdraw")
	end
	
end


function OnHeartAttackLanded(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage
	--damage = damage * (target:GetPhysicalArmorValue(false) + targetSTR) / 100
	--DoDamage(keys.caster, keys.target, damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)

end

function OnInvisibilityBroken(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_heart_of_harmony_invisible")
end

function TPOnAttack(keys)
	local caster = keys.caster
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	local rand = RandomInt(1, #targets) 
	caster:SetAbsOrigin(targets[1]:GetAbsOrigin() + Vector(RandomFloat(-100, 100),RandomFloat(-100, 100),RandomFloat(-100, 100) ))		
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

-- Destroy effect particle
function OnQuickdrawStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local qdProjectile = 
	{
		Ability = keys.ability,
        EffectName = "particles/custom/false_assassin/fa_quickdraw.vpcf",
        iMoveSpeed = 1500,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = 750,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 1500
	}

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_quickdraw_baseattack_reduction", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_quickdraw_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.4)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector()*1500)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("quickdraw_dash", {
		endTime = 0.5,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("quickdraw_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)

end

function OnQuickdrawHit(keys)
	local caster = keys.caster
	local target = keys.target

	local damage = 500 + keys.caster:GetAgility() * 13
	DoDamage(keys.caster, keys.target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	caster:PerformAttack( target, true, true, true, true, false, false, false )

	local firstImpactIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(firstImpactIndex, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(800,0,150))
    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(0.3,0,0))
end


