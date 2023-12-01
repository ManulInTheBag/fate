iskander_cavalry = class({})
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phalanx_soldier_wall","abilities/iskandar/iskander_phalanx", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_iskandar_cavalry_rush","abilities/iskandar/iskander_cavalry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskandar_cavalry_rush_hitmarker","abilities/iskandar/iskander_cavalry", LUA_MODIFIER_MOTION_NONE)
function iskander_cavalry:GetCastPoint()
	return self:GetCaster().IsRiding and 0 or 0.3
end



function iskander_cavalry:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("damage")
	if caster.IsBeyondTimeAcquired == true then
		duration = duration + 3
	end
	
	--if caster.AOTKSoldierCount == nil then caster.AOTKSoldierCount = 0 end --initialize soldier count if its not made yet
	local aotkAbility = caster:FindAbilityByName("iskander_ionioi")
    local targetPoint = self:GetCursorPosition()
    local forwardVec = caster:GetForwardVector()

	local leftvec = Vector(-forwardVec.y, forwardVec.x, 0)
	local rightvec = Vector(forwardVec.y, -forwardVec.x, 0)
	local caster_vector = caster:GetForwardVector()
	-- Spawn soldiers from target point to left end
	for i=0,3 do
		Timers:CreateTimer(i*0.05, function()
			local soldier = CreateUnitByName("iskander_cavalry", targetPoint + leftvec * 100 * i, true, nil, nil, caster:GetTeamNumber())
			soldier:SetOwner(caster)
			soldier:SetForwardVector(-caster_vector)
			soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
			soldier:AddNewModifier(caster,self, "modifier_iskandar_cavalry_rush", {duration = 0.5,speed = 1500 + 100*i})
			self:CreateCavalryProjectile(soldier)
			if not caster.IsAOTKActive then
				soldier:AddNewModifier(caster, self, "modifier_phalanx_soldier_wall", {duration = duration})
			end
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
			soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
			local particle = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots_dust.vpcf", PATTACH_ABSORIGIN, soldier)
			ParticleManager:SetParticleControl(particle, 0, soldier:GetAbsOrigin())
			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
			if i==0 then
				local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
				ParticleManager:SetParticleControl(particle, 3, targetPoint)
				Timers:CreateTimer( 2.0, function()
					ParticleManager:DestroyParticle( particle, false )
					ParticleManager:ReleaseParticleIndex( particle )
				end)
			end 
		end)
	end

	-- Spawn soldiers on right side
	for i=1,3 do
		Timers:CreateTimer(i*0.05, function()
			local soldier = CreateUnitByName("iskander_cavalry", targetPoint + rightvec * 100 * i, true, nil, nil, caster:GetTeamNumber())
			soldier:SetOwner(caster)
			soldier:SetForwardVector(-caster_vector)
			soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
			soldier:AddNewModifier(caster,self, "modifier_iskandar_cavalry_rush", {duration = 0.5, speed = 1500 + 100*i})
			--caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
			if not caster.IsAOTKActive then
				soldier:AddNewModifier(caster, self, "modifier_phalanx_soldier_wall", {duration = duration})
			end
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
			local particle = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots_dust.vpcf", PATTACH_ABSORIGIN, soldier)
			ParticleManager:SetParticleControl(particle, 0, soldier:GetAbsOrigin())
			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
			--local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
			--ParticleManager:SetParticleControl(particle, 3, soldier:GetAbsOrigin())
			soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
		end)
	end
	
	local soundQueue = math.random(1, 4)

	caster:EmitSound("Iskander_Skill_" .. soundQueue)


end
 

function iskander_cavalry:Charge(aoe, vector)
	local caster = self:GetCaster()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, aoe
        , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	local soundQueue = math.random(1,4)
	if soundQueue == 3 then soundQueue = 5 end -- i was lazy, but needed to remove 3rd sound. 
	for k,v in pairs(targets) do
		if(v:GetUnitName() == "iskander_cavalry") then
			v:SetForwardVector(vector)
			v:AddNewModifier(caster,self, "modifier_iskandar_cavalry_rush", {duration = 0.5, speed = 1800})
			StartAnimation(v, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
			self:CreateCavalryProjectile(v)
			local particle = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots_dust.vpcf", PATTACH_ABSORIGIN, v)
			ParticleManager:SetParticleControl(particle, 0, v:GetAbsOrigin())
			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end
    end

end

function iskander_cavalry:CreateCavalryProjectile(unit)
	local ability = self
	local caster = self:GetCaster()
	local qdProjectile = 
	{
		Ability = ability,
        --EffectName = "particles/muramasa/muramasa_throw_projectile.vpcf",
        iMoveSpeed = 1850,
        vSpawnOrigin = unit:GetOrigin(),
        fDistance = 925,
        fStartRadius = 250,
        fEndRadius = 250,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = unit:GetForwardVector() * 1850
	}
	unit.projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

end

function iskander_cavalry:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	if not hTarget:HasModifier("modifier_iskandar_cavalry_rush_hitmarker") then
		giveUnitDataDrivenModifier(caster, hTarget, "stunned", self:GetSpecialValueFor("stun_duration"))
		hTarget:AddNewModifier(caster,self, "modifier_iskandar_cavalry_rush_hitmarker", {duration = 0.5})
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	
end

modifier_iskandar_cavalry_rush_hitmarker = class({})

function modifier_iskandar_cavalry_rush_hitmarker:IsHidden()
	return true
end
function modifier_iskandar_cavalry_rush_hitmarker:IsDebuff()
	return false
end

modifier_iskandar_cavalry_rush = class({})

function modifier_iskandar_cavalry_rush:OnCreated(args)
	self.ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not IsServer() then return end
	local speed = args.speed
	
	local sin = Physics:Unit(parent)
	parent:SetPhysicsFriction(0)
	parent:SetPhysicsVelocity(parent:GetForwardVector() * speed)
	parent:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer(0.5, function()
		parent:OnPreBounce(nil)
		parent:SetBounceMultiplier(0)
		parent:PreventDI(false)
		parent:SetPhysicsVelocity(Vector(0,0,0))
		parent:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
	return end
	)

	parent:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		ProjectileManager:DestroyLinearProjectile(parent.projectile)
		parent:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end



function modifier_iskandar_cavalry_rush:IsHidden()
	return true
end
function modifier_iskandar_cavalry_rush:IsDebuff()
	return false
end
 
 