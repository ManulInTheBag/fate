nobu_shot = class({})

LinkLuaModifier("modifier_nobu_slow","abilities/nobu/nobu_shot", LUA_MODIFIER_MOTION_NONE)

function nobu_shot:GetBehavior()
    if  self:GetCaster():HasModifier("modifier_nobu_turnlock") then
        return DOTA_ABILITY_BEHAVIOR_POINT  + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    else
        return DOTA_ABILITY_BEHAVIOR_POINT
    end

end

 

function nobu_shot:OnSpellStart()
    local hCaster = self:GetCaster()
    local aoe = 50
    local origin = hCaster:GetAttachmentOrigin(3) 

    
    if  hCaster:FindModifierByName("modifier_nobu_turnlock") then

        local gun_spawn = hCaster:GetAbsOrigin()
        local random1 = RandomInt(25, 150) -- position of gun spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(80,200)*Vector(0,0,1) 
        

		if random2 == 0 then 
			gun_spawn = gun_spawn +  hCaster:GetRightVector() * -1 * random1 + random3
		else 
			gun_spawn = gun_spawn + hCaster:GetRightVector() * random1 + random3
        end
        local aoe = 50
        
        self:EShot({
            Speed = 10000,
            AoE = aoe,
            Range = 1000,
        },  gun_spawn )

    else
        local position = self:GetCursorPosition()
        local facing = ForwardVForPointGround(hCaster,position)
        hCaster:EmitSound("nobu_shoot_1")
        Timers:CreateTimer(0.1, function()
            self:Shoot({
                Origin = origin,
                Speed = 10000,
                Facing = facing,
                AoE = aoe*2,
                Range = 1000,
            } )
        
        
        
        end)


    end
   
    
   
end

function nobu_shot:Shoot(keys)
    local projectileTable = {
        EffectName = "particles/nobu/nobu_bullet_q.vpcf" ,
        Ability = self,
        vSpawnOrigin = keys.Origin,
        vVelocity = keys.Facing * keys.Speed,
        fDistance = keys.Range,
        fStartRadius = keys.AoE,
        fEndRadius = keys.AoE,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.1,
        
    }
    ProjectileManager:CreateLinearProjectile(projectileTable)
end

 
function nobu_shot:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * self:GetSpecialValueFor("damage_mod")
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
    end
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    target:AddNewModifier(hCaster, self, "modifier_nobu_slow", {Duration = self:GetSpecialValueFor("duration")})  
    if( hCaster:FindModifierByName("modifier_nobu_dash_dmg") ) then
        DoDamage(hCaster, target, hCaster:FindAbilityByName("nobu_dash"):GetSpecialValueFor("attr_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
    if( hCaster.NobuActionAcquired and not  hCaster:FindModifierByName("modifier_nobu_turnlock")) then
        local knockback = { should_stun = true,
        knockback_duration = 0.1,
        duration = 0.1,
        knockback_distance = 80,
        knockback_height = 0,
        center_x = hCaster:GetAbsOrigin().x,
        center_y = hCaster:GetAbsOrigin().y,
        center_z = hCaster:GetAbsOrigin().z }

        target:AddNewModifier(hCaster, self, "modifier_knockback", knockback)
        
    end
    if(hCaster.ISDOW) then
        local gun_spawn = hCaster:GetAbsOrigin()
        local random1 = RandomInt(25, 150) -- position of gun spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(80,200)*Vector(0,0,1) 
        

		if random2 == 0 then 
			gun_spawn = gun_spawn +  hCaster:GetRightVector() * -1 * random1 + random3
		else 
			gun_spawn = gun_spawn + hCaster:GetRightVector() * random1 + random3
        end
        local aoe = 50
        
        hCaster:FindAbilityByName("nobu_guns"):DOWShoot({
            Speed = 10000,
            AoE = aoe,
            Range = 1000,
        },  gun_spawn )
    end
    return false 
end



function nobu_shot:EShot(keys, position)
    
    self.caster = self:GetCaster()
    local vCasterOrigin = self.caster:GetAbsOrigin()
    vCasterOrigin.z = 0
    local targets = FindUnitsInRadius( self.caster:GetTeam(),  self.caster:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    self.target = nil
     if( targets[1] ~= nil) then
        self.target  = targets[1]:GetAbsOrigin()
        self.target_enemy = targets[1]
     end    

     
	self.Dummy = CreateUnitByName("dummy_unit", vCasterOrigin, false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)

    if(self.target == nil) then 
        self.target = self.caster:GetForwardVector()*1000 + self.caster:GetAbsOrigin()
        self.Dummy:SetForwardVector( self.caster:GetForwardVector())
    else
        self.Dummy:SetForwardVector((  self.target - position ):Normalized())
    end
 

    --self.Dummy:SetForwardVector(vCasterOrigin - self.Dummy:GetAbsOrigin())

	local GunFx = ParticleManager:CreateParticle( "particles/nobu/gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
  
	ParticleManager:SetParticleControl(GunFx, 3, position ) 
    ParticleManager:SetParticleControl(GunFx, 4,   self.target- vCasterOrigin  ) 
    self.Dummy.GunFx = GunFx
    local dummy = self.Dummy
 

	Timers:CreateTimer(0.4, function()
         
        dummy:SetForwardVector((    self.target_enemy:GetAbsOrigin() - position ):Normalized())
        local velocity = dummy:GetForwardVector()
        dummy:EmitSound("nobu_shoot_1")
        velocity.z = 0
	
        local projectileTable = {
            EffectName = "particles/nobu/nobu_bullet.vpcf" ,
            Ability = self,
            vSpawnOrigin = position + dummy:GetForwardVector()*80,
            vVelocity =velocity * keys.Speed,
            fDistance = keys.Range,
            fStartRadius = keys.AoE,
            fEndRadius = keys.AoE,
            Source = self:GetCaster(),
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            flExpireTime = GameRules:GetGameTime() + 0.33,
            
        }
        ProjectileManager:CreateLinearProjectile(projectileTable)
        ParticleManager:DestroyParticle(GunFx, false)
		ParticleManager:ReleaseParticleIndex(GunFx)
        dummy:RemoveSelf() 
	end)

    
 
end










modifier_nobu_slow = class({})

function modifier_nobu_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_nobu_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_nobu_slow:IsHidden()
	return false 
end