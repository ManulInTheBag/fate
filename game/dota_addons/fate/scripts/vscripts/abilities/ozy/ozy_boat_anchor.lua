LinkLuaModifier("modifier_ozy_anchor_aura_enemy", "abilities/ozy/ozy_boat_anchor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_anchor_enemy", "abilities/ozy/ozy_boat_anchor", LUA_MODIFIER_MOTION_NONE)
ozy_boat_anchor = class({})

function ozy_boat_anchor:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function ozy_boat_anchor:GetCustomCastErrorLocation(vLocation)
	 return "#Wrong_Target_Location"
end

function ozy_boat_anchor:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	if (vTargetPoint-hCaster:GetAbsOrigin()):Length2D() > 1300 then
		vTargetPoint = hCaster:GetAbsOrigin() + (vTargetPoint-hCaster:GetAbsOrigin()):Normalized() * 1300
	end
	local ozymandias = hCaster.ozy
	local boatOrigin = hCaster:GetAbsOrigin()
	local ozyOrigin = ozymandias:GetAbsOrigin()
	local ply = hCaster:GetPlayerOwner()
	local Anchor = CreateUnitByName("ozy_anchor", boatOrigin + Vector(0,0, 2500), true, nil, nil, hCaster:GetTeamNumber())
	local liveDuration = self:GetSpecialValueFor("live_duration")
	local targetPointGround  = GetGroundPosition(vTargetPoint, Anchor)  + Vector(0,0,-50)
	local vectorJopa= -(boatOrigin - vTargetPoint):Normalized()

	local beamAbil = hCaster:FindAbilityByName("ozy_boat_beam")
	if beamAbil:GetCooldownTimeRemaining() < 0.5 then
		beamAbil:StartCooldown(0.5)
	end
	local strikesAbil = hCaster:FindAbilityByName("ozy_boat_sunstrike")
	if strikesAbil:GetCooldownTimeRemaining() < 0.5 then
		strikesAbil:StartCooldown(0.5)
	end
	if( not self.JopaAnchor or self.JopaAnchor:IsNull()) then
            self.JopaAnchor = Anchor
    else
            self.JopaAnchor:RemoveSelf() 
            self.JopaAnchor = Anchor
			if IsNotNull(self.particle_ground_fx) then
				ParticleManager:DestroyParticle(self.particle_ground_fx, true)
				ParticleManager:ReleaseParticleIndex(self.particle_ground_fx)
			end
    end
	EmitSoundOnLocationWithCaster(vTargetPoint,"ozy_boat_anchor_cast", hCaster)
		self.particle_ground_fx = ParticleManager:CreateParticle("particles/ozy/boat/ozy_boat_anchor_indicator.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.particle_ground_fx, 0, vTargetPoint)
	ParticleManager:SetParticleControl(self.particle_ground_fx, 1, Vector(self:GetSpecialValueFor("hit_radius"), 0, 0))
	ParticleManager:SetParticleShouldCheckFoW(self.particle_ground_fx, false)

	Anchor:SetDayTimeVisionRange(300)
	Anchor:SetNightTimeVisionRange(300)
	ozymandias.Anchor = Anchor
	Anchor:AddNewModifier(hCaster, self, "modifier_kill", {duration = liveDuration})
    Timers:CreateTimer(liveDuration, function()
        if IsNotNull(Anchor) then
            Anchor:RemoveSelf()
        end
    end)
	local counter = 0
	local CounterMax = FrameTime()*7 / FrameTime()
	local heightDiff = (vTargetPoint + Vector(0,0, 2500)).z - targetPointGround.z
	local distanceDiff = (vTargetPoint - boatOrigin):Length2D()
	local VectorZCoeff  = 0

	if distanceDiff > 200 then
		
		VectorZCoeff = distanceDiff/self:GetSpecialValueFor("cast_range") * 0.4
	end
	local vectorJopa2 = -(boatOrigin - vTargetPoint)
	vectorJopa2.z = 0
	vectorJopa2  = vectorJopa2:Normalized()
	
	Anchor:SetForwardVector(( vectorJopa2+ Vector(0,0,VectorZCoeff)):Normalized())
	
	Timers:CreateTimer(0, function()
		if Anchor ~= self.JopaAnchor then return end
		if counter>= CounterMax then
			Anchor:AddNewModifier(hCaster.ozy, self, "modifier_ozy_anchor_aura_enemy", {duration = liveDuration})
			Anchor:SetAbsOrigin(targetPointGround)
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), targetPointGround, nil, self:GetSpecialValueFor("hit_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(tEnemies) do
				DoDamage(hCaster, v, self:GetSpecialValueFor("damage") + self:GetCaster().ozy:GetLevel()* self:GetSpecialValueFor("damage_per_level"), self:GetAbilityDamageType(), 0, self, false)
			end
			ParticleManager:DestroyParticle(self.particle_ground_fx, true)
			ParticleManager:ReleaseParticleIndex(self.particle_ground_fx)
			local particle_ground_fx_impact = ParticleManager:CreateParticle("particles/ozy/boat/ozy_boat_anchor_impact_jopa2.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(particle_ground_fx_impact, 0, vTargetPoint)
			ParticleManager:SetParticleShouldCheckFoW(particle_ground_fx_impact, false)
			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle(particle_ground_fx_impact, true)
				ParticleManager:ReleaseParticleIndex(particle_ground_fx_impact)
			end)
		else
			counter = counter + 1 
			Anchor:SetAbsOrigin(boatOrigin + Vector(0,0, 2500) + Vector(0,0, - heightDiff/CounterMax * counter) + vectorJopa * distanceDiff/CounterMax*counter )
			return FrameTime()
		end
		
	
	end)


 
end



-------------------------------------AURA FOR ENEMIES-----------------------------
modifier_ozy_anchor_aura_enemy = class({})

function modifier_ozy_anchor_aura_enemy:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY 
end

function modifier_ozy_anchor_aura_enemy:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_ozy_anchor_aura_enemy:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_ozy_anchor_aura_enemy:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_ozy_anchor_aura_enemy:GetModifierAura()
	return "modifier_ozy_anchor_enemy"
end

function modifier_ozy_anchor_aura_enemy:IsHidden()
	return true
end

function modifier_ozy_anchor_aura_enemy:RemoveOnDeath()
	return true
end

function modifier_ozy_anchor_aura_enemy:IsDebuff()
	return false 
end

function modifier_ozy_anchor_aura_enemy:IsAura()
	return true 
end

function modifier_ozy_anchor_aura_enemy:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_ozy_anchor_aura_enemy:CheckState()
    if IsServer() then
        local vLoc = GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()) + Vector(0,0,-50)
        self:GetParent():SetAbsOrigin(vLoc)
    end
end

modifier_ozy_anchor_enemy = class({})

 

function modifier_ozy_anchor_enemy:IsHidden() return false end
function modifier_ozy_anchor_enemy:IsDebuff() return true end
function modifier_ozy_anchor_enemy:RemoveOnDeath() return true end
function modifier_ozy_anchor_enemy:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
           }
end

 

function modifier_ozy_anchor_enemy:GetModifierMoveSpeedBonus_Percentage()
	return ((self:GetCaster():FindAbilityByName("ozy_spawn_boat"):GetLevel() > 1) and -1*self:GetAbility():GetSpecialValueFor("slow") or 0) 
end
