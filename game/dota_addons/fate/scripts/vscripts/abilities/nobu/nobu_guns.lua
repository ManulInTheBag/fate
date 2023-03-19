nobu_guns = class({})
LinkLuaModifier("modifier_nobu_atk_sound","abilities/nobu/nobu_guns", LUA_MODIFIER_MOTION_NONE)

function nobu_guns:GetBehavior()
	if self:GetLevel() == 1 then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	else
		return  DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING
	end
end

function nobu_guns:GetAnimeVectorTargetingRange()
    return 900
end
function nobu_guns:GetAnimeVectorTargetingStartRadius()
    if self:GetLevel() == 2 then
        return 100
    elseif self:GetLevel() == 3  then
        return 150
    elseif self:GetLevel() == 4 then
        return 250
    end
end
function nobu_guns:GetAnimeVectorTargetingEndRadius()
    if self:GetLevel() == 2 then
        return 100
    elseif self:GetLevel() == 3  then
        return 150
    elseif self:GetLevel() == 4 then
        return 250
    end
end
function nobu_guns:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function nobu_guns:GetAnimeVectorTargetingColor()
    return Vector(255, 0, 0)
end

function nobu_guns:OnHeroLevelUp()
	local caster = self:GetCaster()

	if caster.NobuActionAcquired then
		if caster:GetLevel() < 8 then
			self:SetLevel(2)
		elseif caster:GetLevel() >= 8 and caster:GetLevel() < 16 then
			self:SetLevel(3)
		elseif caster:GetLevel() >= 16 then
			self:SetLevel(4)
		end
	end
end

function nobu_guns:OnSpellStart()
    self.caster = self:GetCaster()
    self.direction = self:GetAnimeVectorTargetingMainDirection()
    self.direction.z = 0
 

    local up = Vector(0,0,1)
    self.rightvec = self.direction:Cross(up)
    self.leftvec = -  self.rightvec
    print( self.rightvec)
    print(self.direction)
    self.target = self:GetCursorPosition()
    if(self.dummies == nil) then
        self.dummies = {}
    end
    local gun_amount
    if  self.caster:GetLevel() < 8 then
        gun_amount = 3
    elseif  self.caster:GetLevel() >= 8 and  self.caster:GetLevel() < 16 then
        gun_amount = 5
    elseif  self.caster:GetLevel() >= 16 then
        gun_amount = 7
    end
  
    if( self.dummies ~= {}) then
        for i = 1, #self.dummies do
            if(self.dummies[i] ~= nil) then
             ParticleManager:DestroyParticle( self.dummies[i].GunFx, true)
		     ParticleManager:ReleaseParticleIndex(self.dummies[i].GunFx)
             self.dummies[i]:RemoveSelf()
             self.dummies[i] = nil
            end 
        end
        self.dummies = {}
    end
    
    for i=1,gun_amount do 
        local gun_spawn = self.target + self.leftvec * 50* (gun_amount-1)/2 + Vector(0,0,150)
		gun_spawn = gun_spawn + self.rightvec * (i-1) * 50 
     	self:CreateGun(gun_spawn) 
    end
    local aoe = 50
    Timers:CreateTimer(0.5, function()
        for i = 1, #self.dummies do
            if(self.dummies[i] == nil ) then return end
            Timers:CreateTimer(0.05 * i, function()
                if(self.dummies[i] == nil ) then return end
                local facing =   self.direction
                self.dummies[i]:EmitSound("nobu_shoot_multiple_"..math.random(1,2))
                               
            self:Shoot({
                Origin = self.dummies[i]:GetAbsOrigin()+ self.direction*80,
                Speed = 10000,
                Facing =  facing,
                AoE = aoe,
                Range = 1300,
            })
            ParticleManager:DestroyParticle( self.dummies[i].GunFx, false)
		    ParticleManager:ReleaseParticleIndex(self.dummies[i].GunFx)
            
            self.dummies[i]:RemoveSelf()
            self.dummies[i] = nil
            end)
    
        end
    end)
end

function nobu_guns:CreateGun(position)
	local vCasterOrigin = self.caster:GetAbsOrigin()
	self.Dummy = CreateUnitByName("dummy_unit", position, false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
    vCasterOrigin.z = 0
    local fwtarget =  self.direction
    self.Dummy:SetForwardVector((fwtarget ):Normalized())
    local GunFx
    GunFx = ParticleManager:CreateParticle( "particles/nobu/gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
    ParticleManager:SetParticleControl(GunFx, 3, position ) 
    ParticleManager:SetParticleControl(GunFx, 4, fwtarget ) 
    self.Dummy.GunFx = GunFx
    table.insert(self.dummies, self.Dummy)
	Timers:CreateTimer(3.2, function()
		ParticleManager:DestroyParticle(GunFx, true)
		ParticleManager:ReleaseParticleIndex(GunFx)
	end)
   
end


function nobu_guns:Shoot(keys)
    local projectileTable = {
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
            iUnitTargetType = DOTA_UNIT_TARGET_ALL,
            flExpireTime = GameRules:GetGameTime() + 0.13,
             
        }
    ProjectileManager:CreateLinearProjectile(projectileTable)
end

function nobu_guns:GetGunsDamage()
    local caster = self:GetCaster()
    if(caster.UnifyingAcquired) then
        return self:GetSpecialValueFor("base_dmg") +caster:GetLevel()*  self:GetSpecialValueFor("dmg_per_lvl") 
        +caster:GetIntellect() * self:GetSpecialValueFor("dmg_per_int") + (caster:HasModifier("modifier_nobu_strategy_attribute") and 70 or 0)
    else
        return self:GetSpecialValueFor("base_dmg") +caster:GetLevel()* self:GetSpecialValueFor("dmg_per_lvl")  + (caster:HasModifier("modifier_nobu_strategy_attribute") and 70 or 0)
    end
end
function nobu_guns:GetIntrinsicModifierName()
	return "modifier_nobu_atk_sound"
end



modifier_nobu_atk_sound = class({})



function modifier_nobu_atk_sound:OnCreated()
	self.sound = "Tsubame_Slash_"..math.random(1,3)
end

function modifier_nobu_atk_sound:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "Tsubame_Slash_"..math.random(1,3)

end

function modifier_nobu_atk_sound:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_nobu_atk_sound:DeclareFunctions()
	local func = {
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

				}
	return func
end

function modifier_nobu_atk_sound:GetAttackSound()
	return self.sound
end

function modifier_nobu_atk_sound:IsHidden() return true end
function modifier_nobu_atk_sound:RemoveOnDeath() return true end

 


function nobu_guns:DOWShoot(keys, position)
    
    self.caster = self:GetCaster()
    local vCasterOrigin = self.caster:GetAbsOrigin()
    local targets = FindUnitsInRadius( self.caster:GetTeam(),  self.caster:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    self.target = nil
    local target  
    if( targets[1] ~= nil) then
        self.target  = targets[1]:GetAbsOrigin()
         target = targets[1]
     end    
    if(target == nil) then return end
    self.caster.ISDOW = false 
	self.Dummy = CreateUnitByName("dummy_unit", self.caster:GetAbsOrigin(), false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
  
    vCasterOrigin.z = 0
	 self.Dummy:SetForwardVector((  self.target- position ):Normalized())
    --self.Dummy:SetForwardVector(vCasterOrigin - self.Dummy:GetAbsOrigin())

	local GunFx = ParticleManager:CreateParticle( "particles/nobu/gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
    ParticleManager:SetParticleControl(GunFx, 1, Vector(40,0,0) ) 
	ParticleManager:SetParticleControl(GunFx, 3, position ) 
    ParticleManager:SetParticleControl(GunFx, 4, self.target- position ) 
    self.Dummy.GunFx = GunFx
    local dummy = self.Dummy
    Timers:CreateTimer(1.5, function()
        self.caster.ISDOW = true 

    end)

	Timers:CreateTimer(0.4, function()
        dummy:SetForwardVector((  target:GetAbsOrigin()- position ):Normalized())
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
            iUnitTargetType = DOTA_UNIT_TARGET_ALL,
            flExpireTime = GameRules:GetGameTime() + 0.33,
            
        }
        ProjectileManager:CreateLinearProjectile(projectileTable)
        ParticleManager:DestroyParticle(GunFx, false)
		ParticleManager:ReleaseParticleIndex(GunFx)
        dummy:RemoveSelf() 
	end)

    
 
end


function nobu_guns:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = self:GetGunsDamage()
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
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
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    if( hCaster:FindModifierByName("modifier_nobu_dash_dmg") ) then
        DoDamage(hCaster, target, hCaster:FindAbilityByName("nobu_dash"):GetSpecialValueFor("attr_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    return true
end
  