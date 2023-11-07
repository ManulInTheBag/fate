LinkLuaModifier("modifier_madmans_roar_slow_moderate", "abilities/heracles/pepeg_roar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_madmans_roar_slow_strong", "abilities/heracles/pepeg_roar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_madmans_roar_cooldown", "abilities/heracles/pepeg_roar", LUA_MODIFIER_MOTION_NONE)

berserker_5th_madmans_roar = class({})

--[[function berserker_5th_madmans_roar:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local plyID = caster:GetPlayerID()
	PlayerResource:SetOverrideSelectionEntity(plyID, nil)
    PlayerResource:SetCameraTarget(plyID, caster)

    CameraModule:PositionSlip(plyID, 170 + CameraModule:GetYawAngle(caster), 5, 480 + CameraModule:GetHeightDiff(caster), 400, false, true, 0.5, "min", "decrease")
    Timers:CreateTimer(1, function()
        PlayerResource:SetCameraTarget(plyID, nil)
        CameraModule:InitializeCamera(plyID)
    end)
    return true
end

function berserker_5th_madmans_roar:OnAbilityPhaseInterrupted()
    
end]]

function berserker_5th_madmans_roar:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	--giveUnitDataDrivenModifier(caster, caster, "rb_sealdisabled", 10.0)
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_madmans_roar_silence", {})

	--[[local courageAbility = caster:FindAbilityByName("berserker_5th_courage")
	local courageCooldown = courageAbility:GetCooldown(courageAbility:GetLevel())
	courageAbility:StartCooldown(courageCooldown)]]

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))
	caster:AddNewModifier(caster, self, "modifier_madmans_roar_cooldown", {duration = ability:GetCooldown(1)})
	
	caster:RemoveModifierByName("modifier_heracles_combo_window")
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.zlodemon == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_combo"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	--remove berserk and set health to max
	--[[if caster:HasModifier("modifier_berserk_self_buff") then
		caster:RemoveModifierByName("modifier_berserk_self_buff")
	end
	caster:SetHealth(caster:GetMaxHealth())]]

	--Reset berserk buff with double health lock
	--[[if caster:HasModifier("modifier_heracles_berserk") == false then
		caster:RemoveModifierByName("modifier_heracles_berserk")
		local newKeys = keys
		newKeys.ability = caster:FindAbilityByName("berserker_5th_berserk")
		newKeys.Duration = newKeys.ability:GetSpecialValueFor("duration")
		newKeys.Health = newKeys.ability:GetSpecialValueFor("health_constant")		

		OnBerserkStart(newKeys, false)
	end]]

	--caster:FindAbilityByName("berserker_5th_berserk"):ApplyDataDrivenModifier(caster, caster, "modifier_berserk_self_buff", {hplock = hplock * 2})		
	--caster:SetRenderColor(255, 127, 127)

	caster:FindAbilityByName("heracles_berserk"):EnterBerserk(self:GetSpecialValueFor("bers_duration"))

	local soundQueue = math.random(1,100)
	EmitGlobalSound("berserker_roar_02")
	LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
        	-- apply legion horn vsnd on their client
        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Haru_Yok"})
        	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	Timers:CreateTimer(1.72, function()
		StopGlobalSound("Haru_Yo")
		end)

	local Damage1 = self:GetSpecialValueFor("damage")
	local Damage2 = self:GetSpecialValueFor("damage2")
	local Damage3 = self:GetSpecialValueFor("damage3")

	--newKeys.PlaySound = true
	Damage1 = Damage1 + 2*caster:GetStrength()
	Damage2 = Damage2 + 1.5*caster:GetStrength()
	Damage3 = Damage3 + caster:GetStrength()

	if soundQueue <= 25 then		
		caster:EmitSound("Heracles_Combo_Easter_" .. math.random (2,3))
		Damage1 = Damage1 * 1
		Damage2 = Damage2 * 1
		Damage3 = Damage3 * 1
	end

	local casterloc = caster:GetAbsOrigin()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 999999
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local finaldmg = 0
	for k,v in pairs(targets) do
		local dist = (v:GetAbsOrigin() - casterloc):Length2D() 
		if dist <= 500 then
			finaldmg = Damage1
			--v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 3.0 })
		    --giveUnitDataDrivenModifier(caster, v, "stunned", 3.0)
		    if not IsImmuneToSlow(v) then 
				v:AddNewModifier(caster, self, "modifier_madmans_roar_slow_strong", {duration = 10})
			end
			giveUnitDataDrivenModifier(caster, v, "rb_sealdisabled", 3.0)
			giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("lock_duration_1"))
			v:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
		elseif dist > 500 and dist <= 1000 then
			finaldmg = Damage2
			if not IsImmuneToSlow(v) then 
				v:AddNewModifier(caster, self, "modifier_madmans_roar_slow_strong", {duration = 10})
			end
			giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("lock_duration_2"))
		elseif dist > 1000 and dist <= 3000 then
			finaldmg = Damage3
			if not IsImmuneToSlow(v) then 
				v:AddNewModifier(caster, self, "modifier_madmans_roar_slow_moderate", {duration = 10})
			end
			giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("lock_duration_3"))
		elseif dist > 3000 then
			finaldmg = 0
			if not IsImmuneToSlow(v) then 
				v:AddNewModifier(caster, self, "modifier_madmans_roar_slow_moderate", {duration = 10})
			end
		end

	    DoDamage(caster, v, finaldmg , DAMAGE_TYPE_MAGICAL, 0, self, false)
	end
	--ParticleManager:CreateParticle("particles/custom/screen_face_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	LoopOverPlayers(function(player, playerID, playerHero)
		if not (playerHero:GetTeamNumber() == caster:GetTeamNumber()) then
    		ParticleManager:CreateParticleForPlayer("particles/custom/screen_face_splash.vpcf", PATTACH_EYES_FOLLOW, caster, player)
    	end
    end)
	ScreenShake(caster:GetOrigin(), 30, 2.0, 5.0, 10000, 0, true)
end

modifier_madmans_roar_slow_moderate = class({})

function modifier_madmans_roar_slow_moderate:IsDebuff() return true end
function modifier_madmans_roar_slow_moderate:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_madmans_roar_slow_moderate:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("moderate_slow")
end

modifier_madmans_roar_slow_strong = class({})

function modifier_madmans_roar_slow_strong:IsDebuff() return true end
function modifier_madmans_roar_slow_strong:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_madmans_roar_slow_strong:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

modifier_madmans_roar_cooldown = class({})

function modifier_madmans_roar_cooldown:GetTexture()
	return "custom/berserker_5th_madmans_roar"
end

function modifier_madmans_roar_cooldown:IsHidden()
	return false 
end

function modifier_madmans_roar_cooldown:RemoveOnDeath()
	return false
end

function modifier_madmans_roar_cooldown:IsDebuff()
	return true 
end

function modifier_madmans_roar_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end