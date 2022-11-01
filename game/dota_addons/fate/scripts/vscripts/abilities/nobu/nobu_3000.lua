nobu_3000 = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)



 


function nobu_3000:OnSpellStart()
	self.ChannelTime = 0
    self.caster = self:GetCaster()
    self.particle_kappa = ParticleManager:CreateParticle("particles/nobu/3000-charge.vpcf", PATTACH_ABSORIGIN_FOLLOW,  self.caster)
    self.dummies = {}
    self.rightvec = self.caster:GetRightVector()
    self.leftvec = -1*self.caster:GetRightVector()
    self.target = self:GetCursorPosition()
    self.caster:EmitSound("nobu_ulti_cast")
 
    if    self.caster :HasModifier("modifier_nobu_turnlock") then
        Timers:RemoveTimer("nobu_shoots")
        self.caster :RemoveModifierByName("modifier_nobu_turnlock")
        self.caster:StopAnimation()
        --StartAnimation(  self.caster, {duration= 1 , activity=ACT_DOTA_CAST_ABILITY_4, rate= 1})
    end
    for i=1,5 do 
        local gun_spawn = self.caster:GetAbsOrigin() + self.caster:GetForwardVector() *RandomInt(-200,200)
        local random1 = RandomInt(0, 300) -- position of gun spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(25,200)*Vector(0,0,1) 
		 

		if random2 == 0 then 
			gun_spawn = gun_spawn + self.leftvec * random1 + random3
		else 
			gun_spawn = gun_spawn + self.rightvec * random1 + random3
        end
		self:CreateGun(gun_spawn) 
    end
end

function nobu_3000:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if IsServer() and  caster:FindModifierByName("modifier_nobu_turnlock") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function nobu_3000:GetCustomCastErrorLocation(vLocation)
    return "Can not be used while shooting"
end

 
function nobu_3000:OnChannelThink(fInterval)
    self.ChannelTime = self.ChannelTime + fInterval
    if(self.ChannelTime >= 0.03) then
 
        local gun_spawn = self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*RandomInt(-200,200)
        local random1 = RandomInt(0, 300) -- position of gun spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(25,200)*Vector(0,0,1) --  
		

		if random2 == 0 then 
			gun_spawn = gun_spawn + self.leftvec * random1 + random3
		else 
			gun_spawn = gun_spawn + self.rightvec * random1 + random3
        end
        self:CreateGun(gun_spawn)
        self.ChannelTime = self.ChannelTime - 0.03
       
    end
    self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() + Vector(0,0,2))
    self.caster:FaceTowards(self.target)
    return true
end
 

function nobu_3000:OnChannelFinish(bInterrupted)
    local vCasterOrigin = self.caster:GetAbsOrigin()
    local vCasterFW = self.caster:GetForwardVector()
    self.caster:AddNewModifier(self.caster, self, "modifier_merlin_self_pause", {Duration = 0.3}) 
    ParticleManager:DestroyParticle( self.particle_kappa, false)
    ParticleManager:ReleaseParticleIndex( self.particle_kappa)
	StartAnimation( self.caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})
    local aoe = 50
    local position = self:GetCursorPosition()
    self.caster:StopSound("nobu_ulti_cast")
    EmitGlobalSound("nobu_ulti_end") 
    Timers:CreateTimer(0.3, function()
     
        local facing =  self.caster:GetForwardVector()
        facing.z = 0
        self:Shoot({
            Origin =  vCasterOrigin + vCasterFW * 120 + Vector(0,0,150),
            Speed = 10000,
            Facing = facing,
            AoE = aoe,
            Range = 1300,
        })
        Timers:CreateTimer(0.1, function()
            self.caster:SetAbsOrigin(GetGroundPosition(self.caster:GetAbsOrigin(),self.caster))

        end)
        
        for i = 1, #self.dummies do
            Timers:CreateTimer(0.0165 * i, function()
                local facing =  self.dummies[i]:GetForwardVector()
                facing.z = 0
                if(self.caster.is3000Acquired) then
                    self.dummies[i]:EmitSound("nobu_shoot_laser")
                else
                    self.dummies[i]:EmitSound("nobu_shoot_multiple_"..math.random(1,2))
                end
           
            self:Shoot({
                Origin = self.dummies[i]:GetAbsOrigin()+vCasterFW*80,
                Speed = 10000,
                Facing =  facing,
                AoE = aoe,
                Range = 1300,
            })
            ParticleManager:DestroyParticle( self.dummies[i].GunFx, false)
		    ParticleManager:ReleaseParticleIndex(self.dummies[i].GunFx)
           
            self.dummies[i]:RemoveSelf()
       
        end)
    
        end
    end)
  
    
 
	 
end
function nobu_3000:CreateGun(position)
	local vCasterOrigin = self.caster:GetAbsOrigin()
	 
	self.Dummy = CreateUnitByName("dummy_unit", self.caster:GetAbsOrigin(), false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
 
    vCasterOrigin.z = 0
	 self.Dummy:SetForwardVector((  self.target- vCasterOrigin ):Normalized())
    --self.Dummy:SetForwardVector(vCasterOrigin - self.Dummy:GetAbsOrigin())
    local GunFx
    if(self.caster.is3000Acquired) then
	      GunFx = ParticleManager:CreateParticle( "particles/nobu/gun_no_destroy.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
    else
        GunFx = ParticleManager:CreateParticle( "particles/nobu/gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
    end
    ParticleManager:SetParticleControl(GunFx, 1, Vector(40,0,0) ) 
	ParticleManager:SetParticleControl(GunFx, 3, position ) 
 
    self.Dummy.GunFx = GunFx
    table.insert(self.dummies, self.Dummy)
	Timers:CreateTimer(3.2, function()
		ParticleManager:DestroyParticle(GunFx, true)
		ParticleManager:ReleaseParticleIndex(GunFx)
	end)
end

function nobu_3000:Shoot(keys)
    local projectileTable = {}
    if(self.caster.is3000Acquired) then
          projectileTable = {
            EffectName = "particles/nobu/nobu_lasers.vpcf" ,
            Ability = self,
            vSpawnOrigin = keys.Origin,
            vVelocity = keys.Facing * keys.Speed,
            fDistance = keys.Range,
            fStartRadius = keys.AoE,
            fEndRadius = keys.AoE,
            Source =  self.caster,
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            flExpireTime = GameRules:GetGameTime() + 0.13,
            
        }
    else
          projectileTable = {
            EffectName = "particles/nobu/nobu_bullet.vpcf" ,
            Ability = self,
            vSpawnOrigin = keys.Origin,
            vVelocity = keys.Facing * keys.Speed,
            fDistance = keys.Range,
            fStartRadius = keys.AoE,
            fEndRadius = keys.AoE,
            Source =  self.caster,
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            flExpireTime = GameRules:GetGameTime() + 0.13,
             
        }
    end
   
    ProjectileManager:CreateLinearProjectile(projectileTable)
end

 
function nobu_3000:OnProjectileHit_ExtraData(target, location, data)
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * self:GetSpecialValueFor("damage_mod")
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
    end
    if hCaster.is3000Acquired then
        DoDamage(hCaster, target, damage*0.85, DAMAGE_TYPE_PHYSICAL, 0, self, false)
        DoDamage(hCaster, target, damage*0.15, DAMAGE_TYPE_PURE, 0, self, false)
    else
        DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
        target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    end
    if( hCaster:FindModifierByName("modifier_nobu_dash_dmg") ) then
        DoDamage(hCaster, target, hCaster:FindAbilityByName("nobu_dash"):GetSpecialValueFor("attr_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
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
    if(self.caster.is3000Acquired) then  
        return false
    else
        return true
    end
end
