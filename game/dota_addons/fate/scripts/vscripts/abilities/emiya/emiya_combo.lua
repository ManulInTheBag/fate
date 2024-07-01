emiya_combo = class({})
LinkLuaModifier("modifier_ubw_chronosphere", "abilities/emiya/emiya_unlimited_bladeworks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arrow_rain_cooldown", "abilities/emiya/modifiers/modifier_arrow_rain_cooldown", LUA_MODIFIER_MOTION_NONE)
local ubwCenter = Vector(5926, -4837, 222)

function emiya_combo:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local enemy = self:GetCursorTarget()
	local distance = (caster:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
	local ubw_ability = caster:FindAbilityByName("emiya_unlimited_bladeworks")
	EmitGlobalSound("emiya_ubw7")

	----Dash to enemy
    local knockback1 = { should_stun = true,
		knockback_duration = 0.5,
		duration = 0.5,
		knockback_distance = -distance,
		knockback_height = 0,
		center_x = enemy:GetAbsOrigin().x,
		center_y = enemy:GetAbsOrigin().y,
		center_z = enemy:GetAbsOrigin().z }

	caster:RemoveModifierByName("modifier_knockback")
	caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_LIFESTEALER_RAGE, rate= 1})
	local casterFX = ParticleManager:CreateParticle("particles/emiya/caladbolg_init.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(casterFX, 1, caster, PATTACH_ABSORIGIN, nil, caster:GetOrigin(), false)
    ParticleManager:ReleaseParticleIndex(casterFX)
	----

	caster:AddNewModifier(caster, ability, "modifier_arrow_rain_cooldown", {duration = self:GetCooldown(1)})
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))
	enemy:AddNewModifier(caster, self, "modifier_ubw_chronosphere", { Duration = 2 })


	Timers:CreateTimer(0.5,function()
		ubw_ability:StartUBW(false)

	
	end)

	Timers:CreateTimer(2.0, function()

		caster:EmitSound("Archer.Combo") 
		EmitSoundOnLocationWithCaster(ubwCenter, "emiya_combo_music", caster)
		local centerpos = caster:GetAbsOrigin() + caster:GetForwardVector()*700
		local enemypos = enemy:GetAbsOrigin()
		
		giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.7)
		local knockback2 = { should_stun = true,
			knockback_duration = 0.2,
			duration = 0.5,
			knockback_distance = -700,
			knockback_height = 0,
			center_x =centerpos.x,
			center_y = centerpos.y,
			center_z = centerpos.z }

		caster:RemoveModifierByName("modifier_knockback")
		caster:AddNewModifier(caster, self, "modifier_knockback", knockback2)	
		
		StartAnimation(caster, {duration=0.2, activity=ACT_ALIEN_BURROW_OUT, rate=2})
	
	end)
	Timers:CreateTimer(2.3, function()
		if caster:IsAlive() then 
			caster:MoveToTargetToAttack(enemy)
			local enemypos = enemy:GetAbsOrigin()
			if  IsInSameRealm(caster:GetAbsOrigin(), enemypos) then
				StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL_START, rate=1})
				self:SwordRain(enemypos)
				self:SwordRain(enemypos)
				local explosionFx = ParticleManager:CreateParticle( "particles/emiya/emiya_combo_swords_drop.vpcf", PATTACH_CUSTOMORIGIN, nil )
				ParticleManager:SetParticleControl( explosionFx, 3, enemypos )
				ParticleManager:SetParticleControl( explosionFx, 0, enemypos )
				ParticleManager:SetParticleControl( explosionFx, 5, Vector(800,0,0) )
				local first_damage = self:GetSpecialValueFor("first_damage")
				local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
								enemypos,
								nil,
								700,
								DOTA_UNIT_TARGET_TEAM_ENEMY,
								DOTA_UNIT_TARGET_ALL,
								DOTA_UNIT_TARGET_FLAG_NONE,
								FIND_ANY_ORDER,
								false)
				for _,enemy in pairs(enemies) do
					DoDamage(caster, enemy, first_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					giveUnitDataDrivenModifier(caster, enemy, "stunned", 2)
				end
			end
		end
	end)
	Timers:CreateTimer(4.5, function()
		if caster:IsAlive() then 
			caster:EmitSound("emiya_big_swords_spawn_combo")
		end
	end)
	Timers:CreateTimer(5.3, function()
		if caster:IsAlive() then 
			local enemypos = enemy:GetAbsOrigin()
			if  IsInSameRealm(caster:GetAbsOrigin(), enemypos) then
				local explosion_damage = self:GetSpecialValueFor("explosion_damage")
				caster:EmitSound("explosion_emiya")
				
				
				local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
								enemypos,
								nil,
								900,
								DOTA_UNIT_TARGET_TEAM_ENEMY,
								DOTA_UNIT_TARGET_ALL,
								DOTA_UNIT_TARGET_FLAG_NONE,
								FIND_ANY_ORDER,
								false)
				for _,enemy in pairs(enemies) do
					DoDamage(caster, enemy, explosion_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					giveUnitDataDrivenModifier(caster, enemy, "stunned", 0.1)
				end
			end
		end
	end)
 

end

function emiya_combo:SwordRain(enemypos)
	local caster = self:GetCaster()
	local radius = 700
	local targetPoint = enemypos
	local duration = 0
	local forwardVec = ( targetPoint - caster:GetAbsOrigin() ):Normalized()
	local damage = self:GetSpecialValueFor("rain_damage")
	Timers:CreateTimer(function()
		if caster:IsAlive() then
			if duration >= 6 then return
			else
				duration = duration + 0.055
				local swordVector = Vector(RandomFloat(-radius, radius), RandomFloat(-radius, radius), 0)
			
				-- Create sword particles
				-- Main variables
				local delay = 0.5				-- Delay before damage
				local speed = 3000				-- Movespeed of the sword
				
				-- Side variables
				local distance = delay * speed
				local height = distance * math.tan( 30 / 180 * math.pi )
				local spawn_location = ( targetPoint + swordVector ) - ( distance * RandomVector(1) )
				spawn_location = spawn_location + Vector( 0, 0, height )
				local target_location = targetPoint + swordVector
				local newForwardVec = ( target_location - spawn_location ):Normalized()
				target_location = target_location + 100 * newForwardVec
				
				local swordFxIndex = ParticleManager:CreateParticle( "particles/emiya/emiya_rain_sword.vpcf", PATTACH_CUSTOMORIGIN, caster )
				ParticleManager:SetParticleControl( swordFxIndex, 0, spawn_location )
				ParticleManager:SetParticleControl( swordFxIndex, 1, newForwardVec * speed )
				
				-- Delay
				Timers:CreateTimer(delay, function()
					-- Destroy particles
					ParticleManager:DestroyParticle( swordFxIndex, false )
					ParticleManager:ReleaseParticleIndex( swordFxIndex )
					
					-- Delay damage
					local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint + swordVector, nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
					for k,v in pairs(targets) do
						--[[if v:HasModifier("modifier_sword_barrage_confine") then
							DoDamage(caster, v, damage * 1.4, DAMAGE_TYPE_PHYSICAL, 0, self, false)
						else]]
							DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
						--end
					end
					
					-- Particles on impact
					local explosionFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( explosionFxIndex, 0, targetPoint + swordVector )
					
					local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint + swordVector )
					ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(300, 300, 300))
					
					-- Destroy Particle
					Timers:CreateTimer( 0.5, function()
						ParticleManager:DestroyParticle( explosionFxIndex, false )
						ParticleManager:DestroyParticle( impactFxIndex, false )
						ParticleManager:ReleaseParticleIndex( explosionFxIndex )
						ParticleManager:ReleaseParticleIndex( impactFxIndex )
					end)
					
					return nil
				end)

				return 0.055
			end
		end 
	end)


end

 