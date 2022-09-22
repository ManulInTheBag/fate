vectorA = Vector(0,0,0)

function OnWeakConstitutionThink (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local min_chance = ability:GetSpecialValueFor("min_chance")
	local max_chance = ability:GetSpecialValueFor("max_chance")
	local hp_loss_percent = ability:GetSpecialValueFor("hp_loss_percent")
	local weak_duration = ability:GetSpecialValueFor("weak_duration")
	local stun_duration = ability:GetSpecialValueFor("stun_duration")
	local current_mana = caster:GetManaPercent()
	local hp_loss = caster:GetHealth() * hp_loss_percent / 100

	if not ability:IsCooldownReady() then return end
	if caster:IsIdle() then return end 
	if caster:HasModifier("modifier_okita_focus") then return end
	if caster:HasModifier("modifier_mumyo_check") then return end
	if caster:HasModifier("modifier_zekken") then return end
	if caster:HasModifier("round_pause") then return end

	local random = RandomInt(1, 100)
	local bonus_chance = (100 - current_mana)/5
	local trigger_chance = min_chance + bonus_chance
	if trigger_chance >= max_chance then 
		trigger_chance = max_chance
	end
	if caster:IsMoving() then 
		if trigger_chance >= 17 then 
			trigger_chance = 17
		end
	end
	if random <= trigger_chance then 
		caster:Stop()
		if caster:HasModifier("okita_weak_constitution") then 
			local weak_stack = caster:GetModifierStackCount("modifier_weak_constitution", caster)
			caster:SetModifierStackCount("modifier_weak_constitution", caster, weak_stack + 1)
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_weak_constitution", {duration = weak_duration})
			caster:SetModifierStackCount("modifier_weak_constitution", caster, 1)
		end
	end
end

function OnCoughUp (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local hp_loss_percent = ability:GetSpecialValueFor("hp_loss_percent")
	local stun_duration = ability:GetSpecialValueFor("stun_duration")
	local hp_loss = caster:GetHealth() * hp_loss_percent / 100
	local cough_up = {
		victim = caster,
		attacker = caster,
		damage = hp_loss,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL, --Optional.
		ability = ability, --Optional.
	}
	ability:StartCooldown(ability:GetCooldown(1))
	ApplyDamage(cough_up)
	caster:EmitSound("Okita.Cough")
	caster:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
	--StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_RUN, rate=0.9})
end

function OnShukuchiStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target_loc = ability:GetCursorPosition()
	local leap_range = ability:GetSpecialValueFor("leap_range")
	if IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
		keys.ability:EndCooldown() 
		caster:GiveMana(100) 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Blink")
        return
    end
	OnShukuchiBlink (caster, target_loc, leap_range)
	caster:EmitSound("Okita.Shukuchi")

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_shukuchi_ms", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_shukuchi_breath", {})

	if caster:HasModifier("modifier_okita_focus") then 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_shukuchi_agi", {})
	end

	OkitaCheckCombo(caster, ability)
end

function OnShukuchiBlink (hCaster, vTarget, fMaxDistance, tParams)

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

    ProjectileManager:ProjectileDodge(hCaster)
    FindClearSpaceForUnit(hCaster, vBlinkPos, true)
end

function OnShukuchiBreathStart(keys)
	local caster = keys.caster 
	local ability = keys.ability
	local target = keys.target 
	caster:RemoveModifierByName("modifier_shukuchi_ms")
	caster:RemoveModifierByName("modifier_shukuchi_breath")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_shukuchi_stab", {}) 
end

function OnShukuchiBreathLand(keys)
	local hero = keys.caster:GetPlayerOwner():GetAssignedHero()
	if IsSpellBlocked(keys.target) then keys.caster:RemoveModifierByName("modifier_shukuchi_stab") return end -- Linken effect checker

	if keys.target:GetName() == "npc_dota_ward_base" then
		DoDamage(keys.caster, keys.target, 2, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	else
		DoDamage(keys.caster, keys.target, keys.caster:GetAttackDamage(), DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, keys.ability, false)
	end
	keys.caster:RemoveModifierByName("modifier_shukuchi_stab")
	keys.caster:RemoveModifierByName("modifier_shukuchi_ms")
end

function OnAbilityCast(keys)
	--[[Timers:CreateTimer({
		endTime = 0.033,
		callback = function()
		if keys.ability:GetName() ~= "okita_shukuchi" and args.ability:GetName() ~= "okita_mumyo" then
			keys.caster:RemoveModifierByName("modifier_shukuchi_ms")
		end
	end
	})]]
	if keys.ability:GetName() ~= "okita_shukuchi" and keys.ability:GetName() ~= "okita_mumyo" then
		keys.caster:RemoveModifierByName("modifier_shukuchi_ms")
	else
		keys.caster:RemoveModifierByName("modifier_shukuchi_ms")
	end
	keys.caster:RemoveModifierByName("modifier_shukuchi_breath")
end

function OnAbilityCastBroke(keys)
	local caster = keys.caster 
	local ability = keys.ability 
	if caster.flag == nil then 
		caster.flag = {}
	end
	if IsValidEntity(caster.flag) and ability:GetAbilityName() == "okita_flag_of_sincerity" then
    	caster:Stop()
    end
	caster:RemoveModifierByName("modifier_shukuchi_ms")
	caster:RemoveModifierByName("modifier_shukuchi_breath")
	
end

function OnTenninRishinStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_tennen_base", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_tennen_bonus", {})

end 

function OnTenninRishinAttack (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target = keys.target 
	local bonus_dmg = ability:GetSpecialValueFor("bonus_dmg")
	if target:IsRealHero() or target:IsCreature() or target:IsIllusion() or target:IsCreep() then 
		if caster.tennin_target then
			local tennen_stack = caster:GetModifierStackCount("modifier_tennen_bonus", caster)
			caster:SetModifierStackCount("modifier_tennen_bonus", caster, tennen_stack + 1)
			if caster:HasModifier("modifier_okita_focus") then 
				caster.tennen_hit = caster.tennen_hit + 1
				if caster.tennen_hit % 3 == 0 then
					DoDamage(caster, target, bonus_dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false) 
					target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.1})
				end
			end
		else
			caster:SetModifierStackCount("modifier_tennen_bonus", caster, 1)
			caster.tennin_target = target
			if caster:HasModifier("modifier_okita_focus") then 
				caster.tennen_hit = 1
			end
		end
	else
		caster:SetModifierStackCount("modifier_tennen_bonus", caster, 0)
		if caster:HasModifier("modifier_okita_focus") then 
			caster.tennen_hit = 0
		end
	end
end 

function OnTenninRishinDestroy (keys)
	local caster = keys.caster
	caster.tennen_hit = 0
end

function OnFlagStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local flag_origin = ability:GetCursorPosition()
	local radius = ability:GetSpecialValueFor("radius")
	local summon_count = ability:GetSpecialValueFor("summon_count")
	local duration = ability:GetSpecialValueFor("duration")
	local flag_health = ability:GetSpecialValueFor("flag_health")



	if IsValidEntity(caster.flag) then
    	ability:EndCooldown()
    	caster:GiveMana(ability:GetManaCost(ability:GetLevel())) 
    	return
    end

    if (caster:GetOrigin() - flag_origin):Length2D() > 500 then 
    	ability:EndCooldown()
    	caster:GiveMana(ability:GetManaCost(ability:GetLevel())) 
    	return 
    end
    local iskandar = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_ANY_ORDER, false)
    for _,iskander in pairs(iskandar) do
    	if iskander:GetName() == "npc_fate_hero_chen" then 
    		caster.bIskandarAllied = true
    	end
    end

		caster.flag = CreateUnitByName("okita_flag", flag_origin, true, nil, nil, caster:GetTeamNumber())
		caster.flag:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
		caster.flag:SetBaseMaxHealth(flag_health)
		caster.flag:SetControllableByPlayer(caster:GetPlayerID(), true)
		caster.flag:FindAbilityByName("okita_flag_of_sincerity_passive"):SetLevel(1)

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_flag_summon", {})

		caster.currentflaghealth = flag_health
		caster.flagorigin = flag_origin
		caster.flagradius = radius
		caster.duration = duration
		if caster.flag:GetOrigin().y >= -2000 then 
			caster.flagspawnrealworld = true
		--print('flag spawn real world')
		else 
	 		caster.flagspawnrealworld = false
		end


		if caster.IsHeadbandAcquired then 
			summon_count = summon_count + 1 
		end

		if caster.shinsengumi == nil then 
			caster.shinsengumi = {}
		end

		for i = 1,summon_count do
    		caster.shinsengumi[i] = CreateUnitByName("okita_shinsengumi", flag_origin + RandomVector(150) , true, nil, nil, caster:GetTeamNumber())
    		FindClearSpaceForUnit(caster.shinsengumi[i], flag_origin + RandomVector(150), true)
    		caster.shinsengumi[i]:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
    		caster.shinsengumi[i]:SetControllableByPlayer(caster:GetPlayerID(), true)
			caster.shinsengumi[i]:SetForwardVector(caster:GetForwardVector())
			caster.shinsengumi[i]:FindAbilityByName("okita_shinsengumi_passive"):SetLevel(1)
			if caster.IsHeadbandAcquired then 
				ability:ApplyDataDrivenModifier(caster, caster.shinsengumi[i], "modifier_head_band_buff", {})
			end
			caster.shinsengumi[i]:CreatureLevelUp(ability:GetLevel() - 1)
   		end
   		caster.shinsengumi_count = summon_count

   	--particle area 
   		local sacredZoneFx = ParticleManager:CreateParticle("particles/custom/ruler/luminosite_eternelle/sacred_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(sacredZoneFx, 0, flag_origin)
		ParticleManager:SetParticleControl(sacredZoneFx, 1, Vector(1,1,radius))
		ParticleManager:SetParticleControl(sacredZoneFx, 14, Vector(radius,radius,0))
		ParticleManager:SetParticleControl(sacredZoneFx, 4, Vector(-5,0,0) + flag_origin) -- Cross arm lengths
		ParticleManager:SetParticleControl(sacredZoneFx, 5, Vector(5,0,0) + flag_origin)
		ParticleManager:SetParticleControl(sacredZoneFx, 6, Vector(0,-5,0) + flag_origin)
		ParticleManager:SetParticleControl(sacredZoneFx, 7, Vector(0,5,0) + flag_origin)
		caster.CurrentFlagParticle = sacredZoneFx

end

function OnFlagTakeDamagePassive (keys)
	local target = keys.caster 
	local ply = target:GetMainControllingPlayer()
	local hero = PlayerResource:GetPlayer(ply):GetAssignedHero()
	--local hero = target:GetPlayerOwner():GetAssignedHero() 
	local ability = keys.ability
	local currenthealth = target:GetHealth()
	if target:IsAlive() then
		currenthealth = currenthealth - 1
		target:SetHealth(currenthealth)
		if currenthealth <= 0 then
			OnFlagDeathPassive (keys)
		end
	end
end

function OnFlagThinkPassive (keys)
	local target = keys.caster 
	local ply = target:GetMainControllingPlayer()
	local hero = PlayerResource:GetPlayer(ply):GetAssignedHero()
	--local hero = target:GetPlayerOwner():GetAssignedHero() 
	local ability = keys.ability 
	if hero.shinsengumi_count <= 0 then 
		if IsValidEntity(target) then
			ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
			ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle )
			target:ForceKill(false)
        end
    end
	local okita = FindUnitsInRadius(target:GetTeam(), target:GetOrigin(), nil, hero.flagradius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,h in pairs (okita) do
		if h:GetUnitName() == hero:GetUnitName() then 
			if hero.IsHeadbandAcquired then 
				if not h:HasModifier("modifier_weak_buff") then
					ability:ApplyDataDrivenModifier(target, h, "modifier_weak_buff", {})
				end
			end
			
			if h:HasModifier("modifier_weak_constitution") then 
				if h:GetAbsOrigin().y < -2000 and h:GetAbsOrigin().x < 3300 and hero.bIskandarAllied then 
				elseif not hero.bIskandarAllied then 
					for _,v in pairs(hero.shinsengumi) do
						if v and IsValidEntity(v) then
							ability:ApplyDataDrivenModifier(target, v, "modifier_weak_buff", {})
						end
					end
				end
			end
		end
	end
	
	if IsValidEntity(target) then
		if target:HasModifier("round_pause") then 
			target:ForceKill(false) 
			ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
			ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle )
		end
		if not IsInSameRealm(target:GetOrigin(), hero:GetOrigin()) then 
			ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
			ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle )
			target:ForceKill(false)
		elseif IsInSameRealm(target:GetOrigin(), hero:GetOrigin()) then 
			if target:GetOrigin().y <= -2000 then 
				flag_changecentermarble = false
				if hero.flagspawnrealworld == true and flag_changecentermarble == false then
					--ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
					--ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle ) 
					hero.flagorigin = target:GetOrigin()
					Timers:CreateTimer(0.1, function() 
						--local sacredZoneFx = ParticleManager:CreateParticle("particles/custom/ruler/luminosite_eternelle/sacred_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 0, target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 1, Vector(1,1,hero.flagradius))
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 14, Vector(hero.flagradius,hero.flagradius,0))
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 4, Vector(-5,0,0) + target:GetOrigin()) -- Cross arm lengths
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 5, Vector(5,0,0) + target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 6, Vector(0,-5,0) + target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 7, Vector(0,5,0) + target:GetOrigin())
						--hero.CurrentFlagParticle = sacredZoneFx
					end)
				
					flag_changecentermarble = true
				end
			elseif target:GetOrigin().y > -2000 then 
				flag_changecenter = false
				if hero.flagspawnrealworld == false and flag_changecenter == false then 
					--ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
					--ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle )
					hero.flagorigin = target:GetOrigin()
					Timers:CreateTimer(0.1, function() 
						--local sacredZoneFx = ParticleManager:CreateParticle("particles/custom/ruler/luminosite_eternelle/sacred_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 0, target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 1, Vector(1,1,hero.flagradius))
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 14, Vector(hero.flagradius,hero.flagradius,0))
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 4, Vector(-5,0,0) + target:GetOrigin()) -- Cross arm lengths
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 5, Vector(5,0,0) + target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 6, Vector(0,-5,0) + target:GetOrigin())
						ParticleManager:SetParticleControl(hero.CurrentFlagParticle, 7, Vector(0,5,0) + target:GetOrigin())
						--hero.CurrentFlagParticle = sacredZoneFx
					end)
					flag_changecenter = true
				end
			end
		end
	end

	for _,s in pairs(hero.shinsengumi) do
		if s and IsValidEntity(s) then
			if not IsInSameRealm(target:GetOrigin(), s:GetOrigin()) then 
				s:ForceKill(false)
			end
        end
	end
end 

function OnOkitaDeath (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	if caster.flag == nil then 
		caster.flag = {}
	end
	if IsValidEntity(caster.flag) then
		--OnFlagDeath (keys)
		OnFlagDeathPassive (keys)
	end
end

function OnFlagDeathPassive (keys)
	local target = keys.caster 
	local ply = target:GetMainControllingPlayer()
	local hero = PlayerResource:GetPlayer(ply):GetAssignedHero()
	--local hero = target:GetPlayerOwner():GetAssignedHero() 
	ParticleManager:DestroyParticle( hero.CurrentFlagParticle, false )
	ParticleManager:ReleaseParticleIndex( hero.CurrentFlagParticle )
	hero:RemoveModifierByName("modifier_flag_summon")
	local ability = keys.ability 
	for _,v in pairs(hero.shinsengumi) do
		if v and IsValidEntity(v) then
            v:ForceKill(false)
            UTIL_Remove(v)
        end
	end
	if hero:HasModifier("modifier_weak_buff") then 
		hero:RemoveModifierByName("modifier_weak_buff")
	end
	
end 

function OnShinsengumiThinkPassive (keys)
	local target = keys.caster 
	local ply = target:GetMainControllingPlayer()
	local hero = PlayerResource:GetPlayer(ply):GetAssignedHero()
	--local hero = target:GetPlayerOwner():GetAssignedHero() 
    if not IsInSameRealm(target:GetOrigin(), hero.flag:GetOrigin()) or not IsValidEntity(hero.flag) then 	
    	if target:IsAlive() then
        	target:RemoveSelf()
        end
	else
		if math.abs((target:GetOrigin() - hero.flagorigin):Length2D()) > hero.flagradius then
			local diff = target:GetOrigin() - hero.flagorigin
			diff = diff:Normalized()

			target:SetAbsOrigin(hero.flagorigin + diff * hero.flagradius)
	--print("Abs Origin To Set", (TheatreCenter + diff * self.TheatreSize))
			FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
		end
	end
end 

function OnShinsengumiDeath (keys)
	local target = keys.caster 
	local ply = target:GetMainControllingPlayer()
	local hero = PlayerResource:GetPlayer(ply):GetAssignedHero()
	hero.shinsengumi_count = hero.shinsengumi_count - 1
	--print(hero.shinsengumi_count)
end

function OnMumyoCast (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target = keys.target 
	EmitGlobalSound("Okita.Mumyo")
	if caster:HasModifier("modifier_okita_focus") then 
		ability:SetOverrideCastPoint(0.5)
	else
		ability:SetOverrideCastPoint(0.9)
	end
end

function OnMumyoStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target = keys.target 
	local origin = caster:GetAbsOrigin() 
	local target_loc = target:GetAbsOrigin() 
	local range = ability:GetSpecialValueFor("distance")

	local distance = (target_loc - origin):Length2D()

	if distance > range then 
		ability:EndCooldown()
		caster:SetMana(caster:GetMana() + 800)
	elseif distance < range / 10 then 
		-- run only 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mumyo_check", {})
		if caster:HasModifier("modifier_weak_constitution") and not caster:HasModifier("modifier_okita_focus_check") then return end
		OnMumyoDash (caster, ability, target, distance,false)
		OnMumyoSlash (caster, ability, target)

	elseif distance >= range / 10 and distance <= range then 
		-- run then blink 
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mumyo_check", {})
		if caster:HasModifier("modifier_weak_constitution") and not caster:HasModifier("modifier_okita_focus_check") then return end
		OnMumyoDash (caster, ability, target, distance/3,true)
		OnMumyoSlash (caster, ability, target)
	end
end 

function OnMumyoDash (caster, ability, target, distance, bBlink)
	local okita = Physics:Unit(caster)
	local caster_origin = caster:GetAbsOrigin()
	local mumyodas_direction = (target:GetOrigin() - caster_origin):Normalized()
	local velocity = 0
	if caster:HasModifier("modifier_enkidu_hold") and not caster:HasModifier("modifier_okita_focus") then return end

	if bBlink == true then 
		velocity = distance * 2
		if distance < 110 then 
			distance = 50
		end
		giveUnitDataDrivenModifier(caster, caster, "drag_pause", 0.5)
		giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)
		Timers:CreateTimer(0.5, function() 
			if caster:IsAlive() then
				-- particle sonic boom
				giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.7)
			end
		end)
		caster:PreventDI()
		caster:SetPhysicsFriction(0)
		local vectorC = mumyodas_direction
		-- get the direction where target will be pushed back to
		local vectorB = vectorC - vectorA
		caster:SetPhysicsVelocity(vectorB:Normalized() * velocity)
		caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_RUN, rate=0.7})

		caster:OnPhysicsFrame(function(unit)
			local caster_pos = unit:GetAbsOrigin()
			local diff = caster_pos - caster_origin
			local n_diff = diff:Normalized()
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
			if diff:Length() > distance or caster:HasModifier("modifier_enkidu_hold") and not caster:HasModifier("modifier_okita_focus") then -- if pushback distance is over 150, stop it
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
			end
		end)
	elseif bBlink == false then 
		velocity = distance * 2
		giveUnitDataDrivenModifier(caster, caster, "drag_pause", 0.5)
		giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)
		Timers:CreateTimer(0.5, function() 
			if caster:IsAlive() then
				if caster:HasModifier("modifier_enkidu_hold") and not caster:HasModifier("modifier_okita_focus") then return end
				giveUnitDataDrivenModifier(caster, caster, "drag_pause", 0.5)
			end
		end)
	end
end 

function OnMumyoSlash (caster, ability, target)
	local first_hit_dmg = ability:GetSpecialValueFor("first_hit")
	local second_hit_dmg = ability:GetSpecialValueFor("second_hit")
	local third_hit_dmg = ability:GetSpecialValueFor("third_hit")
	local agi_ratio = ability:GetSpecialValueFor("agi_ratio")
	local agi_caster = caster:GetAgility()
	local agi_target = 0
	local hit_rate_bonus = 0
	if target:IsRealHero() then
		agi_target = target:GetAgility()
		hit_rate_bonus = agi_caster - agi_target
	else
		hit_rate_bonus = 50
	end
	local first_hit_miss = 35
	local second_hit_miss = 20
	local hit_count = 0
	local delay = 0.5
	local delay_per_slash = 0.2
	if caster:HasModifier("modifier_enkidu_hold") and not caster:HasModifier("modifier_okita_focus") then return end
	--first slash
	Timers:CreateTimer(delay, function() 
		if caster:IsAlive() and target:IsAlive() then
			EmitGlobalSound("Okita.Sandanzuki")
			if caster:HasModifier("out_of_game") then return end 
			first_hit_miss = 35 - hit_rate_bonus
			if first_hit_miss > 50 then 
				first_hit_miss = 50
			elseif first_hit_miss <= 0 then 
				first_hit_miss = 0
			end
			if caster:HasModifier("modifier_okita_focus") then 
				first_hit_dmg = first_hit_dmg + (agi_caster * agi_ratio)
				first_hit_miss = 0
			end
			--inc evade for dodge ability
			if target:HasModifier("modifier_diarmuid_minds_eye") or target:HasModifier("modifier_instinct_active") then 
				first_hit_miss = 50
			end
			if caster:HasModifier("modifier_shukuchi_ms") then 
				first_hit_miss = first_hit_miss - 10
				if first_hit_miss <= 0 then 
					first_hit_miss = 0
				end
			end
			-- decrease evade for block ability
			if target:HasModifier("modifier_rho_aias") or target:HasModifier("modifier_rune_of_protection") or target:HasModifier("modifier_argos_shield") or target:HasModifier("modifier_mantra_ally") then 		
				first_hit_miss = 0
			end
			local first_random = RandomInt(1, 100)
			if first_random <= first_hit_miss and first_random > 0 then 
				PerformThrust(caster,ability, target, 0, true, 1)
			elseif first_hit_miss <= 0 then 
				if target:HasModifier("modifier_rho_aias") or target:HasModifier("modifier_rune_of_protection") or target:HasModifier("modifier_argos_shield") or target:HasModifier("modifier_mantra_ally") then 
					target:RemoveModifierByName("modifier_rho_aias")
					target:RemoveModifierByName("modifier_argos_shield")
					target:RemoveModifierByName("modifier_rune_of_protection")
					target:RemoveModifierByName("modifier_mantra_ally")
					PerformThrust(caster,ability, target, 0, true, 1)
				else
					PerformThrust(caster,ability, target, first_hit_dmg, false, 1)
				end
				hit_count = hit_count + 1
			elseif first_random > first_hit_miss then
				PerformThrust(caster,ability, target, first_hit_dmg, false, 1)
				hit_count = hit_count + 1
			end
		else 
			caster:RemoveModifierByName("jump_pause")
			return
		end
	end) 

	delay = delay + delay_per_slash

	--second slash
	Timers:CreateTimer(delay, function() 
		if caster:IsAlive() and target:IsAlive() then
			if caster:HasModifier("out_of_game") then return end 
			
			second_hit_miss = 20- hit_rate_bonus
			if second_hit_miss > 25 then 
				second_hit_miss = 25
			elseif second_hit_miss <= 0 then 
				second_hit_miss = 0
			end
			if caster:HasModifier("modifier_okita_focus") then 
				second_hit_dmg = second_hit_dmg + (agi_caster * agi_ratio)
				second_hit_miss = 0
			end	
			--inc evade for dodge ability
			if target:HasModifier("modifier_diarmuid_minds_eye") or target:HasModifier("modifier_instinct_active") then 
				second_hit_miss = 25
			end
			-- decrease evade for block ability
			if target:HasModifier("modifier_rho_aias") or target:HasModifier("modifier_rune_of_protection") or target:HasModifier("modifier_argos_shield") or target:HasModifier("modifier_mantra_ally") then 
				second_hit_miss = 0
			end
			local second_random = RandomInt(1, 100)
			if second_random <= second_hit_miss and second_random > 0 then 
				PerformThrust(caster,ability, target, 0, true, 2)
			elseif second_hit_miss <= 0 then
				if target:HasModifier("modifier_rho_aias") or target:HasModifier("modifier_rune_of_protection") or target:HasModifier("modifier_argos_shield") or target:HasModifier("modifier_mantra_ally") then 
					target:RemoveModifierByName("modifier_rho_aias")
					target:RemoveModifierByName("modifier_argos_shield")
					target:RemoveModifierByName("modifier_rune_of_protection")
					target:RemoveModifierByName("modifier_mantra_ally")
					PerformThrust(caster,ability, target, 0, true, 2)
				else 
					PerformThrust(caster,ability, target, second_hit_dmg, false, 2)
				end
				hit_count = hit_count + 1
			elseif second_random > second_hit_miss then
				PerformThrust(caster,ability, target, second_hit_dmg, false, 2)
				hit_count = hit_count + 1 
			end
		else
			caster:RemoveModifierByName("jump_pause")
			return
		end 
	end)

	delay = delay + delay_per_slash

	--third slash
	Timers:CreateTimer(delay, function() 
		if caster:IsAlive() and target:IsAlive() then
			if caster:HasModifier("modifier_okita_focus") then 
				third_hit_dmg = third_hit_dmg + (agi_caster * agi_ratio)
			end
			PerformThrust(caster,ability, target, third_hit_dmg, false, 3)
			hit_count = hit_count + 1
			print('Hit Count :'.. hit_count)

			if caster.IsKikuIchimonjiAcquired then 
				if hit_count == 3 then 
					DoDamage(caster, target, 500, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, ability, false) 
					target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.9})
				end
			end
		else
			--remove particle
		end 
	end)
		
	--always cough up 
	Timers:CreateTimer(delay + 0.2, function()
		if caster:IsAlive() then
			if not caster:HasModifier("modifier_okita_focus") then
				if caster:HasModifier("okita_weak_constitution") then 
					local weak_stack = caster:GetModifierStackCount("modifier_weak_constitution", caster)
					caster:SetModifierStackCount("modifier_weak_constitution", caster, weak_stack + 1)
				else
					local weak_constitution = caster:FindAbilityByName("okita_weak_constitution")
					weak_constitution:ApplyDataDrivenModifier(caster, caster, "modifier_weak_constitution", {duration = 2.0})
					caster:SetModifierStackCount("modifier_weak_constitution", caster, 1)
				end
			end
		end
	end)
end

function PerformThrust(caster,ability, target, damage, iEvade, thrust)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
	ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

	--[[if soundQueue == 1 then 
		target:EmitSound("Tsubame_Focus")
		flag = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
		target:RemoveModifierByName("modifier_master_intervention")
	elseif soundQueue == 2 then
		target:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	else
		target:EmitSound("Hero_Juggernaut.PreAttack")
	end]]

	if iEvade == true then
		damage = 0
	end

	StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK_EVENT, rate=3.0})
	DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, ability, false) 
	print('Thrust' .. ':'.. thrust .. ':' ..damage)

end
	
function OnFocusStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_focus", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_focus_cooldown", {})
end

function OnFocusCrit (keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_focus_crit_hit", {})
end

function OnFocusEnd (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	caster:FindAbilityByName("okita_weak_constitution"):ApplyDataDrivenModifier(caster, caster, "modifier_weak_constitution", {duration = 10})
	local weak_stack = caster:GetModifierStackCount("modifier_weak_constitution", caster) or 0
	caster:SetModifierStackCount("modifier_weak_constitution", caster, weak_stack + 3)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_focus_check", {})
end

function OnMindEyeStart (keys)
	local caster = keys.caster 
	local ability = keys.ability 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_mind_eye", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_okita_mind_eye_cooldown", {})
end

function OnMindEyeThink(keys)
	local caster = keys.caster
	local ability = keys.ability
	ProjectileManager:ProjectileDodge(caster)
end

function OnMindEyeTakeDamage(keys)
	local caster = keys.caster 
	local ability = keys.ability 
	local target = keys.attacker
	if caster:GetTeam() ~= target:GetTeam() then
		caster:RemoveModifierByName("modifier_okita_mind_eye")
		caster:SetHealth(caster:GetHealth() + keys.DamageTaken)
		HardCleanse(caster)
		if (caster:GetAbsOrigin()-target:GetAbsOrigin()):Length2D() < 500 then 
			local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
			local position = target:GetAbsOrigin() - distance*100
			FindClearSpaceForUnit(caster, position, true)		
			target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 0.7})
			caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0})
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.33)
			Timers:CreateTimer(0.1,function()
				if not caster:IsAlive() then return end 
				caster:PerformAttack( target, true, true, true, true, false, false, false )
			end)
		elseif (caster:GetAbsOrigin()-target:GetAbsOrigin()):Length2D() >= 500 then 
			local backvec = -caster:GetForwardVector()
			local dashback = Physics:Unit(caster)
			local origin = caster:GetOrigin()

		    caster:PreventDI()
		    caster:SetPhysicsFriction(0)

			local vectorC = backvec
			-- get the direction where target will be pushed back to
			local vectorB = vectorC - vectorA
			caster:SetPhysicsVelocity(vectorB:Normalized() * 500 * 3)
	   		caster:SetNavCollisionType(PHYSICS_NAV_HALT)
	   		StartAnimation(caster, {duration=0.33, activity=ACT_DOTA_CAST_ABILITY_3, rate=3.0})
	   		giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.33)
		
			caster:OnPhysicsFrame(function(unit) -- pushback distance check
				local unitOrigin = unit:GetAbsOrigin()
				local diff = unitOrigin - origin
				local n_diff = diff:Normalized()
				unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
				if diff:Length() > 500 or not caster:HasModifier("jump_pause") then -- if pushback distance is over 150, stop it
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					unit:OnPhysicsFrame(nil)
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
				end
			end)
		end
	end
end

function OkitaCheckCombo(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("okita_shukuchi") and caster:FindAbilityByName("okita_mumyo"):IsCooldownReady() and not caster:HasModifier("modifier_zekken_cooldown") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_zekken_window", {})	
		end
	end
end

function OnZekkenWindow(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("okita_mumyo", "okita_zekken", false, true) 
end

function OnZekkenWindowDestroy(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:SwapAbilities("okita_mumyo", "okita_zekken", true, false)
end

function OnZekkenWindowDied(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_zekken_window")
end

function OnZekkenStart (keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target 
	if not caster:IsRealHero() then
		ability:EndCooldown()
		caster:SetMana(caster:GetMana() + 800)
		return
	end
	
	local caster_origin = caster:GetAbsOrigin() 
	local target_loc = target:GetAbsOrigin() 
	local range = ability:GetSpecialValueFor("range")
	local hit_count = ability:GetSpecialValueFor("hit_count")
	local last_hit = ability:GetSpecialValueFor("last_hit")
	local agi_ratio = ability:GetSpecialValueFor("agi_ratio")
	local atk = caster:GetAttackDamage()

	if caster.IsKikuIchimonjiAcquired then 
		last_hit = last_hit + 1000 
	end

	if caster:HasModifier("modifier_okita_focus") then 
		last_hit = last_hit + (agi_ratio * caster:GetAgility())
	end

	local distance = (target_loc - caster_origin):Length2D()

	if distance > range then 
		ability:EndCooldown()
		caster:SetMana(caster:GetMana() + 800)
	else
		-- Set master's combo cooldown
		local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
		masterCombo:EndCooldown()
		masterCombo:StartCooldown(keys.ability:GetCooldown(1))
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_zekken", {})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_zekken_cooldown", {})
		caster:FindAbilityByName("okita_mumyo"):StartCooldown(45)
		caster:RemoveModifierByName("modifier_zekken_window")
		EmitGlobalSound("Okita.Precombo")
		giveUnitDataDrivenModifier(caster, caster, "drag_pause", 0.5)
		OnMumyoDash (caster, ability, target, distance / 3 ,true)
		
		Timers:CreateTimer(0.5 , function() 
			
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 2.6)
			giveUnitDataDrivenModifier(caster, target, "jump_pause", 2.5)
			local target_ground = target:GetAbsOrigin()
			for i = 1,hit_count do
				Timers:CreateTimer( i * 0.1 , function() 
					if caster:IsAlive() and target:IsAlive() then
						if i == 1 then 
							caster:SetModel("models/development/invisiblebox.vmdl")
							caster:AddNewModifier(caster, target, "modifier_camera_follow", {duration = 1.0})  
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_zekken_reduction", {})
						end
						if not caster:IsAlive() then caster:SetModel("models/okita/okita_new.vmdl") return end
						caster:PerformAttack( target, true, true, true, true, false, false, false )
						if caster:HasModifier("modifier_tennen_bonus") then 
							local tennen_stack = caster:GetModifierStackCount("modifier_tennen_bonus", caster)
							caster:SetModifierStackCount("modifier_tennen_bonus", caster, tennen_stack + 1)
							caster.tennin_target = target
						end
						StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3.0})
						CreateSlashFx(caster, target:GetAbsOrigin()+RandomVector(300), target:GetAbsOrigin()+RandomVector(300))
						if i == hit_count then 
							caster:SetAbsOrigin(target:GetAbsOrigin()-(caster_origin - target:GetAbsOrigin()):Normalized() * 500)
							local caster_pos_lasthit = target:GetOrigin()
							caster:SetForwardVector(caster_origin - (target:GetAbsOrigin()):Normalized())
							StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
							caster:SetModel("models/okita/okita_new.vmdl")
						else
							caster:SetAbsOrigin(target:GetAbsOrigin()+RandomVector(300))
						end
						target:SetAbsOrigin(target:GetOrigin()+Vector(0,0,5))
						EmitGlobalSound("FA.Quickdraw")
					end
				end)
			end
			Timers:CreateTimer( 1.5 , function()
				for j = 1,10 do
					Timers:CreateTimer( j * 0.1 , function() 
						if caster:IsAlive() and target:IsAlive() then
							target:SetOrigin(target:GetOrigin() - Vector(0,0,7))
						else
							caster:RemoveModifierByName("jump_pause")
						end
					end)
				end
			end)

			Timers:CreateTimer( 2.5 , function()
				if caster:IsAlive() and target:IsAlive() then
					if IsInSameRealm(caster_origin, caster:GetAbsOrigin()) then
						caster:SetAbsOrigin(caster_origin)
					else
						caster:SetAbsOrigin(target:GetAbsOrigin())
					end
					StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK_EVENT, rate=3.0})
					DoDamage(caster, target, last_hit, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, ability, false) 
					CreateSlashFx(caster, caster:GetAbsOrigin(), target:GetAbsOrigin())
					target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 1.0})
					EmitGlobalSound("Okita.Zekken")
					EmitGlobalSound("FA.Quickdraw")
				else
					caster:RemoveModifierByName("jump_pause")
				end
			end)

			--always cough up 
			Timers:CreateTimer(2.7, function()
				if caster:IsAlive() then
					if not caster:HasModifier("modifier_okita_focus") then
						local weak_constitution = caster:FindAbilityByName("okita_weak_constitution")
						weak_constitution:ApplyDataDrivenModifier(caster, caster, "modifier_weak_constitution", {duration = 2.0})
						local weak_stack = caster:GetModifierStackCount("modifier_weak_constitution", caster) or 0
						caster:SetModifierStackCount("modifier_weak_constitution", caster, weak_stack + 2)
					end
				end
			end)
		end)
	end	
end

function OnTennenAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsTennenAcquired = true
	keys.ability:StartCooldown(9999)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnHeadbandAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsHeadbandAcquired = true
	keys.ability:StartCooldown(9999)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnCoatOfOathsAcquired(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsCoatOfOathsAcquired = true
	keys.ability:StartCooldown(9999)
	--hero:SwapAbilities("okita_weak_constitution", "okita_weak_constitution_summer", false, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnSummerMadnessAcquired(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsSummerMadnessAcquired = true
	keys.ability:StartCooldown(9999)
	hero:SwapAbilities("okita_weak_constitution", "okita_jet", false, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnMindEyeAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsMindEyeAcquired = true
	keys.ability:StartCooldown(9999)

	hero:SwapAbilities("fate_empty1", "okita_mind_eye", false, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnKikuIchimonjiAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsKikuIchimonjiAcquired = true
	keys.ability:StartCooldown(9999)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end