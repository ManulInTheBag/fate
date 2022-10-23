nobu_guns = class({})
LinkLuaModifier("modifier_nobu_atk_sound","abilities/nobu/nobu_guns", LUA_MODIFIER_MOTION_NONE)


function nobu_guns:GetGunsDamage()
    if(self:GetCaster().UnifyingAcquired) then
        return self:GetSpecialValueFor("base_dmg") + self:GetCaster():GetAttackDamage()* (self:GetSpecialValueFor("dmg_per_atk") + 0.75)
    else
        return self:GetSpecialValueFor("base_dmg") + self:GetCaster():GetAttackDamage()* self:GetSpecialValueFor("dmg_per_atk")
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
 
    self.Dummy.GunFx = GunFx
    local dummy = self.Dummy
    Timers:CreateTimer(1, function()
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
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
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
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    return true
end
  