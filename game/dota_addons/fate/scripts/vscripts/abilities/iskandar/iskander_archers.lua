iskander_archers = class({})
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archers_soldier_script","abilities/iskandar/iskander_archers", LUA_MODIFIER_MOTION_NONE)


function iskander_archers:GetCastPoint()
	return self:GetCaster().IsRiding and 0 or 0.2
end

function iskander_archers:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("damage")

	local aotkAbility = caster:FindAbilityByName("iskander_ionioi")
    local targetPoint = self:GetCursorPosition()
    local forwardVec = caster:GetForwardVector()
	local spawn_center = caster:GetAbsOrigin() + forwardVec  * - 300
    caster.PhalanxSoldiers = {}

	local leftvec = Vector(-forwardVec.y, forwardVec.x, 0)
	local rightvec = Vector(forwardVec.y, -forwardVec.x, 0)
	local caster_vector = caster:GetForwardVector()
	-- Spawn soldiers from target point to left end
	--if not caster.IsAOTKActive then
		for i=0,2 do
			Timers:CreateTimer(i*0.1, function()
				local soldier = CreateUnitByName("iskander_archer",  spawn_center + leftvec * 100 * i, true, nil, nil, caster:GetTeamNumber())
				soldier:SetOwner(caster)
				soldier:SetForwardVector(caster_vector)
				soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
				soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
				soldier:AddNewModifier(caster, self, "modifier_archers_soldier_script", {pointx =targetPoint.x, pointy = targetPoint.y,  pointz = targetPoint.z  })
				soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
				if i==0 then
					local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
					ParticleManager:SetParticleControl(particle, 3, targetPoint)
					Timers:CreateTimer( 2.0, function()
						ParticleManager:DestroyParticle( particle, false )
						ParticleManager:ReleaseParticleIndex( particle )
					end)
				end 
				table.insert(caster.PhalanxSoldiers, soldier)
			end)
		end

		-- Spawn soldiers on right side
		for i=1,3 do
			Timers:CreateTimer(i*0.15, function()
				local soldier = CreateUnitByName("iskander_archer", spawn_center + rightvec * 100 * i, true, nil, nil, caster:GetTeamNumber())
				soldier:SetOwner(caster)
				soldier:SetForwardVector(caster_vector)
				soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
				soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
				soldier:AddNewModifier(caster, self, "modifier_archers_soldier_script", {pointx =targetPoint.x, pointy = targetPoint.y,  pointz = targetPoint.z  })
				soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
				table.insert(caster.PhalanxSoldiers, soldier)
			end)
		end

		local soundQueue = math.random(1, 4)

		caster:EmitSound("Iskander_Skill_" .. soundQueue)
	--end

    
end

function iskander_archers:ShootArrow(unit, point)
	local aoe = self:GetSpecialValueFor("aoe")
	local caster = self:GetCaster()
	local point = point + RandomVector(RandomInt(0, self:GetSpecialValueFor("distribution_radius")) )
	local point2 = unit:GetAbsOrigin()  +( point - unit:GetAbsOrigin())/2 
	local nSpeed = 3000	
	local unitPoint = unit:GetAttachmentOrigin(2)
	local point_particle = ParticleManager:CreateParticle("particles/emiya/emiya_change_aoe_marker.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(point_particle, 0,  point )
	ParticleManager:SetParticleControl(point_particle, 1,  Vector(aoe,0,0) )
	ParticleManager:SetParticleShouldCheckFoW(point_particle, false)
	local count = self:GetSpecialValueFor("shots_per_unit")
	local dmg = self:GetSpecialValueFor("damage")
	local sArrowParticle = "particles/iskander/sanya_arrows.vpcf" 

	local counter = 0 
	StartAnimation(unit, {duration = 0.25, activity=ACT_DOTA_CAST_ABILITY_1, rate=4})
	Timers:CreateTimer(0.25, function()
		if counter == count then return end  
		StartAnimation(unit, {duration = 0.25, activity=ACT_DOTA_CAST_ABILITY_1, rate=4})
		local nArrowParticle =  ParticleManager:CreateParticle(sArrowParticle, PATTACH_WORLDORIGIN, nil)
		unit:EmitSound("arrow_sanya")
		--ParticleManager:SetParticleShouldCheckFoW(nArrowParticle, false)
		ParticleManager:SetParticleAlwaysSimulate(nArrowParticle)
		ParticleManager:SetParticleControl(nArrowParticle, 0, unitPoint)
		ParticleManager:SetParticleControl(nArrowParticle, 1, GetGroundPosition(point2, nil))
		ParticleManager:SetParticleControl(nArrowParticle, 2, Vector(nSpeed, 0, 0))
		Timers:CreateTimer(0.55,function()
			ParticleManager:DestroyParticle(nArrowParticle, true)
			ParticleManager:ReleaseParticleIndex(nArrowParticle)
		end)
		counter = counter + 1
		return 0.25
	end)
	
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(point_particle, true)
		ParticleManager:ReleaseParticleIndex(point_particle)
		local iParticleIndex = ParticleManager:CreateParticle("particles/custom/iskandar/arrow_volley.vpcf", PATTACH_CUSTOMORIGIN, nil) 
		ParticleManager:SetParticleControl(iParticleIndex, 0, point)
		ParticleManager:SetParticleControl(iParticleIndex, 1, unitPoint + Vector(0, 0, 500))
		ParticleManager:SetParticleControl(iParticleIndex, 3, unitPoint + Vector(0, 0, 500))
		ParticleManager:SetParticleControl(iParticleIndex, 4, Vector(aoe, 1, 1))
		EmitSoundOnLocationWithCaster(point , "arrow_sanya_2", caster)
		Timers:CreateTimer(1,function()
			ParticleManager:DestroyParticle(iParticleIndex, true)
			ParticleManager:ReleaseParticleIndex(iParticleIndex)
		end)
		local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
						point,
                        nil,
                        aoe,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     	for _,enemy in pairs(enemies) do
			DoDamage(caster, enemy, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
			giveUnitDataDrivenModifier(caster, enemy, "rooted", self:GetSpecialValueFor("duration"))
       	end

	end)



end




modifier_archers_soldier_script = class({})

function modifier_archers_soldier_script:IsDebuff()
	return true
end

function modifier_archers_soldier_script:OnCreated(args)
	if(not IsServer()) then return end
	self.parent = self:GetParent() 
	local target = Vector(args.pointx, args.pointy, args.pointz)
	Timers:CreateTimer(0.2, function()
		self:GetAbility():ShootArrow(self.parent, target)
	end)
end

function modifier_archers_soldier_script:CheckState()
	local state = {
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_STUNNED] = true,
	}
 
	return state
end
