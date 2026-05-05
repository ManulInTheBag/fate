ozy_spawn_piramid = class({})
modifier_piramid_death_checker = class({})
modifier_piramid_alive = class({})

LinkLuaModifier("modifier_piramid_death_checker", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_piramid_alive", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pyramid_cast_slow", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_no_healthbar", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_stacking_vision_provider", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function ozy_spawn_piramid:IsHiddenAbilityCastable()
	return true
end

function ozy_spawn_piramid:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ozy_spawn_piramid:CastFilterResultLocation(vLocation)
	if self:GetCaster():HasModifier("modifier_piramid_alive") then
		return UF_FAIL_CUSTOM
	else	
		return UF_SUCCESS
	end
end

function ozy_spawn_piramid:GetCustomCastErrorLocation(vLocation)
	return "Cannot Summon"
end

function ozy_spawn_piramid:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local fDelay = self:GetSpecialValueFor("summon_delay")
	local pyramidHp = self:GetSpecialValueFor("max_health")
	local fAOE = self:GetAOERadius()
	local damage_first = self:GetSpecialValueFor("damage_first")

	if IsNotNull(hCaster.Piramid) then
		hCaster.Piramid:Kill(nil, hCaster)
		hCaster.Piramid = nil
	end
	--EmitGlobalSound("Gilles_Cool")
	hCaster:AddNewModifier(hCaster, self, "modifier_piramid_alive", { Duration = 3.0})

	AddFOWViewer(hCaster:GetTeamNumber(), vTargetPoint, fAOE, fDelay + 0.5, true)
    hCaster:EmitSound("Hero_Warlock.Upheaval")


	local particle_slow_fx = ParticleManager:CreateParticle("particles/ozy/piramid/ozymandias_piramid_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle_slow_fx, 0, vTargetPoint)
	ParticleManager:SetParticleControl(particle_slow_fx, 1, Vector(fAOE, 0, 0))
	local MaxCount = 10
	local tickTime = fDelay/MaxCount
	local count = 0
	damage_first = damage_first / MaxCount
	Timers:CreateTimer(0, function()
		if count >= MaxCount then
			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle_slow_fx, false)
				ParticleManager:ReleaseParticleIndex(particle_slow_fx)
			end)
			ScreenShake(vTargetPoint, 0.5*count, 0.5, tickTime, 100 * count, 0, true)
			return
		end
		count = count + 1
		local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTargetPoint, nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(tEnemies) do
			DoDamage(hCaster, v, damage_first, DAMAGE_TYPE_MAGICAL, 0, self, false)
			v:AddNewModifier(hCaster, self, "modifier_pyramid_cast_slow", {duration = 0.5})

		end

		return tickTime
	
	
	end)

	Timers:CreateTimer(fDelay - 0.5, function()
		if hCaster:IsAlive() then			
			-- Summon Gigantic Horror
			local Piramid = CreateUnitByName("ozy_piramid", vTargetPoint, false, hCaster, hCaster, hCaster:GetTeamNumber())
			Piramid:AddNewModifier(hCaster, self, "modifier_ozy_no_healthbar", {duration = 1})
			hCaster.Piramid = Piramid
			Piramid:AddNewModifier(hCaster, self, "modifier_phased", {duration = 0.5})
			Piramid:SetControllableByPlayer(hCaster:GetPlayerID(), true)
			Piramid:SetOwner(hCaster)
			Piramid.Ozy = hCaster
			
			--FindClearSpaceForUnit(Piramid, Piramid:GetAbsOrigin(), true)
			
			-- Level abilities
			
			Piramid:FindAbilityByName("ozy_piramid_cage"):SetLevel(self:GetLevel())
			Piramid:FindAbilityByName("ozy_piramid_barrier"):SetLevel(self:GetLevel())
			Piramid:FindAbilityByName("ozy_piramid_curse"):SetLevel(self:GetLevel())
			Piramid:FindAbilityByName("ozy_piramid_beam"):SetLevel(self:GetLevel())
			if hCaster.ozySa1Acquired then
				Piramid:FindAbilityByName("ozy_piramid_auto_defence"):SetLevel(self:GetLevel()) 
			end
			Piramid:FindAbilityByName("ozy_piramid_aura"):SetLevel(self:GetLevel())
			Piramid:SetHullRadius(0)
			Piramid:SetBaseMoveSpeed(0)
			Piramid:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE )
			Piramid:SetMaxHealth(pyramidHp)
			Piramid:SetBaseMaxHealth(pyramidHp)
			Piramid:SetHealth(pyramidHp)
			Piramid:SetDayTimeVisionRange(1000)
			Piramid:SetNightTimeVisionRange(1000)
			Timers:CreateTimer(90, function()
				if IsNotNull(Piramid) then
						Piramid:Kill(nil, hCaster)
				end
			end)
			Piramid:AddNewModifier(hCaster, self, "modifier_kill", { duration = 91.0 })
			Piramid:AddNewModifier(hCaster, self, "modifier_kb_immune", { duration = 91.0 })
			Piramid:AddNewModifier(hCaster, self, "modifier_piramid_death_checker", { Duration = 90 })

			--EmitGlobalSound("ZC.Ravage")

			Piramid:SetDeathXP(self:GetLevel() * 50 + 100)
		    local playerData = { transport = Piramid:entindex() }
            CustomGameEventManager:Send_ServerToPlayer( hCaster:GetPlayerOwner(), "player_summoned_transport", playerData )
			
			-- Damage enemies

			


				
			Timers:CreateTimer(0.5, function()
				Piramid:SetHullRadius(400)
				local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTargetPoint, nil, fAOE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				local EruptionParticle = ParticleManager:CreateParticle("particles/ozy/piramid/ozy/piramid/eruption.vpcf", PATTACH_CUSTOMORIGIN, Piramid)
				ParticleManager:SetParticleControl(EruptionParticle, 0, vTargetPoint)
				ParticleManager:SetParticleControl(EruptionParticle, 1, vTargetPoint)
				ParticleManager:SetParticleControl(EruptionParticle, 2, Vector(600, 0, 0))
				Timers:CreateTimer( 2.0, function()
					ParticleManager:DestroyParticle( EruptionParticle, false )
					ParticleManager:ReleaseParticleIndex( EruptionParticle )
				end)
				for k,v in pairs(tEnemies) do
					if v:GetUnitName() ~= "ozy_piramid" then
						local Distance = (v:GetAbsOrigin() - Piramid:GetAbsOrigin()):Length2D()
						local knockbackDistance = 0
						local knockbackHeight = 0
						if Distance< 450 then
							knockbackDistance = 450 - Distance
							knockbackHeight = knockbackDistance * 1.5
						end
						
						if v:GetTeamNumber() ~= hCaster:GetTeamNumber() then

							DoDamage(hCaster, v, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
							if not v:IsMagicImmune() then
								--ApplyAirborne(hCaster, v, 0.5)
								if( not IsKnockbackImmune(v)) then
									v:RemoveModifierByName("modifier_knockback")
	
									local knockback1 = { should_stun = true,
														knockback_duration = 0.5,
														duration = 0.5,
														knockback_distance = knockbackDistance ,
														knockback_height = knockbackHeight,
														center_x =vTargetPoint.x,
														center_y = vTargetPoint.y,
														center_z = vTargetPoint.z }
									v:AddNewModifier(hCaster, self, "modifier_knockback", knockback1)
								end
							end
						else
							if not v:IsMagicImmune() then
								--ApplyAirborne(hCaster, v, 0.5)
								if( not IsKnockbackImmune(v)) then
									v:RemoveModifierByName("modifier_knockback")
									local knockback2 = { should_stun = false,
														knockback_duration = 0.5,
														duration = 0.5,
														knockback_distance = knockbackDistance,
														knockback_height = knockbackHeight,
														center_x =vTargetPoint.x,
														center_y = vTargetPoint.y,
														center_z = vTargetPoint.z }
									v:AddNewModifier(hCaster, self, "modifier_knockback", knockback2)

	
								end
							end
						end
					end
				end

		
			end)

			Timers:CreateTimer(1, function()
				--Piramid:SetBaseMoveSpeed(100)
				--FindClearSpaceForUnit(Piramid, Piramid:GetAbsOrigin(), false)
			
			end)


			-- if hCaster:GetStrength() > 29.1 and hCaster:GetIntellect() > 29.1 and hCaster:GetAgility() > 29.1 then
			-- 	if hCaster:FindAbilityByName("gille_larret_de_mort"):IsCooldownReady() then
			-- 		hCaster:AddNewModifier(hCaster, self, "modifier_gilles_combo_window", { Duration = 4})
			-- 	end
			-- end

			EmitGlobalSound("ZC.Ravage")
			

		end

		StopSoundEvent("Hero_Warlock.Upheaval", hCaster)
	end)
end

function ozy_spawn_piramid:OnOwnerDied()
	local hCaster = self:GetCaster()
	if IsNotNull(hCaster.Piramid) and hCaster.Piramid:IsAlive() then
		hCaster.Piramid:Kill(nil, hCaster)
	end
end

function ozy_spawn_piramid:OnUpgrade()

end


if IsServer() then
	function modifier_piramid_death_checker:OnCreated()
		self:StartIntervalThink(0.1)
	end

	function modifier_piramid_death_checker:OnDestroy()		
		self:GetCaster():RemoveModifierByName("modifier_piramid_alive")

		local hAbility = self:GetCaster():FindAbilityByName("ozy_spawn_piramid")
		--hAbility:EndCooldown()
		--hAbility:StartCooldown(hAbility:GetCooldown(hAbility:GetLevel()))
	end

	function modifier_piramid_death_checker:OnIntervalThink()
	    local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 3000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
	    for k,v in pairs(targets) do
	        self:GetParent():AddNewModifier(v, nil, "modifier_vision_provider", {duration = 0.2})
	    end
		if self:GetCaster().ozySa1Acquired then
			local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
				v:AddNewModifier(v, nil, "modifier_ozy_stacking_vision_provider", {duration = 0.5})
			end
		end
	end
end

function modifier_piramid_death_checker:IsHidden()
	return true
end
function modifier_piramid_death_checker:CheckState()
	return {[MODIFIER_STATE_FORCED_FLYING_VISION ] = true}
end



function modifier_piramid_death_checker:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING,
			MODIFIER_PROPERTY_MOVESPEED_MAX_OVERRIDE,
			MODIFIER_PROPERTY_MOVESPEED_MIN_OVERRIDE,
			MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE    }
end

function modifier_piramid_death_checker:GetModifierIncomingDamage_Percentage(args) 
	if ((args.attacker:GetAbsOrigin()-self:GetParent():GetAbsOrigin()):Length2D()) < self:GetAbility():GetSpecialValueFor("damage_reduction_distance_min") then return 0 end
	return self:GetAbility():GetSpecialValueFor("damage_reduction_max") * math.min(0, -(   math.min(1, ((args.attacker:GetAbsOrigin()-self:GetParent():GetAbsOrigin()):Length2D())/self:GetAbility():GetSpecialValueFor("damage_reduction_distance_max"))))
end

function modifier_piramid_death_checker:GetModifierMoveSpeedOverride()
	return 0
end
function modifier_piramid_death_checker:GetModifierMoveSpeed_MinOverride()
	return 0
end
function modifier_piramid_death_checker:GetModifierMoveSpeed_MaxOverride()
	return 0
end
function modifier_piramid_death_checker:GetModifierDisableTurning()
	return 1
end
function modifier_piramid_death_checker:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_piramid_alive:IsHidden()
	return true
end

function modifier_piramid_alive:IsPermanent()
	return false
end

function modifier_piramid_alive:RemoveOnDeath()
	return true
end

function modifier_piramid_alive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_pyramid_cast_slow = class({})

function modifier_pyramid_cast_slow:IsDebuff() return true end
function modifier_pyramid_cast_slow:IsHidden() return false end
function modifier_pyramid_cast_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_pyramid_cast_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_first") 
end
function modifier_pyramid_cast_slow:OnRefresh()

end
function modifier_pyramid_cast_slow:OnCreated()
	local particle_slow_fx = ParticleManager:CreateParticle("particles/econ/items/zeus/zeus_immortal_2021/zeus_immortal_2021_shard_gold_slow_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(particle_slow_fx, 0, self:GetParent():GetAbsOrigin() + Vector(0, 0, 0))
	self:AddParticle(particle_slow_fx, false, false, -1, false, true)
end


modifier_ozy_no_healthbar = class({})

function modifier_ozy_no_healthbar:IsHidden() return true end
function modifier_ozy_no_healthbar:IsDebuff() return false end
function modifier_ozy_no_healthbar:RemoveOnDeath() return true end

function modifier_ozy_no_healthbar:CheckState()
	return {  [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = false,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_FORCED_FLYING_VISION ] = true}
end


modifier_ozy_stacking_vision_provider = class({})



function modifier_ozy_stacking_vision_provider:OnCreated(args)
    self:SetStackCount(0)
end

function modifier_ozy_stacking_vision_provider:OnRefresh(args)
	
    self:SetStackCount(self:GetStackCount() + 3)
	if self:GetStackCount() >= 100 then
		self:SetStackCount(100)
		self:GetParent():AddNewModifier(caster, self:GetAbility(), "modifier_vision_provider", {duration = 0.5})
		self.OverheadFx = ParticleManager:CreateParticle( "particles/zlodemon/zlodemon_overhead_eye.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( self.OverheadFx , 1, Vector( 1,1,0.1 ) )
		ParticleManager:SetParticleControl( self.OverheadFx , 2, Vector( 0.5,0,0 ) )
		ParticleManager:ReleaseParticleIndex(self.OverheadFx)
	end
end

function modifier_ozy_stacking_vision_provider:IsHidden()
    return false
end

function modifier_ozy_stacking_vision_provider:IsDebuff()
    return true
end


function modifier_ozy_stacking_vision_provider:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end