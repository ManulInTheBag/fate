emiya_broken_phantasm = class({})

LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function emiya_broken_phantasm:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("cast_range")

    if self:GetCaster():HasModifier("modifier_eagle_eye") then
        range = range + self:GetSpecialValueFor("bonus_range")
    end

    return range
end

function emiya_broken_phantasm:GetAOERadius()
    return 350
end

function emiya_broken_phantasm:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()
    self.hTarget = hTarget
	
    self:EndCooldown()
    hCaster:GiveMana(self:GetManaCost(-1))

    self.pcMarker = ParticleManager:CreateParticleForTeam("particles/custom/archer/archer_broken_phantasm/archer_broken_phantasm_crosshead.vpcf", PATTACH_OVERHEAD_FOLLOW, hTarget, hCaster:GetTeamNumber())
    ParticleManager:SetParticleControl(self.pcMarker, 0, hTarget:GetAbsOrigin() + Vector(0,0,100)) 
    ParticleManager:SetParticleControl(self.pcMarker, 1, hTarget:GetAbsOrigin() + Vector(0,0,100))

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if hTarget:IsHero()then
            Say(hPlayer, "Broken Phantasm targets " .. FindName(hTarget:GetName()) .. ".", true)
        end
    end
end

function emiya_broken_phantasm:OnChannelFinish(bInterrupted)
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()

    ParticleManager:DestroyParticle(self.pcMarker, false)
    ParticleManager:ReleaseParticleIndex(self.pcMarker)
    if IsSpellBlocked(hTarget) then 
        Say(hPlayer, "Broken Phantasm failed.", true)
        self:StartCooldown(self:GetCooldown(self:GetLevel()))
        hCaster:SpendMana(self:GetManaCost(-1), self)
        return 
    end
    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if bInterrupted or not hCaster:CanEntityBeSeenByMyTeam(hTarget) or hCaster:GetRangeToUnit(hTarget) > (self:GetCastRange() + 1000) or hCaster:GetMana() < self:GetManaCost(-1) or not IsInSameRealm(hCaster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then 
            Say(hPlayer, "Broken Phantasm failed.", true)
            return
        end
    end

    self:StartCooldown(self:GetCooldown(self:GetLevel()))
    hCaster:SpendMana(self:GetManaCost(-1), self)
    hCaster:EmitSound("Emiya_Caladbolg_" .. math.random(1,2))
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true  and playerHero:GetTeamNumber() == hCaster:GetTeamNumber() then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_w_".. math.random(1,2)})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
    hCaster:RemoveModifierByName("modifier_ubw_chant_count")

    local enemy = PickRandomEnemy(hCaster)

    if enemy then
        hCaster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 2 })
    end

    local tProjectile = {
        Target = hTarget,
        Source = hCaster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf",
        iMoveSpeed = 3000,
        vSourceLoc = hCaster:GetAbsOrigin(),
        bDodgeable = true,
        bIsAttack = true,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    }
    ProjectileManager:CreateTrackingProjectile(tProjectile)
end

function emiya_broken_phantasm:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    local fTargetDamage = self:GetSpecialValueFor("target_damage") + self:GetSpecialValueFor("splash_damage")
    local fSplashDamage = self:GetSpecialValueFor("splash_damage")
    local fRadius = self:GetSpecialValueFor("radius")
    local fStun = self:GetSpecialValueFor("stun_duration")    

    local pcExplosion = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
    ParticleManager:SetParticleControl(pcExplosion, 3, hTarget:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pcExplosion)

    hTarget:EmitSound("Misc.Crash")
    
    if not hTarget:IsMagicImmune()   and not hTarget:IsInvulnerable() then
        hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", {Duration = fStun})
        DoDamage(hCaster, hTarget, fTargetDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    else
        DoDamage(hCaster, hTarget, fSplashDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    end

    local tTargets = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(tTargets) do
        if v ~= hTarget then
            DoDamage(hCaster, v, fSplashDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
    end
end

function emiya_broken_phantasm:OnUpgrade()
    local hrunt = self:GetCaster():FindAbilityByName("emiya_hrunting_2")
    hrunt:SetLevel(self:GetLevel())
end