LinkLuaModifier("modifier_saito_magres_down","abilities/saito/saito_inv_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_pause", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
 saito_inv_sword = class({})

function saito_inv_sword:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end


 


function saito_inv_sword:OnUpgrade()
    local Caster = self:GetCaster() 
    if(Caster:FindAbilityByName("saito_quickslash"):GetLevel()< self:GetLevel()) then
    Caster:FindAbilityByName("saito_quickslash"):SetLevel(self:GetLevel())
    end
    if(Caster:FindAbilityByName("saito_clap"):GetLevel()< self:GetLevel()) then
        Caster:FindAbilityByName("saito_clap"):SetLevel(self:GetLevel())
    end
end

function saito_inv_sword:OnSpellStart()
	local caster = self:GetCaster()
    --caster:AddNewModifier(caster, caster, "modifier_saito_fdb_pause",{duration = 0.2})
    StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_3, rate=1})	
    local modifier_jopa = caster:FindModifierByName("modifier_saito_fdb")
   
    caster.eused = caster.eused + 1
    if(caster.eused == 3) then
		caster:SetModifierStackCount("modifier_saito_fdb",caster,0)
	end
    modifier_jopa:SpendStack()
Timers:CreateTimer(0.1, function()
	local ability = self
    local damage = self:GetSpecialValueFor("damage")+ caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
    
    if(caster.FreestyleAcquired) then
        damage = damage + caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
    end
  
    if(IsServer )then
		if(caster:HasModifier("modifier_saito_fdb_lastE")) then
			damage = damage/2
			 
		end
	end
 
    local sword_fx = ParticleManager:CreateParticle("particles/saito/saito_inv_sword_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(sword_fx, 4, caster, PATTACH_POINT_FOLLOW, "slash", Vector(0,0,0), true)
    LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero.gachi == true and playerHero == self:GetCaster() then
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_shing"})
        end
    end)
    local radius = self:GetSpecialValueFor("radius")
    local width = 120
    
    caster:AddNewModifier(caster, caster, "modifier_saito_fdb_lastE",{duration = 15})
	caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
	caster:RemoveModifierByName("modifier_saito_fdb_lastW")

 

    caster:EmitSound("saito_inv_sword1")

    local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

for _,enemy in pairs(enemies) do
 
        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        if(caster.MasteryAcquired) then 
            enemy:AddNewModifier(caster, self, "modifier_saito_magres_down", {Duration = 2})     
        end
 

end
 
if(caster.ShinsengumiAcquired and caster.eused == 0) then
    StartAnimation(caster, {duration=0.2, activity=ACT_DOTA_CAST_ABILITY_3, rate=1})	
 
    Timers:CreateTimer(0.1, function()
    caster:EmitSound("saito_inv_sword2")



    local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

    for _,enemy in pairs(enemies) do
 
        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        if(caster.MasteryAcquired) then 
            enemy:AddNewModifier(caster, self, "modifier_saito_magres_down", {Duration = 2})     
        end
 

    end
end)
end

 
end)
end

modifier_saito_magres_down = class({})

function modifier_saito_magres_down:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }

	return funcs
end

function modifier_saito_magres_down:GetModifierMagicalResistanceBonus()
	return -self:GetAbility():GetSpecialValueFor("mr_down")
end

function modifier_saito_magres_down:IsHidden()
	return false 
end

function modifier_saito_magres_down:RemoveOnDeath()
	return true 
end