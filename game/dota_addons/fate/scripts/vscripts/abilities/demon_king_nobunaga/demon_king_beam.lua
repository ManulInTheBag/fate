
demon_king_beam = class({})


function demon_king_beam:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end
function demon_king_beam:CastFilterResultTarget(hTarget)
    local hCaster = self:GetCaster()

    if hTarget
        and hCaster and not hCaster:IsNull() then
        if (hTarget:GetTeamNumber() == hCaster:GetTeamNumber() and hTarget == hCaster) or hTarget:GetTeamNumber() ~= hCaster:GetTeamNumber() then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function demon_king_beam:GetCustomCastErrorTarget(hTarget)
    return "Cant cast on allies"
end


function demon_king_beam:OnSpellStart()
   local caster = self:GetCaster() 
   local target = self:GetCursorTarget()
   local hpPercentage = target:GetHealthPercent()
 
    if target == caster then
        self:CastGroundSlam()
    elseif hpPercentage > 30 then
        self.unitsTable = {}
        self.unitsDamageTable = {}
        self:CastHandBeam(target)
    else
        self:CastGunOrder(target)
    end

   
end

function demon_king_beam:GetCastAnimation()
    local caster = self:GetCaster() 
    local target = self:GetCursorTarget()
    local hpPercentage = target:GetHealthPercent()

    if target == caster then
        return ACT_DOTA_RAZE_2
    elseif hpPercentage > 30 then
        return ACT_DOTA_RAZE_3
    else
        return ACT_DOTA_CAST_EMP
    end    

end


function demon_king_beam:CastGroundSlam()
    local caster = self:GetCaster()
    local aoe_radius = self:GetSpecialValueFor("slam_aoe_radius")
    local damage = self:GetSpecialValueFor("slam_damage")
    local stun_dur = self:GetSpecialValueFor("slam_air_dur")

      local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
					DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				    ApplyAirborneOnly(v, 2000, stun_dur)
                    v:AddNewModifier(caster, v, "modifier_stunned", { Duration = stun_dur })
			end
		end
    caster:EmitSound("maou_slam")
    ScreenShake(caster:GetOrigin(), 15, 0.5, 0.5, 2000, 0, true)
    local particle = ParticleManager:CreateParticle("particles/maou/ground_slam/maou_ground_slam_.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin() + caster:GetForwardVector()* 100)

    Timers:CreateTimer(0.5, function()
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(particle)
    
    
    end)

end

function demon_king_beam:CastHandBeam(target)
    local caster = self:GetCaster()
    local casterpos = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("left_hand")) + caster:GetForwardVector()*25 
    local endpos = GetGroundPosition(target:GetAbsOrigin(), target) +Vector(0,0,100)
    self:ShootBeam(casterpos, endpos, 0)

end



function demon_king_beam:ShootBeam(startpos, endpos, bounces)
    if bounces >= 3 then return end
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("beam_damage")
    local search_radius = self:GetSpecialValueFor("beam_search_radius")
    local particle = ParticleManager:CreateParticle("particles/maou/hand_beam/maou_hand_beam_.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, startpos)
    ParticleManager:SetParticleControl(particle, 1, endpos)
    Timers:CreateTimer(0.5, function()
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(particle)
    
    
    end)
  

    local enemies = FindUnitsInLine(
													        caster:GetTeamNumber(),
													        startpos,
													        endpos,
													        nil,
													        self:GetSpecialValueFor("beam_width"),
															DOTA_UNIT_TARGET_TEAM_ENEMY,
															DOTA_UNIT_TARGET_ALL,
															0
					    								)

    for _, enemy in pairs(enemies) do
        if not self.unitsDamageTable[enemy:GetEntityIndex()] then
            DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            self.unitsTable[enemy:GetEntityIndex()] = true
            self.unitsDamageTable[enemy:GetEntityIndex()] = true

        end

        

        EmitSoundOn("maou_beam_sound", enemy)
    end

    local targets = FindUnitsInRadius(caster:GetTeam(), endpos, nil, search_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST , false)

    for k, v in pairs(targets) do 
        if  self.unitsTable[v:GetEntityIndex()] ~= true then
            self:ShootBeam(endpos, GetGroundPosition(v:GetAbsOrigin(), v) + Vector(0,0,100), bounces + 1)
            return
        end

    end
end


function demon_king_beam:CastGunOrder(target)
    local casterOrigin = self:GetCaster():GetAbsOrigin()
    local rightVector = self:GetCaster():GetRightVector()
    self:CreateGun(casterOrigin + rightVector * 150 + Vector(0,0, 150), target)
    self:CreateGun(casterOrigin + rightVector * -150 + Vector(0,0, 150), target)
    self:GetCaster():EmitSound("maou_shinei")
end

function demon_king_beam:CreateGun(position, target)
    local caster = self:GetCaster()
	local casterFw = caster:GetForwardVector()
	local Dummy = CreateUnitByName("dummy_unit", position, false, nil, nil, caster:GetTeamNumber())
	Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	Dummy:SetAbsOrigin(position)
    
    
    Dummy:SetForwardVector((casterFw ):Normalized())
    local GunFx
    GunFx = ParticleManager:CreateParticle( "particles/maou/maou_nobu_gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, Dummy )
    ParticleManager:SetParticleControl(GunFx, 3, position ) 
    ParticleManager:SetParticleControl(GunFx, 4, casterFw ) 
    Dummy.GunFx = GunFx
    Timers:CreateTimer(0.1, function()
        local targetPos = target:GetAbsOrigin()
        local vector = targetPos - position
        if vector:Length2D() > self:GetSpecialValueFor("gun_max_range") then
            vector = (targetPos - position):Normalized() * self:GetSpecialValueFor("gun_max_range")
            
        end
        local endPos = position + vector
        Dummy:SetForwardVector((vector):Normalized())
        Timers:CreateTimer(0.1, function()
            self:GunShootLaser(position + vector:Normalized() * 100, endPos + Vector(0,0, 150))

        end)
    end)

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(GunFx, true)
		ParticleManager:ReleaseParticleIndex(GunFx)
        Dummy:RemoveSelf()
	end)
   
end

function demon_king_beam:GunShootLaser(gunPos, targetPos)
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("guns_damage")
    local targets = FindUnitsInLine(  caster:GetTeamNumber(),
                                            gunPos,
                                            targetPos ,
                                            nil,
                                            self:GetSpecialValueFor("gun_laser_width"),
                                            DOTA_UNIT_TARGET_TEAM_ENEMY,
                                            DOTA_UNIT_TARGET_ALL,
                                            0
                                        )
    local fx = ParticleManager:CreateParticle("particles/maou/hand_beam/maou_hand_beam_.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 1,   targetPos)       
    ParticleManager:SetParticleControl(fx, 0,  gunPos)   
    Timers:CreateTimer(0.5, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    
    end)

    for _, enemy in pairs(targets) do
        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)    
        EmitSoundOn("maou_beam_sound", enemy)
    end

end