nobu_dash = class({})
LinkLuaModifier("modifier_nobu_turnrate", "abilities/nobu/nobu_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_dash_dmg", "abilities/nobu/nobu_dash", LUA_MODIFIER_MOTION_NONE)

function nobu_dash:OnSpellStart()
	local caster = self:GetCaster()
	Timers:RemoveTimer("nobu_dash")
	if(self:GetCurrentAbilityCharges() > 0) then
		self:EndCooldown()
		self:StartCooldown(0.5)
	end
	local ability = self
	if(caster.NobuActionAcquired) then
		caster:AddNewModifier(caster, self, "modifier_nobu_dash_dmg", {duration = 3} )
	end
	caster:RemoveModifierByName("modifier_nobu_strategy_attribute_cooldown")
	caster.IsStrategyReady = true
	local speed = 1200
	local point  = self:GetCursorPosition()+caster:GetForwardVector()
	local direction      = (point - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local dist = 400--self:GetSpecialValueFor("dist")
	local casted_dist = (point - caster:GetAbsOrigin()):Length2D()
	if (casted_dist > dist )then
		point = caster:GetAbsOrigin() + (((point - caster:GetAbsOrigin()):Normalized()) * dist)
		casted_dist = dist
	end
	local sin = Physics:Unit(caster)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and caster:GetAbilityByIndex(3):GetName() ~= "nobu_combo"then      
    	if caster:FindAbilityByName("nobu_combo"):IsCooldownReady()  then
             
    		caster:SwapAbilities("nobu_guns", "nobu_combo", false, true)

    		Timers:CreateTimer('nobu_window',{
		        endTime = 2,
		        callback = function()
		        if caster:GetAbilityByIndex(3):GetName() ~= "nobu_guns"  then
					caster:SwapAbilities("nobu_combo", "nobu_guns", false, true)
		       	end
		    end
		    })
 
        end
    end
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(direction * speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
	local dash_time =  casted_dist/ speed
	caster:AddNewModifier(caster, self, "modifier_nobu_turnrate", {duration = dash_time} )
	if not caster:HasModifier("modifier_nobu_turnlock") then
		StartAnimation(caster, {duration= dash_time , activity=ACT_DOTA_CAST_ABILITY_2, rate= 25/(dash_time*30)})
	end
	Timers:CreateTimer("nobu_dash", {
		endTime = dash_time ,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		if(caster.is3000Acquired) then
			self:AttributeGuns()
		end
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("nobu_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		if(caster.is3000Acquired) then
			self:AttributeGuns()
		end
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end


function nobu_dash:AttributeGuns()
	local hCaster = self:GetCaster()
	local gun_spawn = hCaster:GetAbsOrigin()+  hCaster:GetRightVector() * 100 + Vector(0,0,150)
	local gun_spawn2 = hCaster:GetAbsOrigin()+  hCaster:GetRightVector() * -100  + Vector(0,0,150)
 	local aoe = 50
	 Timers:CreateTimer(0.1, function()
		self:Shot({
			Speed = 10000,
			AoE = aoe,
			Range = 1000,
		},  gun_spawn2 )

	 end)
	self:Shot({
		Speed = 10000,
		AoE = aoe,
		Range = 1000,
	},  gun_spawn )
	
end



function nobu_dash:Shot(keys, position)
    
    self.caster = self:GetCaster()
    local vCasterOrigin = self.caster:GetAbsOrigin()
    vCasterOrigin.z = 0
    local targets = FindUnitsInRadius( self.caster:GetTeam(),  self.caster:GetOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    self.target = nil
     if( targets[1] ~= nil) then
        self.target  = targets[1]:GetAbsOrigin()
     end    
	 if(self.target == nil) then return end 
     
	self.Dummy = CreateUnitByName("dummy_unit", vCasterOrigin, false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
	self.Dummy:SetForwardVector((  self.target- position ):Normalized())

 	local GunFx = ParticleManager:CreateParticle( "particles/nobu/gun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
	 ParticleManager:SetParticleControl(GunFx, 3, position ) 
     ParticleManager:SetParticleControl(GunFx, 4, self.target- position ) 
    self.Dummy.GunFx = GunFx
    local dummy = self.Dummy
 	Timers:CreateTimer(0.4, function()
        dummy:SetForwardVector((  self.target - position ):Normalized())
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


 
function nobu_dash:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * 0.5
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
    end
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	if( hCaster:FindModifierByName("modifier_nobu_dash_dmg") ) then
        DoDamage(hCaster, target, hCaster:FindAbilityByName("nobu_dash"):GetSpecialValueFor("attr_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
        local knockback = { should_stun = false,
        knockback_duration = 0.05,
        duration = 0.05,
        knockback_distance = 40,
        knockback_height = 0,
        center_x = hCaster:GetAbsOrigin().x,
        center_y = hCaster:GetAbsOrigin().y,
        center_z = hCaster:GetAbsOrigin().z }

        target:AddNewModifier(hCaster, self, "modifier_knockback", knockback)
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
    return true 
end


 
modifier_nobu_turnrate = class({})

function modifier_nobu_turnrate:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE, }
							
end



function modifier_nobu_turnrate:IsHidden() return true end
function modifier_nobu_turnrate:RemoveOnDeath() return true end
function modifier_nobu_turnrate:IsDebuff() return false end


function modifier_nobu_turnrate:GetModifierTurnRate_Percentage()
	return 100


end


modifier_nobu_dash_dmg = class({})

 

function modifier_nobu_dash_dmg:IsHidden() return false end
function modifier_nobu_dash_dmg:RemoveOnDeath() return true end
function modifier_nobu_dash_dmg:IsDebuff() return false end

 



