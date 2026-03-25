vectorA = Vector(0,0,0)

LinkLuaModifier("modifier_scathach_slow", "abilities/scathach/modifiers/modifier_scathach_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_gate_particle", "abilities/scathach/modifiers/modifier_scathach_gate_particle", LUA_MODIFIER_MOTION_NONE)

function OnRuneMagicStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_scathach_rune_mage_check", {})
	caster.IsMagicUse = false
	ability:EndCooldown()
end

function OnRuneMagicUpgrade (keys)
	local caster = keys.caster 
	caster:FindAbilityByName("scathach_rune_fire"):SetLevel(keys.ability:GetLevel())
	caster:FindAbilityByName("scathach_rune_frost"):SetLevel(keys.ability:GetLevel())
	caster:FindAbilityByName("scathach_rune_blast"):SetLevel(keys.ability:GetLevel())
	caster:FindAbilityByName("scathach_rune_teleport"):SetLevel(keys.ability:GetLevel())
	caster:FindAbilityByName("scathach_rune_heal"):SetLevel(keys.ability:GetLevel())
end

function OnRuneMagicOpen (keys)
	local caster = keys.caster
	local ability = keys.ability 
	-- window
	if caster:HasModifier("modifier_gate_of_sky_window") then 
		caster:RemoveModifierByName("modifier_gate_of_sky_window")
	end
	if caster:HasModifier("modifier_gae_combo_window") then 
		caster:RemoveModifierByName("modifier_gae_combo_window")
	end
	caster:SwapAbilities("scathach_red_wind", "scathach_rune_fire", false, true)
	caster:SwapAbilities("scathach_spearmanship", "scathach_rune_frost", false, true)
	caster:SwapAbilities("scathach_gae_bolg", "scathach_rune_blast", false, true)
	caster:SwapAbilities("scathach_pinning_god", "scathach_rune_teleport", false, true)
	caster:SwapAbilities("scathach_rune_mage", "scathach_rune_close", false, true)
	caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_rune_heal", false, true)
end

function OnRuneMagicClose (keys)
	local caster = keys.caster
	local ability = keys.ability 

	caster:SwapAbilities("scathach_red_wind", "scathach_rune_fire", true, false)
	caster:SwapAbilities("scathach_spearmanship", "scathach_rune_frost", true, false)
	caster:SwapAbilities("scathach_gae_bolg", "scathach_rune_blast", true, false)
	caster:SwapAbilities("scathach_pinning_god", "scathach_rune_teleport", true, false)
	caster:SwapAbilities("scathach_rune_mage", "scathach_rune_close", true, false)
	caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_rune_heal", true, false)
	if caster.IsMagicUse == true and not caster.IsPrimevalRuneAcquired then 
		caster:FindAbilityByName("scathach_rune_mage"):StartCooldown(25.0)
	end
end

function OnRuneMagicCloseStart (keys)
	local caster = keys.caster 
	caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
end

function OnRuneFlameStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target_loc = ability:GetCursorPosition()
	local cast_delay = ability:GetSpecialValueFor("cast_delay")
	local radius = ability:GetSpecialValueFor("radius")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_scathach_fire_check", {})
	caster.IsMagicUse = true
	caster:EmitSound("Scathach.Rune_Fire")
	if not caster.IsPrimevalRuneAcquired then 
		caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
	end
	Timers:CreateTimer(cast_delay, function()
		EmitSoundOnLocationWithCaster(target_loc, "Hero_Shredder.ControlledBurn.Layer", caster)
		local FirePillarFx = ParticleManager:CreateParticle("particles/custom/tamamo/combo/fire_explosion_column.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(FirePillarFx, 0, target_loc)
		Timers:CreateTimer( 0.8, function()
			ParticleManager:DestroyParticle( FirePillarFx, false )
		end)
	end)
	for i = 0,5 do
		Timers:CreateTimer(cast_delay * i, function()
			if not caster:IsAlive() then return end 
			if not caster:HasModifier("modifier_scathach_fire_check") then return end
			local flametargets = FindUnitsInRadius(caster:GetTeam(), target_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _,flame in pairs (flametargets) do
				if not flame:IsMagicImmune() then 
					if caster.IsPrimevalRuneAcquired then 
						ability:ApplyDataDrivenModifier(caster, flame, "modifier_scathach_fire_burn_multiply", {})
					else
						ability:ApplyDataDrivenModifier(caster, flame, "modifier_scathach_fire_burn", {})
					end
				end
			end
		end)
	end
end

function OnRuneFlameCreate (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	target:EmitSound("Hero_Huskar.Burning_Spear")
end

function OnRuneFlameDestroy (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	target:StopSound("Hero_Huskar.Burning_Spear")
end

function OnRuneFlameBurn (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local burn_dps = ability:GetSpecialValueFor("burn_dps")

	if target:IsAlive() then
		if not target:IsMagicImmune() then 
			DoDamage(caster, target, burn_dps * 0.2 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
		end
	end
end

function OnRuneFrostStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local range = ability:GetSpecialValueFor("range")
	local dmg = ability:GetSpecialValueFor("dmg")
	local origin = caster:GetAbsOrigin()
	caster.IsMagicUse = true
	local frostground = ParticleManager:CreateParticle("particles/custom/scathach/scathach_frost.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(frostground, 0, caster:GetAbsOrigin()) 
	ParticleManager:SetParticleControl(frostground, 1, Vector(range,1,1))
	caster:EmitSound("hero_Crystal.freezingField.wind")
	caster:EmitSound("Scathach.Rune_Frost")
	Timers:CreateTimer( 1.0, function()
		ParticleManager:DestroyParticle( frostground, false )
		ParticleManager:ReleaseParticleIndex(frostground)
		caster:StopSound("hero_Crystal.freezingField.wind")
	end)
	local freezetargets = FindUnitsInRadius(caster:GetTeam(), origin, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,freeze in pairs (freezetargets) do
		if not freeze:IsMagicImmune() then 
			ability:ApplyDataDrivenModifier(caster, freeze, "modifier_scathach_freeze", {})
			freeze:EmitSound("hero_Crystal.frostbite")		
		end
		DoDamage(caster, freeze, dmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end
	if not caster.IsPrimevalRuneAcquired then 
		caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
	end
end

function OnRuneFrostCreate (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
end

function OnRuneFrostDestroy (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	target:StopSound("hero_Crystal.frostbite")
end

function OnRuneFrostFreeze (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local freeze_dps = ability:GetSpecialValueFor("freeze_dps")
	local freeze_mana_drain = ability:GetSpecialValueFor("freeze_mana_drain")

	if target:IsAlive() then
		if not target:IsMagicImmune() then 
			DoDamage(caster, target, freeze_dps * 0.1 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
			target:SetMana(target:GetMana() - freeze_mana_drain * 0.1)
		end
	end
end

function OnBlastStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target_loc = ability:GetCursorPosition()
	local distance = ability:GetSpecialValueFor("distance")
	local speed = ability:GetSpecialValueFor("speed")
	local width = 130 
	local origin = caster:GetAbsOrigin()
	local forwardVec = (target_loc - origin):Normalized() 
	local rightVec = caster:GetRightVector()
	local leftVec = -rightVec
	local backVec = -forwardVec
	local origin_1 = origin + (backVec * 100)
	local origin_2 = origin_1 + (leftVec * 100)
	local origin_3 = origin_1 + (leftVec * 200)
	local origin_4 = origin_1 + (rightVec * 100)
	local origin_5 = origin_1 + (rightVec * 200)
	caster:EmitSound("Scathach.Rune_Blast")
	caster:EmitSound("Hero_Mirana.ArrowCast")
	BlastFire (caster,ability,speed,distance,origin_1,forwardVec,width)
	BlastFire (caster,ability,speed,distance,origin_2,forwardVec,width)
	BlastFire (caster,ability,speed,distance,origin_3,forwardVec,width)
	BlastFire (caster,ability,speed,distance,origin_4,forwardVec,width)
	BlastFire (caster,ability,speed,distance,origin_5,forwardVec,width)
	caster.IsMagicUse = true
	if not caster.IsPrimevalRuneAcquired then 
		caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
	end
end

function BlastFire (caster,ability,speed,distance,origin,forwardVec,width)

	local duration = distance / speed

	local blast_dummy = CreateUnitByName("dummy_unit", origin, false, caster, caster, caster:GetTeamNumber())
	blast_dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	blast_dummy:SetForwardVector(forwardVec)	

	local blastfx = ParticleManager:CreateParticle( "particles/custom/scathach/scathach_blast.vpcf", PATTACH_ABSORIGIN_FOLLOW, blast_dummy )
	ParticleManager:SetParticleControl( blastfx, 4, forwardVec * speed)

	Timers:CreateTimer(function()
		if IsValidEntity(blast_dummy) then
			origin = GetGroundPosition(origin + (speed * 0.05) * Vector(forwardVec.x, forwardVec.y, 0), nil)								
			blast_dummy:SetAbsOrigin(origin)
			return 0.05
		else
			return nil
		end
	end)
			
	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle( blastfx, false )
		ParticleManager:ReleaseParticleIndex( blastfx )
		Timers:CreateTimer(0.05, function()
			blast_dummy:RemoveSelf()
			return nil
		end)
		return nil
	end)

	local blast = {
		Ability = ability,
		--EffectName = "particles/units/heroes/hero_mirana/mirana_spell_arrow_launch.vpcf",
		iMoveSpeed = speed,
		vSpawnOrigin = origin,
		fDistance = distance,
		Source = caster,
		fStartRadius = width,
        fEndRadius = width,
		bHasFrontialCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 1,
		bDeleteOnHit = false,
		vVelocity = forwardVec * speed,
		
	}

    local projectile = ProjectileManager:CreateLinearProjectile(blast)
end

function OnBlastHit (keys)
	if keys.target == nil then return end
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local stun = ability:GetSpecialValueFor("stun")
	local dmg = ability:GetSpecialValueFor("dmg")
	if not target:IsMagicImmune() then 
		target:AddNewModifier(caster, nil, "modifier_stunned", {duration = stun})
	end
	DoDamage(caster, target, dmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
end

function OnTeleportCast (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target_loc = ability:GetCursorPosition()
	local range = ability:GetSpecialValueFor("range")
	if IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
		caster:Stop()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Blink")
        return
    end
end

function OnTeleportStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target_loc = ability:GetCursorPosition()
	local range = ability:GetSpecialValueFor("range")
	if IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
		ability:EndCooldown() 
		caster:GiveMana(100) 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Blink")
        return
    end
    caster.IsMagicUse = true
    if not caster.IsPrimevalRuneAcquired then 
		caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
	end
	OnTeleportBlink (caster, target_loc, range)
	
end

function OnTeleportBlink (hCaster, vTarget, fMaxDistance, tParams)

    local tParams = tParams or {}
    local sOutEffect = tParams.sInEffect or "particles/items_fx/blink_dagger_start.vpcf"
    local sInEffect = tParams.sOutEffect or "particles/items_fx/blink_dagger_end.vpcf"
    local sOutSound = tParams.sOutSound or "Hero_Antimage.Blink_out"
    local sInSound = tParams.sInSound or "Hero_Antimage.Blink_in"
    
    local bDodge = true
    if tParams.bDodgeProjectiles ~= nil then bDodge = tParams.bDodgeProjectiles end
    
    local bNavCheck = true
    if tParams.bNavCheck ~= nil then bNavCheck = tParams.bNavCheck end

    local vPos = hCaster:GetAbsOrigin()
    local vDifference = vTarget - vPos
    
    local vDirection = vDifference:Normalized()
    local fDistance = vDifference:Length()
    if fDistance >= fMaxDistance then fDistance = fMaxDistance end
    local vBlinkPos = vPos + (vDirection * fDistance)
    
    if bNavCheck then
		local i = 0
        local iStep = 10
        local iSteps = math.ceil(fDistance / iStep)

        while GridNav:IsBlocked( vBlinkPos ) or not GridNav:IsTraversable( vBlinkPos )do
            i = i + 1
            vBlinkPos = vPos + (vDirection * (fDistance - i * iStep))
            if i >= iSteps then break end
        end
    end
    local pcBlinkOut = ParticleManager:CreateParticle(sOutEffect, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(pcBlinkOut, 0, hCaster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pcBlinkOut)
    hCaster:EmitSound(sOutSound)

    ProjectileManager:ProjectileDodge(hCaster)
    FindClearSpaceForUnit(hCaster, vBlinkPos, true)

    local pcBlinkIn = ParticleManager:CreateParticle(sInEffect, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(pcBlinkIn, 0, hCaster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pcBlinkIn)
    hCaster:EmitSound(sInSound)
end

function OnHealStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local heal_amount = ability:GetSpecialValueFor("heal_amount")
	target:Heal(heal_amount, caster)
	if caster.IsPrimevalRuneAcquired then 
		ability:ApplyDataDrivenModifier(caster, target, "modifier_scathach_rune_heal_buff", {})
	end
	caster.IsMagicUse = true
	if not caster.IsPrimevalRuneAcquired then 
		caster:RemoveModifierByName("modifier_scathach_rune_mage_check")
	end
end

function OnHealBuffCreate (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	caster.healbuff = ParticleManager:CreateParticle("particles/items_fx/healing_clarity.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(caster.healbuff, 0, target:GetAbsOrigin()) 
end

function OnHealBuffDestroy (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	ParticleManager:DestroyParticle( caster.healbuff, false )
	ParticleManager:ReleaseParticleIndex(caster.healbuff)
end

function OnPinningCast (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	if caster:HasModifier("modifier_pinning_god_cooldown") then 
		--caster:Stop()
		--SendErrorMessage(caster:GetPlayerOwnerID(), "#Ability_on_cooldown")
	end
	ability:EndCooldown()
	caster:SetMana(caster:GetMana()+400)
	EmitGlobalSound("Scathach.Pinning_God")
	--caster:EmitSound("Scathach.Pinning_God")
end

function OnPinningInterrupt (keys)
	StopGlobalSound("Scathach.Pinning_God")
end

function OnPinningStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local origin = caster:GetAbsOrigin()
	local speed = ability:GetSpecialValueFor("speed")
	local distance = ability:GetSpecialValueFor("distance")
	--caster:EmitSound("Scathach.Pinning_God")
	ability:StartCooldown(ability:GetCooldown(1))
	caster:SetMana(caster:GetMana() - 400)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_pinning_god_cooldown", {})
	local dodge = true 
	if caster.IsBranchTonelicoAcquired then 
		if IsDivineServant(target) then 
			dodge = true
		end
	end
	
	local lance = {
		Target = target,
		Source = caster, 
		Ability = ability,
		EffectName = "particles/custom/lancer/soaring/spear.vpcf",
		vSpawnOrigin = origin,
		iMoveSpeed = speed,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		bDodgeable = dodge
	}
	ProjectileManager:CreateTrackingProjectile(lance) 
	caster:EmitSound("Hero_DrowRanger.FrostArrows")
end

function OnPinningHit (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local width = ability:GetSpecialValueFor("width")
	local base_dmg = ability:GetSpecialValueFor("base_dmg")
	local bonus_agi_ratio = ability:GetSpecialValueFor("bonus_agi_ratio")
	local stun = ability:GetSpecialValueFor("stun")
	local knockback = ability:GetSpecialValueFor("knockback")
	local wall_dmg = ability:GetSpecialValueFor("wall_dmg")
	local bonus_dmg = caster:GetAgility() * bonus_agi_ratio
	local dmg = base_dmg + bonus_dmg

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.3)

	if IsDivineServant(target) then 
		DoDamage(caster, target, dmg * 1.4 , DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, ability, false)
		target:AddNewModifier(caster, target, "modifier_stunned", { duration = stun })
	else
		DoDamage(caster, target, dmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
		target:AddNewModifier(caster, target, "modifier_stunned", { duration = stun })
	end
	
	local pushTarget = Physics:Unit(target)
	target:EmitSound("Hero_Huskar.ProjectileImpact")
    target:PreventDI()
    target:SetPhysicsFriction(0)
	local vectorC = (target:GetAbsOrigin() - caster:GetAbsOrigin()) 
	-- get the direction where target will be pushed back to
	local vectorB = vectorC - vectorA
	target:SetPhysicsVelocity(vectorB:Normalized() * 1000)
    target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	local initialUnitOrigin = target:GetAbsOrigin()
	
	target:OnPhysicsFrame(function(unit) -- pushback distance check
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if diff:Length() > knockback then -- if pushback distance is over 500, stop it
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			unit:OnPhysicsFrame(nil)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end)
	
	target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		if IsDivineServant(target) then 
			target:AddNewModifier(caster, target, "modifier_stunned", { duration = stun })
		else
			target:AddNewModifier(caster, target, "modifier_stunned", { duration = stun })
		end
		DoDamage(caster, unit, wall_dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end)
end

function OnRedWindStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local origin = caster:GetAbsOrigin() 
	local target_loc = target:GetAbsOrigin()
	local stun = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("damage")

	local diff = target_loc - origin
	CreateSlashFx(caster, caster:GetAbsOrigin() + Vector(0,0,80), caster:GetAbsOrigin() + Vector(0,0,80) + diff:Normalized() * diff:Length2D())
	local rush = 
	{
		Ability = ability,
        EffectName = "",
        iMoveSpeed = 99999,
        vSpawnOrigin = origin,
        fDistance = diff:Length2D(),
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 1.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 99999
	}
	local projectile = ProjectileManager:CreateLinearProjectile(rush)

	caster:SetAbsOrigin(target:GetAbsOrigin() - diff:Normalized() * 100)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	--StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1.5})	
	caster:MoveToTargetToAttack(target)

	ScathachCheckCombo1(caster, ability)

	if IsSpellBlocked(target) then return end

	if caster.IsGodSlayerAcquired then 
		if IsDivineServant(target) then 
			DoDamage(caster, target, damage * 1.2, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})
		else
			DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
			target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})
		end
	else
		DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})
	end

	caster.redwindtarget = target
end

function OnRedwindHit (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target 
	local damage = ability:GetSpecialValueFor("damage")
	if target == nil then return end
	if target == caster.redwindtarget then return end
	DoDamage(caster, target, damage * 0.5 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.1})
end

function OnAttack (keys)
	local caster = keys.caster
	caster:EmitSound("Hero_PhantomLancer.Attack")
end

function OnSpearmanshipStart (keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_scathach_spearmanship", {})
	ScathachCheckCombo1(caster, ability)
	if caster.IsBranchTonelicoAcquired then 
		ScathachCheckCombo2(caster, ability)
	end
end

function OnSpearmanshipAttackStart (keys)
	local caster = keys.caster
	local ability = keys.ability 
	
end

function OnSpearmanshipDeath (keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_scathach_spearmanship")
end

function OnSpearmanshipAttackLand (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	local bonus_dmg = caster:GetAgility()
	local double_atk_chance = ability:GetSpecialValueFor("double_atk_chance")
	local double_spear = false
	if RandomInt(1, 100) <= double_atk_chance and double_spear == false then 
		double_spear = true 
		print('Scathach double attack')
		caster:PerformAttack( target, true, true, true, true, false, false, false )
		StartAnimation(caster, {duration=caster:GetAttackAnimationPoint(), activity=ACT_DOTA_ATTACK_EVENT, rate=3})
	end

	--[[if caster.double_spear == true and target:IsAlive() then 
		if caster:GetAttackTarget() ~= target or not caster:IsAttacking() then 
			caster.double_spear = false
		else
			caster:PerformAttack( target, true, true, true, true, false, false, false )
			caster.double_spear = false
		end
	elseif caster.double_spear == false then 
		caster.double_spear = false
	end]]

	if caster.IsGodSlayerAcquired then 
		if IsDivineServant(target) then 
			if caster.divine_target then
				caster.spear_hit = caster.spear_hit + 1
				if caster.spear_hit % 3 == 0 then
					DoDamage(caster, target, bonus_dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false) 
					target:AddNewModifier(caster, ability, "modifier_scathach_slow", {duration = 1})
				end
			else
				caster.divine_target = target 
				caster.spear_hit = 0
			end
		else
			caster.spear_hit = 0
		end
	end
end

function OnSpearmanshipDestroy (keys)
	local caster = keys.caster
	if caster.IsGodSlayerAcquired then
		caster.spear_hit = 0
	end
end

function GBAttachEffect(keys)
	local caster = keys.caster
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)
	EmitGlobalSound("Scathach.Gae_Bolg")
end


function OnGBTargetHit(keys)
	local caster = keys.caster

	local ability = keys.ability

	if IsSpellBlocked(keys.target) then return end -- Linken effect checker

	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local HBThreshold = ability:GetSpecialValueFor("heart_break")
	local Damage = ability:GetSpecialValueFor("damage")
	local BonusGS = 0

	if caster.IsBranchTonelicoAcquired then 
		if caster:HasModifier("modifier_scathach_spearmanship") then
			Damage = Damage * 1.3
		end
		HBThreshold = HBThreshold + 5
	end

	if caster.IsGodSlayerAcquired then
		if IsDivineServant(target) then
			BonusGS = Damage * 0.2
		end
	end

	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.6})

	giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)

	DoDamage(caster, target, Damage, DAMAGE_TYPE_PURE, 0, ability, false)
	if caster.IsGodSlayerAcquired then
		if IsDivineServant(target) then
			DoDamage(caster, target, BonusGS, DAMAGE_TYPE_PURE, 0, ability, false)
			target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
		else
			target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
		end
	else
		target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
	end
	
	if target:GetHealthPercent() < HBThreshold and not target:IsMagicImmune() and not IsUnExecute(target) then
		PlayHeartBreakEffect(ability, caster, target)
	end  -- check for HB

	-- Add dagon particle
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, keys.caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, keys.target, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.target:GetAbsOrigin(), false)
	local particle_effect_intensity = 600
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	target:EmitSound("Hero_Lion.Impale")
	--PlayNormalGBEffect(target)
	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:DestroyParticle( splat, false )
	end)
end

function PlayHeartBreakEffect(ability, killer, target)
	if target:HasModifier("modifier_avalon") then return end
	--[[local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:DestroyParticle( hb, false )
	end)]]
	target:Execute(ability, killer, { bExecution = true })
end

function PlayNormalGBEffect(target)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)
	
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end 

LinkLuaModifier("modifier_self_disarm", "abilities/cu_chulain/modifiers/modifier_self_disarm", LUA_MODIFIER_MOTION_NONE)

function OnScatGBAOEStart(keys)

	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = ability:GetCursorPosition()
	local radius = keys.Radius
	local projectileSpeed = 1900
	local ply = caster:GetPlayerOwner()
	local ascendCount = 0
	local descendCount = 0
	if (caster:GetAbsOrigin() - targetPoint):Length2D() > 2500 then 
		caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(keys.ability:GetLevel()-1)) 
		keys.ability:EndCooldown() 
		return
	end

	EmitGlobalSound("Scathach.Gae_Bolg_Alternative")

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.8)
	Timers:CreateTimer(0.8, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postdelay", 0.15)
	end)
	Timers:CreateTimer(0.95, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postlock", 0.2)
	end)
	StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_CAST_ABILITY_6, rate=0.6})

	Timers:CreateTimer('sgb_throw', {
		endTime = 0.45,
		callback = function()
		local projectileOrigin = caster:GetAbsOrigin() + Vector(0,0,300)
		local projectile = CreateUnitByName("dummy_unit", projectileOrigin, false, caster, caster, caster:GetTeamNumber())
		projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		projectile:SetAbsOrigin(projectileOrigin)


		local particle_name = "particles/custom/lancer/lancer_gae_bolg_projectile.vpcf"
		local throw_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		ParticleManager:SetParticleControl(throw_particle, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)

		if not caster.IsBranchTonelicoAcquired then
			caster:AddNewModifier(caster, ability, "modifier_self_disarm", { duration = 3 })
		end

		local travelTime = (targetPoint - projectileOrigin):Length() / projectileSpeed
		Timers:CreateTimer(travelTime, function()
			ParticleManager:DestroyParticle(throw_particle, false)
			OnScatGBAOEHit(caster, ability, targetPoint, projectile)
		end)

		--[[if caster.IsBranchTonelicoAcquired then
			if caster:HasModifier("modifier_scathach_spearmanship") then 
				Timers:CreateTimer(0.3, function()
					local throw_particle_2 = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
					ParticleManager:SetParticleControl(throw_particle_2, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)
					Timers:CreateTimer(travelTime, function()
						ParticleManager:DestroyParticle(throw_particle_2, false)
						OnGBAOEHit2(caster, ability, targetPoint, projectile)
					end)
				end)
			end
		end]]
	end
	})

	Timers:CreateTimer('sgb_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 then return end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+50))
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	Timers:CreateTimer("sgb_descend", {
	    endTime = 0.3,
	    callback = function()
	    	if descendCount == 15 then return end
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-50))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})
end

function OnScatGBAOEHit(caster, ability, targetPoint, projectile)
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")

	if caster.IsBranchTonelicoAcquired == true then
		damage = damage + 400
	end

	Timers:CreateTimer(0.15, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if caster.IsGodSlayerAcquired then 
				if IsDivineServant(v) then 
					DoDamage(caster, v, damage * 1.2, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				else
					DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				end
			else
				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end
	        ApplyAirborne(caster, v, 0.25)
	    end
	    projectile:SetAbsOrigin(targetPoint)
	    local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile)
		local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
		local explodeFx1 = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, projectile )
		ParticleManager:SetParticleControl( fire, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( crack, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, projectile:GetAbsOrigin())
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
		caster:EmitSound("Misc.Crash")
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( fire, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
		end)
	end)
	if not caster.IsBranchTonelicoAcquired then
		Timers:CreateTimer(0.75, function()
			ability.Dummy = CreateUnitByName("dummy_unit_ground", targetPoint, false, caster, caster, caster:GetTeamNumber())
			ability.Dummy:FindAbilityByName("dummy_unit_passive_no_fly"):SetLevel(1)

	   	 	local tProjectile = {
	        	Target = caster,
	        	Source = ability.Dummy,
	        	Ability = ability,
	        	EffectName = "particles/custom/lancer/soaring/spear.vpcf",
	        	iMoveSpeed = 3000,
	        	vSourceLoc = ability.Dummy:GetAbsOrigin(),
	        	bDodgeable = false,
	        	flExpireTime = GameRules:GetGameTime() + 10,
	        	iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    	}

	    	ProjectileManager:CreateTrackingProjectile(tProjectile)
		end)	
	end
end

function OnGBAOEHit2(caster, ability, targetPoint, projectile)
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")

	Timers:CreateTimer(0.15, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if caster.IsGodSlayerAcquired == true then 
				if IsDivineServant(v) then 
					damage = damage * 1.2
				end 
			end
	        DoDamage(caster, v, damage / 2, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        ApplyAirborne(caster, v, 0.25)
	    end
	    projectile:SetAbsOrigin(targetPoint)
	    local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile)
		local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
		local explodeFx1 = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, projectile )
		ParticleManager:SetParticleControl( fire, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( crack, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, projectile:GetAbsOrigin())
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
		caster:EmitSound("Misc.Crash")
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( fire, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
		end)
	end)
end

function OnGBReturn (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	if target == nil then return end

	target:RemoveModifierByName("modifier_self_disarm")
	ability.Dummy:RemoveSelf()
end

function OnWisdomOsHauntGroundDetect (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.unit
	local detect = ability:GetSpecialValueFor("detect_duration")
	if ability:IsItem() then return end
	if IsTrueInvis(target) then 
		ability:ApplyDataDrivenModifier(caster, target, "modifier_wisdom_target", {duration = 1})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_wisdom_target", {duration = detect})
	end
end

function OnWisdomSpellThink (keys)
	local caster = keys.caster
	local ability = keys.ability 
	if not caster:HasModifier("modifier_wisdom_spell_block") and not caster:HasModifier("modifier_wisdom_spell_block_cooldown") then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_wisdom_spell_block", {})
	elseif not caster:HasModifier("modifier_wisdom_spell_block") and caster:HasModifier("modifier_wisdom_spell_block_cooldown") then 
		return
	elseif caster:HasModifier("modifier_wisdom_spell_block") and not caster:HasModifier("modifier_wisdom_spell_block_cooldown") then 
		return 
	elseif caster:HasModifier("modifier_wisdom_spell_block") and caster:HasModifier("modifier_wisdom_spell_block_cooldown") then 	
		caster:RemoveModifierByName("modifier_wisdom_spell_block")
	end
end

function OnWisdomSpellBlockDestroy (keys)
	local caster = keys.caster
	local ability = keys.ability 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_wisdom_spell_block_cooldown", {})
end

function OnWisdomSpellBlockCooldownEnd (keys)
	local caster = keys.caster
	local ability = keys.ability 
	if not caster:HasModifier("modifier_wisdom_spell_block_cooldown") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_wisdom_spell_block", {})
	end
end

function OnImmortalKill (keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	local kill_stack = caster:GetModifierStackCount("modifier_immortal_passive", caster) or 0
	if not caster:HasModifier("modifier_immortal_agi") then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_agi", {})
	end
	if IsDivineServant(target) then 
		caster:SetModifierStackCount("modifier_immortal_passive", caster, kill_stack + 1)
		caster:SetModifierStackCount("modifier_immortal_agi", caster, kill_stack + 1)
	end 

	if kill_stack >= 1 then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_evade", {})
	end
	if kill_stack >= 3 then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_crit", {})
	end
	if kill_stack >= 5 then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_aspd", {})
	end
	if kill_stack >= 7 then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_revive", {})
	end
end

function OnImmortalCrit (keys)
	local caster = keys.caster
	local ability = keys.ability 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_immortal_crit_hit", {})
end

function OnImmortalDead (keys)	
	local caster = keys.caster
	local ability = keys.ability 
	caster:SetModifierStackCount("modifier_immortal_passive", caster, kill_stack - 1)
end

function OnImmortalRevive (keys)
	local caster = keys.caster
	local ability = keys.ability 

	if caster:GetHealth() <= 0 and caster:HasModifier("modifier_immortal_revive") then
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
		caster:SetHealth(caster:GetMaxHealth() * 1.0)
		caster:SetModifierStackCount("modifier_immortal_passive", caster, 6)
		caster:SetModifierStackCount("modifier_immortal_agi", caster, 6)
		Timers:CreateTimer(1.0, function()
			caster:RemoveModifierByName("modifier_immortal_revive")
		end)
	end
end

WUsed = false
WTime = 0

function ScathachCheckCombo1(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect(false) >= 29.1 then
		if ability == caster:FindAbilityByName("scathach_spearmanship") then
			WUsed = true
			WTime = GameRules:GetGameTime()
			Timers:CreateTimer({
				endTime = 4,
				callback = function()
				WUsed = false
			end})
		elseif ability == caster:FindAbilityByName("scathach_red_wind") and caster:FindAbilityByName("scathach_rune_mage"):IsCooldownReady() and caster:FindAbilityByName("scathach_combo_gate_of_sky"):IsCooldownReady() and not caster:HasModifier("modifier_gate_of_sky_cooldown") and not caster:HasModifier("modifier_combo_double_gae_bolg_cooldown") then
			if WUsed == true then 
				local newTime =  GameRules:GetGameTime()
				local duration = 4 - (newTime - WTime)
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_gate_of_sky_window", {duration = duration})	
				WUsed = false
			end
		end
	end
end

function OnGateOfSkyWindow(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("scathach_rune_mage", "scathach_combo_gate_of_sky", false, true) 
end

function OnGateOfSkyWindowDestroy(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("scathach_rune_mage", "scathach_combo_gate_of_sky", true, false)
end

function OnGateOfSkyWindowDied(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_gate_of_sky_window")
end


function ScathachCheckCombo2(caster,ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect(false) >= 29.1 and caster.IsBranchTonelicoAcquired then
		if ability == caster:FindAbilityByName("scathach_spearmanship") and caster:FindAbilityByName("scathach_gae_bolg_jump"):IsCooldownReady() and caster:FindAbilityByName("scathach_combo_double_gae_bolg"):IsCooldownReady() and not caster:HasModifier("modifier_combo_double_gae_bolg_cooldown") and not caster:HasModifier("modifier_gate_of_sky_cooldown") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gae_combo_window", {})	
		end
	end
end

function OnGaeComboWindow(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_combo_double_gae_bolg", false, true) 
end

function OnGaeComboWindowDestroy(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_combo_double_gae_bolg", true, false)
end

function OnGaeComboWindowDied(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_gae_combo_window")
end

LinkLuaModifier( "modifier_scathach_gate_cooldown_counter", "abilities/scathach/modifiers/modifier_scathach_gate_cooldown_counter", LUA_MODIFIER_MOTION_NONE )

function OnGateOfSkySound (keys)
	local caster = keys.caster
	local ability = keys.ability
	
	if not caster:HasModifier("modifier_scathach_gate_cooldown_counter") then
		caster:EmitSound("Scathach.Gate_Cast")
		
		caster:AddNewModifier(caster, self, "modifier_scathach_gate_cooldown_counter", { Duration = 5})
	end
	
	if ability:OnAbilityPhaseInterrupted() then 
		StopGlobalSound("Scathach.Gate_Cast")
	end
end

function OnGateOfSkyCast (keys)
	local caster = keys.caster
	local ability = keys.ability
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetSpecialValueFor("range")
	local duration = ability:GetSpecialValueFor("duration")
	local dmg = ability:GetSpecialValueFor("dmg")
	caster:RemoveModifierByName("modifier_gate_of_sky_window")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gate_of_sky_cooldown", {})	
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gate_of_sky_check", {})	
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 5.2)
	SpawnAttachedVisionDummy(caster, caster, radius + 100, duration, false)
	
	StartAnimation(caster, {duration=5.6, activity=ACT_DOTA_AMBUSH, rate=1.0})
	
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))
	ability:StartCooldown(ability:GetCooldown(1))
	
	caster:EmitSound("Hero_Mars.ArenaOfBlood.Crumble")
	
	caster:AddNewModifier(caster, self, "modifier_scathach_gate_particle", { Duration = 4.5 })
	
	EmitGlobalSound("gate_of_skye_door")
	EmitGlobalSound("gate_of_skye_fog")

	Timers:CreateTimer(1.0, function()
		if caster:IsAlive() then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gate_of_sky_buff", {duration = 4.1})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gate_of_sky_pull_aura", {duration = 4.0})	
			EmitGlobalSound("Ability.Focusfire")	
			caster:StopSound("Hero_Mars.ArenaOfBlood.Crumble")
		end
		Timers:CreateTimer(1.5, function()		
			EmitGlobalSound("Scathach.Gate_Of_Sky")
		end)
		Timers:CreateTimer(4.0, function()
			if caster:IsAlive() and caster:HasModifier("modifier_gate_of_sky_check") then 
				EmitGlobalSound("Scathach.Gate_Post")
				local GateTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for k,v in pairs (GateTargets) do 
					if v:IsAlive() then 
						local target_loc = v:GetAbsOrigin()
						local distance = (target_loc - caster:GetAbsOrigin()):Length2D()
						--print(v:GetName() .. ' distance = ' .. distance)
						local far = 1 - (distance / radius )
						--print('far : ' .. far)
						if distance <= 100 then
							if IsUnExecute(v) then
								DoDamage(caster, v, dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
							else
								v:Execute(ability, caster, { bExecution = true })
							end
							giveUnitDataDrivenModifier(caster, v, "revoked", 2.0)
						elseif distance > 100 and distance <= radius then 
							DoDamage(caster, v, dmg * far, DAMAGE_TYPE_MAGICAL, 0, ability, false)
							v:AddNewModifier(caster, nil, "modifier_stunned", {duration = far})
							
						end
					end
				end
			end
		end)
	end)

	-- sound 
	-- find enemy : cant blink 
end 

function OnGateOfSkyCreate (keys)
	local caster = keys.caster
	local ability = keys.ability
	local origin = caster:GetAbsOrigin()
	local backVec = -caster:GetForwardVector()
	caster.gate_of_sky = CreateUnitByName("scathach_gate_dummy", origin + Vector(backVec.x * 50, backVec.y * 50,0), false, caster, caster, caster:GetTeamNumber())
	caster.gate_of_sky:SetForwardVector(caster:GetForwardVector())
	caster.gate_of_sky:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	-- particle Gate at high
	-- gate go down 
end

function OnGateOfSkyDestroy (keys)
	local caster = keys.caster
	StopGlobalSound("Ability.Focusfire")
	if IsValidEntity(caster.gate_of_sky) then
		caster.gate_of_sky:RemoveSelf()
	end
	-- remove Gate 
end

function OnGateOfSkyDeath (keys)
	local caster = keys.caster 
	caster:RemoveModifierByName("modifier_gate_of_sky_check")
	caster:RemoveModifierByName("modifier_gate_of_sky_buff")
	caster:RemoveModifierByName("modifier_gate_of_sky_pull_aura")
end

function OnGateOfSkyPull (keys)
	local caster = keys.caster
	local center = caster:GetAbsOrigin()
	local ability = keys.ability
	local target = keys.target
	local target_origin = target:GetAbsOrigin()		
 	local target_direction = (center - target_origin):Normalized()
    local pullTarget = Physics:Unit(target)

	target:PreventDI()
	target:SetPhysicsFriction(0)
	local vectorC = target_direction
	-- get the direction where target will be pushed back to
	local vectorB = vectorC - vectorA
	target:SetPhysicsVelocity(vectorB:Normalized() * 20)
   	target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	
	target:OnPhysicsFrame(function(unit) -- pushback distance check
	local unitOrigin = unit:GetAbsOrigin()
	local diff = unitOrigin - target_origin
	local n_diff = diff:Normalized()
	unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if (unitOrigin - center):Length2D() < 50 then -- if pushback distance is over 150, stop it
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			unit:OnPhysicsFrame(nil)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end)
end

function OnGateOfSkyBurnMana (keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local mana_burn_sec = ability:GetSpecialValueFor("mana_burn_sec")
	local interval = ability:GetSpecialValueFor("interval")
	local max_mana = target:GetMaxMana()
	local radius = ability:GetSpecialValueFor("range")
	local mana_burn = max_mana * mana_burn_sec * interval / 100
	--print(target:GetName() .. ' mana burn = ' .. mana_burn)

	if target:IsAlive() and caster:IsAlive() then 
		if target:GetMana() > 0 then 
			target:SetMana(target:GetMana() - mana_burn)
		elseif target:GetMana() <= 0 then 
			giveUnitDataDrivenModifier(caster, target, "drag_pause", 0.2)
		end
	end

	local unit_location = target:GetAbsOrigin()
	local vector_distance = caster:GetAbsOrigin() - unit_location
	local distance = (vector_distance):Length2D()
	local direction = (vector_distance):Normalized()
		-- If the target is greater than 40 units from the center, we move them 40 units towards it, otherwise we move them directly to the center
	if distance >= 40 then
		target:SetAbsOrigin(unit_location + (direction * radius / 40))
	else
		target:SetAbsOrigin(unit_location + direction * distance)
	end
end

function OnGateOfSkyPullStop (keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	--[[local pullTarget = Physics:Unit(target)
	if target:IsAlive() then
    	target:PreventDI()
    	target:SetPhysicsVelocity(Vector(0,0,1))
    	target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    	target:FollowNavMesh(false)
    	target:Hibernate(false)

    	Timers:CreateTimer(0.1, function()
        	target:PreventDI(false)
        	target:SetPhysicsVelocity(Vector(0,0,0))
        	target:SetPhysicsAcceleration(Vector(0,0,0))
        	target:OnPhysicsFrame(nil)
        	target:Hibernate(true)
    	end)
    end]]
end

function OnGateOfSkyOpen(keys)
	local caster = keys.caster
	local ability = keys.ability
	-- Gate Open 
	-- Pull Unit 

	-- 4 s calculate how far from gate 
	--deal dmg
end

function OnGaeComboCast (keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	EmitGlobalSound("Scathach.Gae_Combo_Cast")
	-- sound 
	-- cast particle 
end 

function OnGaeComboStart (keys)
	-- 2 gae hit 
	
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local gae_bolg = caster:FindAbilityByName("scathach_gae_bolg")
	local HBThreshold = gae_bolg:GetLevelSpecialValueFor("heart_break", gae_bolg:GetLevel()) 
	local GaeDamage = gae_bolg:GetLevelSpecialValueFor("damage", gae_bolg:GetLevel())
	local bonus_gae_malee = ability:GetSpecialValueFor("gae_malee_dmg")

	caster:RemoveModifierByName("modifier_gae_combo_window")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_combo_double_gae_bolg_cooldown", {})	
	caster:FindAbilityByName("scathach_combo_gate_of_sky"):StartCooldown(150)
	
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName("scathach_combo_gate_of_sky")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))
	ability:StartCooldown(ability:GetCooldown(1))

	if caster.IsGodSlayerAcquired then
		if IsDivineServant(target) then
			GaeBonus = GaeDamage * 0.2
		end
	end

	--StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3})
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.0)

	if IsSpellBlocked(target) then -- Linken effect checker / dodge 1 lance and not stunned 
		DoDamage(caster, target, GaeDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	else
		giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
		DoDamage(caster, target, GaeDamage * 2, DAMAGE_TYPE_PURE, 0, ability, false)
		if IsDivineServant(target) then
			DoDamage(caster, target, GaeBonus * 2, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			giveUnitDataDrivenModifier(caster, target, "revoked", 1.0)
			target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
		else
			target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
		end
		if target:GetHealthPercent() < HBThreshold and not target:IsMagicImmune() and IsUnExecute(target) then
			PlayHeartBreakEffect(ability, caster, target)
		end
		if target:IsAlive() and caster:IsAlive() then 
			for i = 1, 10 do
				Timers:CreateTimer( 0.1 * i, function()
					target:SetAbsOrigin(target:GetAbsOrigin() + Vector(0,0,20))
				end)
			end
			Timers:CreateTimer( 1.0, function()
				giveUnitDataDrivenModifier(caster, target, "pause_sealdisabled", 2.0)
			end)
		end
	end 

	-- Add dagon particle
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	local particle_effect_intensity = 1200
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))

	local dagon_particle_2 = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(dagon_particle_2, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	ParticleManager:SetParticleControl(dagon_particle_2, 2, Vector(particle_effect_intensity))

	target:EmitSound("Hero_Lion.Impale")
	--PlayNormalGBEffect(target)
	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:DestroyParticle( splat, false )
		ParticleManager:DestroyParticle( dagon_particle_2, false )
		ParticleManager:ReleaseParticleIndex(dagon_particle)
		ParticleManager:ReleaseParticleIndex(splat)
		ParticleManager:ReleaseParticleIndex(dagon_particle_2)
	end)

	if target:IsAlive() and caster:IsAlive() then 
		Timers:CreateTimer( 1.0, function()
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 2.0)
			StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4, rate=0.63})
			Timers:CreateTimer( 1.0, function()
				if target:IsAlive() and caster:IsAlive() then 
					EmitGlobalSound("Scathach.Gae_Bolg_Alternative")
					local tProjectile = {
	        			Target = target,
	        			Source = caster,
	        			Ability = ability,
	        			EffectName = "particles/custom/lancer/soaring/spear.vpcf",
	        			iMoveSpeed = 5000,
	        			vSourceLoc = caster:GetAbsOrigin(),
	        			bDodgeable = true,
	        			flExpireTime = GameRules:GetGameTime() + 2,
	        			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    			}
	    			ProjectileManager:CreateTrackingProjectile(tProjectile)
	    			caster:EmitSound("Hero_DrowRanger.FrostArrows")
	    		else
	    			caster:RemoveModifierByName("jump_pause")
	    		end
	    	end)
	    end)
	end
	-- target alive then pause jump + go up (divine revoke) caster jump back + jump pause
	-- timer 
	-- gae thrown
	-- timer deal damage
end

function OnGaeComboHit (keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local gae_bolg_jump = caster:FindAbilityByName("scathach_gae_bolg_jump")
	local radius = gae_bolg_jump:GetSpecialValueFor("radius")
	local damage = gae_bolg_jump:GetLevelSpecialValueFor("damage", gae_bolg_jump:GetLevel())
	local bonus_gae_thrown = ability:GetSpecialValueFor("gae_thrown_dmg")
	if caster.IsGodSlayerAcquired then
		if IsDivineServant(target) then
			damage = damage * 1.2
		end
	end

	DoDamage(caster, target, damage + bonus_gae_thrown, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, ability, false)

	if target:HasModifier("pause_sealdisabled") then 
		target:RemoveModifierByName("pause_sealdisabled")
		--local ground = GetGroundPosition(target:GetAbsOrigin(), nil)
		target:SetAbsOrigin(target:GetAbsOrigin() + Vector(0,0,-200))
		FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
		target:AddNewModifier(caster, target, "modifier_stunned", {duration = 1.0})
		if caster.IsGodSlayerAcquired then
			if IsDivineServant(target) then
				giveUnitDataDrivenModifier(caster, target, "revoked", 1.0)
			end
		end
	else
		Timers:CreateTimer(0.01, function()
			local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, radius
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
				if v ~= target then 
	       			DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        		--v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.25})
	       	 		--v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback )
	        		ApplyAirborne(caster, v, 0.25)
	        	end
	    	end
	    	projectile:SetAbsOrigin(targetPoint)
	    	local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile)
			local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
			local explodeFx1 = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, projectile )
			ParticleManager:SetParticleControl( fire, 0, projectile:GetAbsOrigin())
			ParticleManager:SetParticleControl( crack, 0, projectile:GetAbsOrigin())
			ParticleManager:SetParticleControl( explodeFx1, 0, projectile:GetAbsOrigin())
			ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
			caster:EmitSound("Misc.Crash")
	    	Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( crack, false )
				ParticleManager:DestroyParticle( fire, false )
				ParticleManager:DestroyParticle( explodeFx1, false )
			end)
		end)
	end
end

function OnPrimevalRuneAcquired (keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsPrimevalRuneAcquired = true
	keys.ability:StartCooldown(9999)

	hero:FindAbilityByName("scathach_rune_mage"):SetLevel(2)
	if not hero:FindAbilityByName("scathach_rune_mage"):IsCooldownReady() then 
		hero:FindAbilityByName("scathach_rune_mage"):EndCooldown()
	end

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnGodSlayerAcquired (keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsGodSlayerAcquired = true
	keys.ability:StartCooldown(9999)

	hero:FindAbilityByName("scathach_pinning_god"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnBranchTonelicoAcquired (keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsBranchTonelicoAcquired = true
	keys.ability:StartCooldown(9999)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnWisdomOfHauntGroundAcquired (keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsWisdomOfHauntGroundAcquired = true
	keys.ability:StartCooldown(9999)

	local wisdom = hero:FindAbilityByName("scathach_wisdom_of_haunt_ground")
	wisdom:SetLevel(1)
	wisdom:ApplyDataDrivenModifier(hero, hero, "modifier_wisdom_passive", {})
	wisdom:ApplyDataDrivenModifier(hero, hero, "modifier_wisdom_spell_block", {})

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnImmortalAcquired (keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsImmortalAcquired = true
	keys.ability:StartCooldown(9999)

	local immortal = hero:FindAbilityByName("scathach_immortal")
	immortal:SetLevel(1)
	immortal:ApplyDataDrivenModifier(hero, hero, "modifier_immortal_passive", {})

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end