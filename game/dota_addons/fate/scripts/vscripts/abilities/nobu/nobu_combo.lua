nobu_combo = class({})

LinkLuaModifier("modifier_nobu_combo_self","abilities/nobu/nobu_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_combo_mark", "abilities/nobu/nobu_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_combo_stun", "abilities/nobu/nobu_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_combo_cd", "abilities/nobu/nobu_combo", LUA_MODIFIER_MOTION_NONE)
function nobu_combo:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:AddNewModifier(hCaster, self, "modifier_nobu_combo_self", {duration = self:GetSpecialValueFor("run_duration") + 1.5} )
    hCaster:AddNewModifier(hCaster, self, "modifier_merlin_self_pause", {Duration = 1.5}) 
    hCaster.target_enemy = self:GetCursorTarget()
    self.target_enemy = self:GetCursorTarget()
    StartAnimation(hCaster, {duration=1.5 , activity=ACT_DOTA_CAST_ABILITY_6, rate= 0.5})
    self.particle_kappa = ParticleManager:CreateParticle("particles/nobu/nobu_combo_smoke_red.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
     hCaster.target_enemy:AddNewModifier(hCaster, self, "modifier_nobu_combo_mark", {duration = self:GetSpecialValueFor("run_duration")} )
     EmitGlobalSound("nobu_combo_cast") 
     self.caster = hCaster
     hCaster:AddNewModifier(hCaster, self, "modifier_nobu_combo_cd", {duration = self:GetCooldown(1)})
     local masterCombo = hCaster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
end

function nobu_combo:AttackEnemy()
    local hCaster = self:GetCaster()
    local damage =  self:GetSpecialValueFor("dmg_initial")
    local target = self.target_enemy
    if(not hCaster:IsAlive() or not target:IsAlive()) then return end
    self.dummies = {}
  
    hCaster:SetAbsOrigin(hCaster:GetAbsOrigin() + hCaster:GetForwardVector()*90)
    giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 3)
    target:RemoveModifierByName("modifier_nobu_combo_mark")
    giveUnitDataDrivenModifier(hCaster, target, "modifier_nobu_combo_stun", 3)
    local sin = Physics:Unit( target)
    Timers:CreateTimer( 0.40, function()
        if(hCaster:IsAlive() == false) then return end
        ParticleManager:DestroyParticle( self.particle_kappa, false)
        ParticleManager:ReleaseParticleIndex( self.particle_kappa)
            target:SetPhysicsVelocity(Vector(0,0,1500))
        end)
   Timers:CreateTimer( 0.62, function()
            if(hCaster:IsAlive() == false) then return end
            
            
            target:SetPhysicsVelocity(Vector(0,0,-500))
            end)
    Timers:CreateTimer(1.1,  function()
        target:SetBounceMultiplier(0)
        target:PreventDI(false)
        target:SetPhysicsVelocity(Vector(0,0,0))
        target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        DoDamage(hCaster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        hCaster:EmitSound("merlin_staff")
        self.target = target:GetAbsOrigin()
        for i=1,25 do 
            local gun_spawn =   PointOnCircle(GetGroundPosition(target:GetAbsOrigin(), caster), 450,i*10)
            gun_spawn = gun_spawn + RandomInt(0,150)*Vector(0,0,1) 
           
            self:CreateGun(gun_spawn) 
        end

        end)
        
        Timers:CreateTimer(1.8,  function()
         
         for i = 1, #self.dummies do
             Timers:CreateTimer(0.033 * i, function()
                 local facing =  self.dummies[i]:GetForwardVector()
                 facing.z = 0
                self:Shoot({
                    Origin = self.dummies[i]:GetAbsOrigin()+facing*80,
                    Speed = 10000,
                    Facing =  facing,
                    AoE = aoe,
                    Range = 1000,
                })
                self.dummies[i]:EmitSound("nobu_shoot_multiple_"..math.random(1,2))
                ParticleManager:DestroyParticle( self.dummies[i].GunFx, false)
		        ParticleManager:ReleaseParticleIndex(self.dummies[i].GunFx)
                self.dummies[i]:RemoveSelf()
              end)
          end
         end)

   
     Timers:CreateTimer(3,  function()
        StopGlobalSound("nobu_combo_cast") 
        EmitGlobalSound("nobu_combo_end") 
            if( target:IsAlive()) then
                FindClearSpaceForUnit(  target,   target:GetAbsOrigin(), true)
                
            end
        end)    
    StartAnimation(hCaster, {duration=3 , activity=ACT_DOTA_CAST_ABILITY_7, rate= 1})
 

end

function nobu_combo:CreateGun(position)
   
	local vCasterOrigin = self.caster:GetAbsOrigin()
	 
	self.Dummy = CreateUnitByName("dummy_unit", self.caster:GetAbsOrigin(), false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
 
    vCasterOrigin.z = 0
	 self.Dummy:SetForwardVector((  self.target- position ):Normalized())
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


function nobu_combo:Shoot(keys)
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

function nobu_combo:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * self:GetSpecialValueFor("dmg_mod")
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    return true 
end



modifier_nobu_combo_self = class({})

function modifier_nobu_combo_self:OnCreated()
    self:StartIntervalThink(0.033)
    self.caster = self:GetCaster()
end

function modifier_nobu_combo_self:OnIntervalThink()
    if not IsServer() then return end
    if(not self.caster.target_enemy:IsAlive()  or not self.caster:IsAlive() ) then return end
    if(self.caster.target_enemy:GetAbsOrigin()- self.caster:GetAbsOrigin()):Length2D() < 250 then
        self:GetAbility():AttackEnemy()
        self:Destroy()
    end
 
    self.caster:MoveToTargetToAttack(self.caster.target_enemy)



end

function modifier_nobu_combo_self:DeclareFunctions()
	return {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
				}
end

function modifier_nobu_combo_self:GetModifierProvidesFOWVision()
    return 1
end

function modifier_nobu_combo_self:GetModifierMoveSpeed_Absolute()
	return 1500  --self:GetAbility():GetSpecialValueFor("run_speed")
end
function modifier_nobu_combo_self:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 
 


function modifier_nobu_combo_self:IsHidden() return false end
function modifier_nobu_combo_self:RemoveOnDeath() return true end
function modifier_nobu_combo_self:IsDebuff() return true end
 
 
 
function modifier_nobu_combo_self:CheckState()
    local state =   { 
                        
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end


modifier_nobu_combo_mark = class({})

function modifier_nobu_combo_mark:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_nobu_combo_mark:GetModifierProvidesFOWVision()
    return 1
end

function modifier_nobu_combo_mark:IsHidden()
    return false
end

function modifier_nobu_combo_mark:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_nobu_combo_stun = class({})
function modifier_nobu_combo_stun:IsHidden() return false end
function modifier_nobu_combo_stun:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_nobu_combo_stun:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_nobu_combo_cd = class({})


function modifier_nobu_combo_cd:IsHidden()
    return false 
end

function modifier_nobu_combo_cd:RemoveOnDeath()
    return false
end

function modifier_nobu_combo_cd:IsDebuff()
    return true 
end

function modifier_nobu_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end