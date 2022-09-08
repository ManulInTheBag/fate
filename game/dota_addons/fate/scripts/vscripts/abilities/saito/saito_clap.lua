LinkLuaModifier("modifier_saito_slow","abilities/saito/saito_clap", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_pause", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
saito_clap = class({})
function saito_clap:GetAOERadius()
    return self:GetSpecialValueFor("range")
end


function saito_clap:OnUpgrade()
    local Caster = self:GetCaster() 
    if(Caster:FindAbilityByName("saito_inv_sword"):GetLevel()< self:GetLevel()) then
		Caster:FindAbilityByName("saito_inv_sword"):SetLevel(self:GetLevel())
	end
	if(Caster:FindAbilityByName("saito_quickslash"):GetLevel()< self:GetLevel()) then
			Caster:FindAbilityByName("saito_quickslash"):SetLevel(self:GetLevel())
	end
end


function saito_clap:OnSpellStart()
	local caster = self:GetCaster()
StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_2, rate=1})		
--caster:AddNewModifier(caster, caster, "modifier_saito_fdb_pause",{duration = 0.2})
local modifier_jopa = caster:FindModifierByName("modifier_saito_fdb")
caster.wused = caster.wused + 1
if(caster.wused == 3) then
	caster:SetModifierStackCount("modifier_saito_fdb",caster,0)
end
modifier_jopa:SpendStack()
Timers:CreateTimer(0.1, function()
 
	

    local ability = self
    local radius = self:GetSpecialValueFor("radius")
	if(caster.ShinsengumiAcquired and caster.wused == 0) then
		radius = radius*2
	end
    local damage = self:GetSpecialValueFor("damage")+ caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
	if(caster.FreestyleAcquired) then
        damage = damage + caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
    end
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	if(IsServer )then
		if(caster:HasModifier("modifier_saito_fdb_lastW")) then
			damage = damage/2
			slow_duration = slow_duration/2
			stun_duration = stun_duration/2
		end
	end


	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.gachi == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_vineboom"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)


    local point = caster:GetAbsOrigin() -- + caster:GetForwardVector()*self:GetSpecialValueFor("range") 
    --StartAnimation(caster, {duration = 1, activity = ACT_DOTA_RAZE_2, rate = 1+(0.4-self:GetCastPoint())*2})  
 	 local 	partname
	if(radius > 500) then
		partname = "particles/saito/saito_shock_2.vpcf" 
	else
		partname = "particles/saito/saito_shock.vpcf" 
	end

	local explosionFx = ParticleManager:CreateParticle(partname, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, point)
    ParticleManager:SetParticleControl(explosionFx, 1, Vector(radius,radius,radius))
    caster:AddNewModifier(caster, caster, "modifier_saito_fdb_lastW",{duration = 15})
	caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
	caster:RemoveModifierByName("modifier_saito_fdb_lastE")
 

    local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = stun_duration})    
		if(caster.MasteryAcquired) then 
			v:AddNewModifier(caster, self, "modifier_saito_slow", {Duration = slow_duration})     
		end
    end 

	caster:EmitSound("saito_clap")
 
end)
end

modifier_saito_slow = class({})

function modifier_saito_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_saito_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_saito_slow:IsHidden()
	return false 
end