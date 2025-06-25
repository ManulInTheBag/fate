muramasa_sword_creation = class({})
LinkLuaModifier("modifier_muramasa_sword_creation","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_flame","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_no_sword","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_muramasa_sword_drop_enemy", "abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_muramasa_sword_drop_enemy_buff", "abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_muramasa_rush_mr","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)

function muramasa_sword_creation:GetIntrinsicModifierName()
    return "modifier_muramasa_sword_creation"
end
 

 

function muramasa_sword_creation:OnHeroDiedNearby( hVictim, hKiller, kv )
	if hVictim == nil or hKiller == nil then
		return
	end
    if not self:GetCaster().SoulSwordAcquired then return end
	if hKiller == self:GetCaster() or ((hVictim:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() < 300 and hVictim:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() )then
        local position = Vector(hVictim:GetAbsOrigin().x, hVictim:GetAbsOrigin().y, 0)
        Timers:CreateTimer(0.5, function()
            CreateModifierThinker(self:GetCaster(), self, "modifier_muramasa_sword_drop_enemy", {duration = 6, Duration = 6, radius = 175,
            x = position.x, y = position.y},  position, self:GetCaster():GetTeamNumber(), false)
    
        end)
	end
end

 
 
modifier_muramasa_sword_creation = class({})

modifier_muramasa_sword_drop_enemy = modifier_muramasa_sword_drop_enemy or class({})

function modifier_muramasa_sword_drop_enemy:IsHidden() return false end
function modifier_muramasa_sword_drop_enemy:IsDebuff() return false end
function modifier_muramasa_sword_drop_enemy:IsPurgable() return false end
function modifier_muramasa_sword_drop_enemy:IsPurgeException() return false end
function modifier_muramasa_sword_drop_enemy:RemoveOnDeath() return true end
function modifier_muramasa_sword_drop_enemy:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
    return state
end
function modifier_muramasa_sword_drop_enemy:OnCreated(hTable)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.duration = hTable.duration
    self.radius = hTable.radius
    self.start_pos = Vector(hTable.x, hTable.y, 0)
    if IsServer() then
        self:StartIntervalThink(FrameTime())
        if not self.swordfx then
            local sword_fx = "particles/muramasa/muramasa_sword_drop_enemy.vpcf"

            self.swordfx =   ParticleManager:CreateParticle( sword_fx, PATTACH_ABSORIGIN_FOLLOW, self.parent )
                            ParticleManager:SetParticleControl( self.swordfx, 0, self.start_pos  )
                            ParticleManager:SetParticleControl( self.swordfx, 1, Vector(self.radius,0,0) )
                            ParticleManager:SetParticleControl( self.swordfx, 2, Vector(6,0,0) )

            self:AddParticle(self.swordfx, true, false, -1, false, false)
        
            --EmitSoundOn("Archer.Kab.Throw."..RandomInt(1, 1), self.parent)
        end
    end
end
function modifier_muramasa_sword_drop_enemy:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_muramasa_sword_drop_enemy:OnIntervalThink()
    if IsServer() and IsNotNull(self.parent) then
        local allies = FindUnitsInRadius(  self.caster:GetTeamNumber(), 
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self.radius, 
                                            DOTA_UNIT_TARGET_TEAM_FRIENDLY , 
                                            DOTA_UNIT_TARGET_HERO, 
                                            DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 
                                            FIND_CLOSEST, 
                                            false)
        if allies[1] ~= nil then 
            allies[1]:AddNewModifier(self.caster, self.ability, "modifier_muramasa_sword_drop_enemy_buff",{duration = 15 })   
            self:Destroy()
        end
    end
end


function modifier_muramasa_sword_drop_enemy:OnDestroy()

end


modifier_muramasa_sword_drop_enemy_buff = class({})
function modifier_muramasa_sword_drop_enemy_buff:OnDestroy()
        ParticleManager:DestroyParticle(self.counterfx , true)
		ParticleManager:ReleaseParticleIndex(self.counterfx )

end
function modifier_muramasa_sword_drop_enemy_buff:OnRefresh(args)
        ParticleManager:DestroyParticle(self.counterfx , true)
		ParticleManager:ReleaseParticleIndex(self.counterfx )
    self:OnCreated(args)
end

function modifier_muramasa_sword_drop_enemy_buff:OnCreated(args)
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetCaster():FindAbilityByName("muramasa_sword_creation")
    if IsServer() then 
        self.parent:Heal(self.parent:GetMaxHealth()*0.25, self:GetAbility())
        self.parent:GiveMana(self.parent:GetMaxMana()*0.25)
        self.counterfx =   ParticleManager:CreateParticle( "particles/muramasa/soul_sword_counter/muramasa_soul_sword_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent )
        ParticleManager:SetParticleControl( self.counterfx , 3, self.parent:GetAbsOrigin() + Vector(0,0,150)  )
        ParticleManager:SetParticleControl( self.counterfx , 2, Vector(5,0,0) )
    end
    self:SetStackCount(5)
    self.isReady = true
end
  
  
function modifier_muramasa_sword_drop_enemy_buff:OnAttackLanded(args)
    local stackCount = self:GetStackCount()
    if self.isReady == false then return end
    self.isReady = false
    ----idk if its needed
    local position = args.target:GetAbsOrigin() + (args.target:GetAbsOrigin() - args.attacker:GetAbsOrigin() ):Normalized() * 100
	self.Dummy = CreateUnitByName("dummy_unit", args.target:GetAbsOrigin(), false, nil, nil, self.caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(args.target:GetAbsOrigin())


    self.Dummy:SetForwardVector((  args.target:GetAbsOrigin() - position ):Normalized())

 


	local GunFx = ParticleManager:CreateParticle( "particles/muramasa/muramasa_soul_sword_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.Dummy )
  
	ParticleManager:SetParticleControl(GunFx, 3, position ) 
    ParticleManager:SetParticleControl(GunFx, 4,   args.target:GetAbsOrigin()- position  ) 
    self.Dummy.GunFx = GunFx
    local dummy = self.Dummy
 
    Timers:CreateTimer(0.5, function()
       if stackCount <= 1 then 
        ParticleManager:DestroyParticle(self.counterfx , true)
		ParticleManager:ReleaseParticleIndex(self.counterfx )
        self:Destroy() 
       end  
       self.isReady = true
        dummy:SetForwardVector((    args.target:GetAbsOrigin() - position ):Normalized())

        ParticleManager:DestroyParticle(GunFx, false)
		ParticleManager:ReleaseParticleIndex(GunFx)
        dummy:EmitSound("muramasa_sword_slash_soul")
        dummy:RemoveSelf()      
    end)
	Timers:CreateTimer(0.25, function()
                DoDamage(self.parent, args.target, (self.ability:GetSpecialValueFor("soul_sa_sword_damage") +self.ability:GetSpecialValueFor("soul_sa_sword_damage_per_level") * self:GetParent():GetLevel() ), DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("attribute_bonus_custom"), false)   

	end)

    --DoDamage(self.parent, args.target, self.parent:GetAttackDamage(), DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("attribute_bonus_custom"), false)   
	self:SetStackCount(stackCount-1)
    ParticleManager:SetParticleControl( self.counterfx , 2, Vector((stackCount-1),0,0) )
end

function modifier_muramasa_sword_drop_enemy_buff:IsHidden()
	return false
end

function modifier_muramasa_sword_drop_enemy_buff:IsPurgable()
	return false
end

function modifier_muramasa_sword_drop_enemy_buff:IsPurgeException()
	return false
end

function modifier_muramasa_sword_drop_enemy_buff:IsDebuff()
	return false
end

function modifier_muramasa_sword_drop_enemy_buff:RemoveOnDeath()
	return true
end

function modifier_muramasa_sword_drop_enemy_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_muramasa_sword_drop_enemy_buff:GetTexture()
  return "custom/muramasa/muramasa_soul_sword_attribute"
end
 
 



function modifier_muramasa_sword_creation:IsHidden()	return false end
function modifier_muramasa_sword_creation:RemoveOnDeath()return false end 
function modifier_muramasa_sword_creation:IsDebuff() 	return false end

function modifier_muramasa_sword_creation:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BASE_OVERRIDE,
    --MODIFIER_EVENT_ON_UNIT_MOVED,
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE,
    MODIFIER_EVENT_ON_HERO_KILLED  }
end

function modifier_muramasa_sword_creation:OnCreated()
    self:SetStackCount(10)
end

function modifier_muramasa_sword_creation:OnRespawn(args)
    local caster = self:GetCaster() 
    if(caster ~= args.unit) then return end
    self:SetStackCount(10)
end

function modifier_muramasa_sword_creation:GetModifierAttackRangeOverride()
	return 150 * (self:GetCaster():HasModifier("modifier_muramasa_no_sword") and 0.5 or 1)
end

function modifier_muramasa_sword_creation:GetModifierAttackSpeed_Limit()
    if(self:GetCaster():HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 2
    end
end

function modifier_muramasa_sword_creation:GetModifierAttackSpeedBaseOverride()
    if(self:GetCaster():HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 2
    end
end

 
-- function modifier_muramasa_sword_creation:OnHeroKilled(args)
--     local hParent = self:GetParent()
--     local hAbility = self:GetAbility()

--     if args.target:GetTeamNumber() ~= hParent:GetTeamNumber() and hParent:IsAlive() and hParent.SoulSwordAcquired and args.attacker == self:GetCaster() then
--         local position = Vector(args.target:GetAbsOrigin().x, args.target:GetAbsOrigin().y, 0)
--         Timers:CreateTimer(0.5, function()
--             CreateModifierThinker(hParent, self, "modifier_muramasa_sword_drop_enemy", {duration = 6, Duration = 6, radius = 175,
--             x = position.x, y = position.y},  position, hParent:GetTeamNumber(), false)
    
--         end)
-- 	end
-- end

 


 function modifier_muramasa_sword_creation:OnAttackLanded(args)
    local caster = self:GetParent()
    if(args.attacker ~= caster ) then return end
local point = args.target:GetAbsOrigin()

local radius = self:GetAbility():GetSpecialValueFor("attack_aoe_radius")
local damage = self:GetAbility():GetSpecialValueFor("base_dmg") + self:GetAbility():GetSpecialValueFor("damage_per_level") *caster:GetLevel() 
local particlestring = "particles/muramasa/muramasa_atk_explosion_base.vpcf"

if(caster:HasModifier("modifier_berserk_scroll")) then
damage = damage + self:GetAbility():GetSpecialValueFor("dmg_berserker")
end
if(caster:HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then
radius = radius + 100
particlestring = "particles/muramasa/muramasa_atk_explosion_powered.vpcf"
end
 
if(caster:HasModifier("modifier_muramasa_dance_controller")) then -- check for Q cast
    damage = damage * self:GetCaster():FindAbilityByName("muramasa_dance"):GetSpecialValueFor("dmg_mod")/100
    DoDamage(caster, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false) 
end

if caster.AppreciationOfSwordsAcquired then
    local cd= caster:FindAbilityByName("muramasa_forge"):GetCooldownTimeRemaining()
    caster:FindAbilityByName("muramasa_forge"):EndCooldown()
    if cd > 1 then 
        caster:FindAbilityByName("muramasa_forge"):StartCooldown(cd - 1)
    end
end
local stackCount = self:GetStackCount()
if(stackCount > 0 ) then
    local explosionFx = ParticleManager:CreateParticle(particlestring, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, point)

 local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    if(not caster:HasModifier("modifier_muramasa_dance_controller"))  then
        for k,v in pairs(targets) do        
            DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)   
        end
    end
    if( (stackCount - 1 )<= 0) then   
        self:SetStackCount(0)
        caster:EmitSound("muramasa_sword_break")
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_muramasa_no_sword", {duration = 10})
    else
        self:SetStackCount(stackCount - 1)
    end
end

 end

 modifier_muramasa_flame = class({})




function modifier_muramasa_flame:IsHidden()	return false end
function modifier_muramasa_flame:RemoveOnDeath()return true end 
function modifier_muramasa_flame:IsDebuff() 	return true end
function modifier_muramasa_flame:OnCreated(args)
self.damage  = args.Damage
end

function modifier_muramasa_flame:OnDestroy()  
    if(IsServer()) then
        DoDamage(self:GetCaster(), self:GetParent(), self.damage*0.3, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    end
end



modifier_muramasa_no_sword = class({})

function modifier_muramasa_no_sword:IsHidden() return false end
function modifier_muramasa_no_sword:DeclareFunctions()
  return { MODIFIER_PROPERTY_MODEL_CHANGE}
end

function modifier_muramasa_no_sword:GetModifierModelChange()
  return "models/muramasa/muramasa_no_sword.vmdl"
end

function modifier_muramasa_no_sword:OnDestroy()
    if not IsServer() then return  end
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_muramasa_sword_creation")
    modifier:SetStackCount(10)
end

