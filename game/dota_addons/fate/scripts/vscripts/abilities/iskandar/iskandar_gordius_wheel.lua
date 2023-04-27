iskandar_gordius_wheel = class({})

LinkLuaModifier("modifier_gordius_wheel", "abilities/iskandar/iskandar_gordius_wheel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gordius_wheel_thunder_slow", "abilities/iskandar/iskandar_gordius_wheel", LUA_MODIFIER_MOTION_NONE)
function iskandar_gordius_wheel:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_gordius_wheel") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function iskandar_gordius_wheel:GetCustomCastError()
	return "Already Riding"
end

function iskandar_gordius_wheel:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_gordius_wheel", {duration = self:GetSpecialValueFor("duration") + 1 })-- + 1 coz 1 second  
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "locked", self:GetSpecialValueFor("duration") + 1)
	caster:EmitSound("Hero_Magnataur.Skewer.Cast")
    	caster:EmitSound("Hero_Zuus.GodsWrath")
    	caster:EmitSound("Iskander_Wheel_" .. math.random(1,3))
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
		local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    	ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin())
    	local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    	ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
    	ParticleManager:SetParticleControl(particle3, 1, caster:GetAbsOrigin())
   	 	ParticleManager:SetParticleControl(particle3, 2, caster:GetAbsOrigin())
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			ParticleManager:DestroyParticle( particle2, false )
			ParticleManager:ReleaseParticleIndex( particle2 )
			ParticleManager:DestroyParticle( particle3, false )
			ParticleManager:ReleaseParticleIndex( particle3 )
		end)
	if caster.IsVEAcquired then
		if caster:FindAbilityByName("iskander_drift"):IsHidden() then
			caster:SwapAbilities(self:GetName(), "iskander_drift", false, true) 
			caster:FindAbilityByName("iskander_drift"):EndCooldown()
		end
		
	end
end


modifier_gordius_wheel = class({})



function modifier_gordius_wheel:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
			 MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
			 }
end

function modifier_gordius_wheel:GetModifierIgnoreMovespeedLimit()
	return 1
end


function modifier_gordius_wheel:GetModifierTurnRate_Percentage()
	return -350
end

function modifier_gordius_wheel:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
        return self.Movespeed
    elseif IsClient() then
        local movespeed = CustomNetTables:GetTableValue("sync","gordius_wheel").movespeed
        return movespeed 
    end
end


function modifier_gordius_wheel:GetModifierMagicalResistanceBonus()
	if IsServer() then        
        return self.mr
    elseif IsClient() then
        local mr = CustomNetTables:GetTableValue("sync","gordius_wheel").mres
        return mr 
    end
end

 

function modifier_gordius_wheel:GetModifierPhysicalArmorBonus()
	if IsServer() then        
        return self.armor
    elseif IsClient() then
        local armor = CustomNetTables:GetTableValue("sync","gordius_wheel").armor
        return armor 
    end
end

function modifier_gordius_wheel:CheckState()
    local state = { [MODIFIER_STATE_UNSLOWABLE ] = true,
                }
    return state
end



function modifier_gordius_wheel:OnCreated(args)
	local ability = self:GetAbility()
	local caster = self:GetParent()

	self.Movespeed = ability:GetSpecialValueFor("base_movespeed")
	self.mr = 30				--ability:GetSpecialValueFor("bonus_mr") IT WILL BREAK IF YOU Change to LINK IDK WHY
	self.armor = 10			--ability:GetSpecialValueFor("bonus_armor")
	if(IsServer() ) then
		CustomNetTables:SetTableValue("sync","gordius_wheel", {movespeed = self.Movespeed, mres = self.mr, armor = self.armor})
	end
	caster.OriginalModel = "models/sanya/sanya.vmdl"
	caster.IsRiding = true
	local counter = 0
	caster.BonusChargeDamage = 0
	local duration = ability:GetSpecialValueFor("duration")
	local max_damage = ability:GetSpecialValueFor("max_damage")
	local min_damage = ability:GetSpecialValueFor("min_damage")
	local radius = ability:GetSpecialValueFor("radius")
	local damageDiff = max_damage - min_damage
	local damage
	if(IsServer()) then
		caster:SetModel("models/sanya/sanya_telega.vmdl")
		caster:SetOriginalModel("models/sanya/sanya_telega.vmdl")
		caster:SetModelScale(0.6)
	

	Timers:CreateTimer(1.0, function() 
		if caster.IsRiding and counter < 10 then 
			self.Movespeed = self.Movespeed + ability:GetSpecialValueFor("movespeed_per_second")
			if(IsServer() ) then
				CustomNetTables:SetTableValue("sync","gordius_wheel", {movespeed = self.Movespeed, mres = self.mr, armor = self.armor})
			end
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		 	for k,v in pairs(targets) do
				local distDiff = 250 -- max damage at 100, min damage at 350
			 	local distance = (caster:GetAbsOrigin() - v:GetAbsOrigin()):Length2D() 
			 	if distance <= 100 then 
					damage = max_damage
			 	elseif distance > 100 then
					damage = max_damage - damageDiff * distance/radius
			 	end
			 	DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				if(v:IsHero()) then
					caster.BonusChargeDamage =  caster.BonusChargeDamage + 75
				end
		 	end
		 	

		 	if caster.IsThundergodAcquired then
			 	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			 	for k,v in pairs(targets) do
					DoDamage(caster, v, 150, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			 	end	  
			 	local thunderTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			 	local thunderTarget = thunderTargets[math.random(#thunderTargets)]
			 	if thunderTarget ~= nil then		        	
					DoDamage(caster, thunderTarget, thunderTarget:GetHealth() * 0.12, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				 	--thunderTarget:AddNewModifier(caster, thunderTarget, "modifier_stunned", {Duration = 0.1})
		 
				 	if not IsImmuneToSlow(thunderTarget) then 
						thunderTarget:AddNewModifier(caster, ability, "modifier_gordius_wheel_thunder_slow", { duration = ability:GetSpecialValueFor("sa_slow_duration") })
				 	end

					thunderTarget:EmitSound("Hero_Zuus.LightningBolt")
				 	local thunderFx = ParticleManager:CreateParticle("particles/units/heroes/hero_razor/razor_storm_lightning_strike.vpcf", PATTACH_CUSTOMORIGIN, thunderTarget)
				 	ParticleManager:SetParticleControl(thunderFx, 0, thunderTarget:GetAbsOrigin())
				 	ParticleManager:SetParticleControl(thunderFx, 1, caster:GetAbsOrigin()+Vector(0,0,800))
				 	Timers:CreateTimer( 2.0, function()
					 	ParticleManager:DestroyParticle( thunderFx, false )
					 	ParticleManager:ReleaseParticleIndex( thunderFx )
				 	end)
			 	end
		 	end
		 	local groundcrack = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		 	caster:EmitSound("Hero_Centaur.HoofStomp")
		 	counter = counter+1
		 	return 1.0
	 	else
		 	return
	 	end
 	end)
	end	   

end

function modifier_gordius_wheel:OnDestroy()
	local caster = self:GetParent()
	caster.OriginalModel = "models/sanya/sanya.vmdl"
	caster.IsRiding = false
	if(IsServer()) then
		caster:SetModel("models/sanya/sanya.vmdl")
		caster:SetOriginalModel("models/sanya/sanya.vmdl")
		caster:SetModelScale(1)
		if caster:GetAbilityByIndex(5):GetName() == "iskander_drift" then
			caster:SwapAbilities("iskander_drift", "iskandar_gordius_wheel", false, true) 
		end
	end
end
 



modifier_gordius_wheel_thunder_slow = class({})

function modifier_gordius_wheel_thunder_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_gordius_wheel_thunder_slow:GetModifierMoveSpeedBonus_Percentage()
	return -99
end

function modifier_gordius_wheel_thunder_slow:IsHidden()
	return true 
end
