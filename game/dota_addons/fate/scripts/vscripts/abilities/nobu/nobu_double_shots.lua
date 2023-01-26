nobu_double_shots = class({})
LinkLuaModifier("modifier_nobu_turnlock", "abilities/nobu/nobu_double_shots", LUA_MODIFIER_MOTION_NONE)


 

function nobu_double_shots:OnSpellStart()
    local hCaster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    Timers:RemoveTimer("nobu_shoots")
    Timers:RemoveTimer("nobu_stop")
    Timers:RemoveTimer("nobu_stop_2")
     hCaster:AddNewModifier(hCaster, self, "modifier_nobu_turnlock", {duration = duration} )
      
    Timers:CreateTimer("nobu_stop", {
		endTime = 0.5,
		callback = function()
        if hCaster:IsAlive() and hCaster:GetAbilityByIndex(2) == self then
            hCaster:SwapAbilities("nobu_double_shots", "nobu_double_shots_stop", false, true)
            Timers:CreateTimer("nobu_stop_2", {
                endTime = 4.5,
                callback = function()
                if hCaster:GetAbilityByIndex(2):GetName() == "nobu_double_shots_stop" then
                    hCaster:SwapAbilities("nobu_double_shots", "nobu_double_shots_stop", true, false)    
                end 
            end})

        end
    end})
	local target = self:GetCursorPosition()
	self.target_enemy = nil
	local origin_e = nil
	local direction_e = hCaster:GetForwardVector()
   
	self.targetted = false
    local aoe = 70

	if self:GetCursorTarget() then
		self.targetted = true
		self.target_enemy = self:GetCursorTarget()
	
	 
	end
    local counter = 0
 
        StartAnimation(hCaster, {duration= duration , activity=ACT_DOTA_CAST_ABILITY_3_END, rate= 3})
     
  
    Timers:CreateTimer("nobu_shoots", {
	endTime = 0.0,
	callback = function()
    counter = counter + 1 
    if (not hCaster:IsAlive()) or  hCaster:IsStunned() then return  0.033 end
    if( counter >= duration*30) then return end
	local origin = hCaster:GetAbsOrigin()
    if(self.target_enemy == hCaster)  then

        self.targetted = false
        self.target_enemy = nil
    end    
    if( self.targetted) then 
        if(   not  hCaster:CanEntityBeSeenByMyTeam(self.target_enemy)   ) then
            self.targetted = false
            target = origin_e
            self.target_enemy = nil
            
        else
            origin_e = self.target_enemy:GetAbsOrigin()
            direction_e = (Vector(origin_e.x, origin_e.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
         
        end
    else
        direction_e = (Vector(target.x, target.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
      
    end
    hCaster:SetForwardVector(direction_e)
    if counter % 10 ~=  0 then return  0.033 end
    local facing = hCaster:GetForwardVector()
    local vRightVect = hCaster:GetRightVector() 
    facing.z = 0
    if counter%20 == 10 then
        hCaster:EmitSound("nobu_shoot_1")
         
        self:Shoot({
            Origin = origin + facing * 80 + Vector(0,0,100)+ vRightVect * 20,
            Speed = 10000,
            Facing = facing,
            AoE = aoe,
            Range = 1000,
        })
    else
        hCaster:EmitSound("nobu_shoot_2")
         
        self:Shoot({
            Origin =  origin + facing * 80 + Vector(0,0,100) + vRightVect * -20,
            Speed = 10000,
            Facing = facing,
            AoE = aoe,
            Range = 1000,
        })
    end
    
    return 0.033
    end})

  

    
    
   
   
end

function nobu_double_shots:Shoot(keys)
    local projectileTable = {
        EffectName = "particles/nobu/nobu_bullet.vpcf" ,
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
        flExpireTime = GameRules:GetGameTime() + 0.33,
        
    }
    ProjectileManager:CreateLinearProjectile(projectileTable)
end

function nobu_double_shots:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * self:GetSpecialValueFor("damage_mod")
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
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
    return true 
end




modifier_nobu_turnlock = class({})

function modifier_nobu_turnlock:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING, MODIFIER_EVENT_ON_ORDER ,   MODIFIER_EVENT_ON_UNIT_MOVED,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				}
end

function modifier_nobu_turnlock:OnUnitMoved( args )
	if self.position then
        local origin_diff = args.new_pos- self.position
        local origin_diff_norm = origin_diff:Normalized()
        if self:GetCaster():GetForwardVector():Dot(origin_diff_norm) < -0.5 then
            self.movementslowed = -40
        elseif self:GetCaster():GetForwardVector():Dot(origin_diff_norm) < 0 then
            self.movementslowed = -15
        else
            self.movementslowed = 0
        end
    end
    self.position  = self:GetCaster():GetAbsOrigin()
end
function modifier_nobu_turnlock:GetModifierMoveSpeedBonus_Percentage()
	return   self.movementslowed
end

function modifier_nobu_turnlock:OnOrder(args)
    if args.unit ~= self:GetParent() then return end
 
	if( args.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET ) then
       
		self:GetAbility().target_enemy = args.target
		self:GetAbility().targetted = true
    else 
        if (args.order_type == DOTA_UNIT_ORDER_ATTACK_MOVE) then
         if(args.target ~= nil) then
            self:GetAbility().target_enemy = args.target
            self:GetAbility().targetted = true
             
         else
          
            local targets = FindUnitsInRadius( self:GetCaster():GetTeamNumber(),  self:GetCaster():GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
             if( targets[1] ~= nil and  self:GetCaster():CanEntityBeSeenByMyTeam(targets[1]) ) then
                self:GetAbility().target_enemy = targets[1]
                self:GetAbility().targetted = true
             end    
         end
        end
    end
end
 

function modifier_nobu_turnlock:IsHidden() return false end
function modifier_nobu_turnlock:RemoveOnDeath() return true end
function modifier_nobu_turnlock:IsDebuff() return true end
 
function modifier_nobu_turnlock:GetModifierDisableTurning()
	return 1
end
 
function modifier_nobu_turnlock:CheckState()
    local state =   { 
                        
                        [MODIFIER_STATE_DISARMED] = true,
   
                    }
    return state
end
