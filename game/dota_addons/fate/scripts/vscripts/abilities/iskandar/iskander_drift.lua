iskander_drift = class({})

LinkLuaModifier("modifier_iskandar_infantry_rush", "abilities/iskandar/iskander_forward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskandar_forward", "abilities/iskandar/iskander_forward", LUA_MODIFIER_MOTION_NONE)

function iskander_drift:OnSpellStart()
	local caster = self:GetCaster()
	local soundQueue = math.random(1,3)
	if(IsServer()) then
		caster:SetModel("models/sanya/sanya_telega.vmdl")
		caster:SetOriginalModel("models/sanya/sanya_telega.vmdl")
		caster:SetModelScale(0.6)
	end

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.5)
	local currentMS = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), false)
	if currentMS > 1200 then
		EmitGlobalSound("Iskander.Charge")
	else
		EmitGlobalSound("Iskander_Cart_Charge_" .. soundQueue)
	end
	local unit = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	local dashtime = 1
	local speed =   self:GetSpecialValueFor("range") * (0.5 + (currentMS/1500))
	caster:SetPhysicsVelocity(caster:GetForwardVector() * speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	local damage = self:GetSpecialValueFor("damage")
	local base_damage = self:GetSpecialValueFor("base_dmg")
	Timers:CreateTimer("chariot_dash_damage", {
		endTime = 0.0,
		callback = function()

		self:CreateLightningField(caster:GetAbsOrigin())
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        local bonus_charge_damage = caster.BonusChargeDamage or 0
		if(IsServer()) then
			caster:SetModel("models/sanya/sanya_telega.vmdl")
			caster:SetOriginalModel("models/sanya/sanya_telega.vmdl")
			caster:SetModelScale(0.6)
		end
        for k,v in pairs(targets) do
			if v.ChariotChargeHit ~= true then 
				v.ChariotChargeHit = true
				Timers:CreateTimer(1.0, function()
					v.ChariotChargeHit = false
				end)

           		DoDamage(caster, v, (base_damage + damage *currentMS/100) + bonus_charge_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
           		v:AddNewModifier(caster, v, "modifier_stunned", {duration = 0.75})
           		v:EmitSound("Iskandar_Chariot_hit")
           	end
        end
		return 0.1
	end})

	Timers:CreateTimer("chariot_dash", {
		endTime =dashtime,
		callback = function()
		Timers:RemoveTimer("chariot_dash_damage")
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("modifier_gordius_wheel")
		caster.IsRiding = false
		caster:RemoveModifierByName("pause_sealenabled")
		caster:RemoveModifierByName("locked")
		giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.75)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		if(IsServer()) then
			caster:SetModel("models/sanya/sanya.vmdl")
			caster:SetOriginalModel("models/sanya/sanya.vmdl")
			caster:SetModelScale(0.8)
		end
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("chariot_dash")
		Timers:RemoveTimer("chariot_dash_damage")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("modifier_gordius_wheel")
		caster.IsRiding = false
		caster:RemoveModifierByName("pause_sealenabled")
		caster:RemoveModifierByName("locked")
		giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.75)
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		if(IsServer()) then
			caster:SetModel("models/sanya/sanya.vmdl")
			caster:SetOriginalModel("models/sanya/sanya.vmdl")
			caster:SetModelScale(0.8)
		end
	end)
end
	
function iskander_drift:CreateLightningField(vector)
	local caster = self:GetCaster()
    local fieldCounter = 0
 	local plusminus = 1
    local currentMS = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), false)
    local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	local duration = self:GetSpecialValueFor("trail_duration") 
	local damage = self:GetSpecialValueFor("trail_damage")
	Timers:CreateTimer( 4.0, function()
		ParticleManager:DestroyParticle( particle3, false )
		ParticleManager:ReleaseParticleIndex( particle3 )
	end)
    Timers:CreateTimer(function()	
    	if fieldCounter >= duration then return end

		local targets = FindUnitsInRadius(caster:GetTeam(), vector, nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
			if v.ChariotTrailHit ~= true then 
				v.ChariotTrailHit = true
				Timers:CreateTimer(0.49, function()
					v.ChariotTrailHit = false
				end)

           		DoDamage(caster, v,damage * currentMS * 0.5 / 100 , DAMAGE_TYPE_MAGICAL, 0, self, false)
           	end
        end
        local randomVec = RandomInt(-400,400)
        
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field_c.vpcf", PATTACH_CUSTOMORIGIN, caster)
        local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field_c.vpcf", PATTACH_CUSTOMORIGIN, caster)
    	ParticleManager:SetParticleControl(particle3, 1, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle3, 2, caster:GetAbsOrigin())
    	ParticleManager:SetParticleControl( particle, 0, vector + Vector(randomVec, 0, 250))
    	ParticleManager:SetParticleControl( particle2, 0, vector + Vector(randomVec, 0, 100))
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			ParticleManager:DestroyParticle( particle2, false )
			ParticleManager:ReleaseParticleIndex( particle2 )
		end)
    	fieldCounter = fieldCounter + 0.5
    	return 0.5
    end)
        
end