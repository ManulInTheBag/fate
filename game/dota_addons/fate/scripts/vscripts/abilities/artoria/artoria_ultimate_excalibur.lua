-----------------------------
--    Ultimate Excalibur    --
-----------------------------

artoria_ultimate_excalibur = class({})

LinkLuaModifier("modifier_artoria_ultimate_excalibur", "abilities/artoria/modifiers/modifier_artoria_ultimate_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_ultimate_excalibur_cooldown", "abilities/artoria/modifiers/modifier_artoria_ultimate_excalibur_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_maxcalibur_slow", "abilities/artoria/artoria_ultimate_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function artoria_ultimate_excalibur:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local facing = caster:GetForwardVector()

	self.TargetsTable = {}
	
	Timers:CreateTimer(0.01, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=5.0, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})
		end
	end)
	
	caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_excalibur_cooldown", { Duration = self:GetCooldown(1) })
	
	local masterCombo = caster.MasterUnit2:FindAbilityByName("artoria_ultimate_excalibur")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(-1))
	
	caster:FindAbilityByName("artoria_excalibur"):StartCooldown(35.0)

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.music == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Saber_Oath"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	Timers:CreateTimer({endTime=0.1,
		callback = function()
		--EmitGlobalSound("Saber_Max_Chant_" .. math.random(1,2))
		EmitGlobalSound("saber_maxex_chant"..math.random(1,2))
	end})

	Timers:CreateTimer({
		endTime = 2.5, 
		callback = function()
	    --EmitGlobalSound("Saber_Max_Excalibur")
	    EmitGlobalSound("saber_maxexcalibar")
	    EmitGlobalSound("saber_effect")
	end})
	
	--caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_excalibur", { Duration = 5.01 })
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 5.2)
	local range = self:GetSpecialValueFor("range") - self:GetSpecialValueFor("width") -- We need this to take end radius of projectile into account
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2)
	--StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})
	local excal = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = self:GetSpecialValueFor("speed"),
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = range,
        fStartRadius = self:GetSpecialValueFor("width"),
        fEndRadius = self:GetSpecialValueFor("width"),
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * self:GetSpecialValueFor("speed")
	}		
	
	-- Charge particles
	local excalibur_Charge = ParticleManager:CreateParticle("particles/custom/saber/max_excalibur/charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	local chargeFxIndex = ParticleManager:CreateParticle( "particles/custom/artoria/artoria_excalibur_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	
	Timers:CreateTimer(4.00, function()
		if not caster:IsAlive() then
			ParticleManager:DestroyParticle( chargeFxIndex, false )
			ParticleManager:ReleaseParticleIndex( chargeFxIndex )
			
			StopGlobalSound("artoria_ultimate_excalibur")
		end
	end)
	
		Timers:CreateTimer(3.50, function() -- Adjust 2.5 to 3.5 to match the sound
			if caster:IsAlive() then
				ScreenShake(caster:GetOrigin(), 7, 2.0, 2, 15000, 0, true)
				
				ParticleManager:DestroyParticle( chargeFxIndex, false )
				ParticleManager:ReleaseParticleIndex( chargeFxIndex )
				
				local YellowScreenFx = ParticleManager:CreateParticle("particles/custom/screen_yellow_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
				
				Timers:CreateTimer( 2.0, function()
					ParticleManager:DestroyParticle( YellowScreenFx, false )
					ParticleManager:ReleaseParticleIndex( YellowScreenFx )
				end)
				
				excalBeam = 0
				Timers:CreateTimer(function()
				if excalBeam == 10 then return end
					excal.vSpawnOrigin = caster:GetAbsOrigin() 
					excal.vVelocity = caster:GetForwardVector() * self:GetSpecialValueFor("speed")
					--local projectile = ProjectileManager:CreateLinearProjectile(excal)
					excalBeam = excalBeam + 1
					return 0.1
				end)
				
				local casterFacing = caster:GetForwardVector()
				return 
			end
		end)
		
	Timers:CreateTimer({
		endTime = 3.5, 
		callback = function()
			if caster:IsAlive() then
				nBeams = 0
				Timers:CreateTimer(function()
					if nBeams == 26 then 
						return
					end
				self:FireSingleMaxParticle()
				local projectile = ProjectileManager:CreateLinearProjectile(excal)
				nBeams = nBeams + 1
				return 0.04
				end)
			end
end})
end

function artoria_ultimate_excalibur:FireSingleMaxParticle()
	local caster = self:GetCaster()
	local casterFacing = caster:GetForwardVector()

		local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() + 300 * casterFacing, false, caster, caster, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		dummy:SetForwardVector(casterFacing)
		Timers:CreateTimer( function()
				if IsValidEntity(dummy) then
					local newLoc = dummy:GetAbsOrigin() + self:GetSpecialValueFor("speed") * 0.015 * casterFacing
					dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
					-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.Width, true, 0.15)
					return 0.015
				else
					return nil
				end
			end
		)
		
		local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/max_excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
		--local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			
		Timers:CreateTimer(0.57, function()
			ParticleManager:DestroyParticle( excalFxIndex, false )
			ParticleManager:ReleaseParticleIndex( excalFxIndex )
			Timers:CreateTimer( 0.1, function()
					dummy:RemoveSelf()
					return nil
				end
			)
			return nil
		end)
end

function artoria_ultimate_excalibur:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then return end
	
	if hTarget:IsMagicImmune() then
		return
	end

	local first = false

	if not self.TargetsTable[hTarget:entindex()] then
		self.TargetsTable[hTarget:entindex()] = true
		first = true
	end

	local caster = self:GetCaster()
	local target = hTarget
	local damage = self:GetSpecialValueFor("damage")
	if caster:HasModifier("modifier_artoria_improve_excalibur_attribute") then
		damage = damage + 5500
	end

	damage = damage/25

	if first then
		damage = self:GetSpecialValueFor("initial_damage")
	end

	local player = caster:GetPlayerOwner()

	target:AddNewModifier(caster, self, "modifier_maxcalibur_slow", {Duration = 0.5})
	giveUnitDataDrivenModifier(caster, target, "locked", 0.5)
	
	if target:GetUnitName() == "gille_gigantic_horror" then damage = damage * 1.5 end
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

modifier_maxcalibur_slow = class({})

function modifier_maxcalibur_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_maxcalibur_slow:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

function modifier_maxcalibur_slow:IsHidden()
	return true 
end