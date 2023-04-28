LinkLuaModifier("modifier_saito_mind_eye","abilities/saito/saito_mind_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_repeated", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_mind_eye_buff", "abilities/saito/saito_mind_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_mind_eye_magic_dmg_immune", "abilities/saito/saito_mind_eye", LUA_MODIFIER_MOTION_NONE)
saito_mind_eye = class({})
function saito_mind_eye:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

function saito_mind_eye:OnSpellStart()
	local caster = self:GetCaster()	
    local duration = self:GetSpecialValueFor("duration")
    self.target = self:GetCursorPosition()
    self.powered = 0
    if(IsServer) then
        if(caster:HasModifier("modifier_saito_fdb_repeated")) then
            self.modifierRepeated = caster:FindModifierByName("modifier_saito_fdb_repeated")
            self.stackCount = self.modifierRepeated:GetStackCount()
        end
    end

    caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
	caster:RemoveModifierByName("modifier_saito_fdb_lastW")
    caster:RemoveModifierByName("modifier_saito_fdb_lastE")
   
	caster:AddNewModifier(caster, self, "modifier_saito_mind_eye",{duration = duration })
 
    caster:SetForwardVector( (  self.target-caster:GetAbsOrigin()):Normalized())
  
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_ligmaballs"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    self.blocking_particle = ParticleManager:CreateParticle("particles/saito/saitoquickslash_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
    Timers:CreateTimer("saito_mind_eye", {
		endTime = duration ,
		callback = function()
        self:RemoveParticle()
     
       
        self:SendProjectile()
	 end})
end

function saito_mind_eye:RemoveParticle()
    ParticleManager:DestroyParticle(  self.blocking_particle, true)
    ParticleManager:ReleaseParticleIndex(   self.blocking_particle)

end
function saito_mind_eye:SendProjectile()
    if not IsServer() then return end
        
	local caster = self:GetCaster()	
    if(not caster:IsAlive()) then return end
    local ability = self
    local velocity = caster:GetForwardVector()* self:GetSpecialValueFor("projectile_speed")
 
    local duration = self:GetSpecialValueFor("duration")
    StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1})
    if(self.modifierRepeated ~= nil) then
    
        caster:RemoveModifierByName("modifier_saito_fdb_repeated")
        caster:AddNewModifier(caster, self.modifierRepeated.ability, "modifier_saito_fdb_repeated", { } )
        caster:FindModifierByName("modifier_saito_fdb_repeated"):SetStackCount(self.stackCount)
        self.modifierRepeated = nil
        self.stackCount = 0
   end
    caster:EmitSound("saito_mind_eye_prock")
	local qdProjectile = 
	{
		Ability = ability,
        EffectName =  "particles/saito/saito_mind_eye_projectile_main.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = self:GetSpecialValueFor("range"),
        fStartRadius =  self:GetSpecialValueFor("projectile_radius"),
        fEndRadius = self:GetSpecialValueFor("projectile_radius"),
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = velocity
	}
    Timers:CreateTimer(0.2, function()                
        local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
       
        return
    end)
   
end

function saito_mind_eye:OnFateSpellBlocked( )
 
    local ability = self

    ability:SendProjectile()
    Timers:RemoveTimer("saito_mind_eye")
    ability:RemoveParticle()
    local caster = self:GetCaster()
    ability.powered = 1
    HardCleanse(caster)
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_ligma_boom"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    --caster:SetForwardVector( ( AbilityCaster:GetAbsOrigin() -caster:GetAbsOrigin()):Normalized())
    if(caster.FreeSpiritAcquired) then
        caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_buff",{duration = 2})
        caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_magic_dmg_immune",{duration = 0.5 })
    else
    --caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_magic_dmg_immune",{duration = 1.5})
    end
end


function saito_mind_eye:OnProjectileHit_ExtraData(hTarget, vLocation, table)

	if hTarget == nil then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")

	--hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
    if(self.powered == 1) then
        hTarget:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})   
        damage = damage *2
    end
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

modifier_saito_mind_eye = class({})




function modifier_saito_mind_eye:OnCreated()    	 
	local ability = self:GetAbility()
	self:StartIntervalThink(FrameTime())

end


function modifier_saito_mind_eye:OnIntervalThink()
    if not IsServer() then return end
    local vector = (self:GetAbility().target-self:GetParent():GetAbsOrigin()):Normalized()
    vector.z = 0
    self:GetParent():SetForwardVector( vector)
end

function modifier_saito_mind_eye:OnTakeDamage(args)
    if IsServer() then 
        local caster = self:GetParent()
        if args.unit ~= self:GetParent() then return end
		local target = args.attacker
        local ability = self:GetAbility()
        local damageTaken = args.original_damage
        local threshold =  ability:GetSpecialValueFor("threshold")
        if damageTaken >= threshold and caster:GetHealth() ~= 0 and self:FilterUnits(caster, target)     then      
            
 
            Timers:CreateTimer(0.033, function()                
                HardCleanse(caster)
                return
            end)
			ability:SendProjectile()
			Timers:RemoveTimer("saito_mind_eye")
            if(caster.FreeSpiritAcquired) then
                caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_buff",{duration = 2})
                caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_magic_dmg_immune",{duration = 0.5})
            else
            --caster:AddNewModifier(caster,ability,"modifier_saito_mind_eye_magic_dmg_immune",{duration = 1.5})
            end
            ability:RemoveParticle()
            ability.powered = 1
            LoopOverPlayers(function(player, playerID, playerHero)
                --print("looping through " .. playerHero:GetName())
                if playerHero.gachi == true then
                    -- apply legion horn vsnd on their client
                    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_ligma_boom"})
                    --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
                end
            end)
            --caster:SetForwardVector( ( args.unit:GetAbsOrigin() -caster:GetAbsOrigin()):Normalized())
            self:Destroy()
        end
    end
end

 
function modifier_saito_mind_eye:FilterUnits(caster, target)    
	local filter = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS, caster:GetTeamNumber())
    if (filter == UF_SUCCESS) then
        if ((caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() < 2000) then
            return true
        end
    end

    return false
end

function modifier_saito_mind_eye:GetTexture()
	return "custom/saito/saito_mind_eye"
end
 

function modifier_saito_mind_eye:GetModifierIncomingDamage_Percentage() 
     return  -1*self:GetAbility():GetSpecialValueFor("resist")
 
end

function modifier_saito_mind_eye:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,  
        MODIFIER_PROPERTY_DISABLE_TURNING   
		
    }
 
    return funcs
end
function modifier_saito_mind_eye:GetModifierDisableTurning()
    return 1
end

function modifier_saito_mind_eye:CheckState()
    local state =   { 
                        
						[MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
						[MODIFIER_STATE_SILENCED] = true,
						[MODIFIER_STATE_MUTED] = true,
   
                    }
    return state
end

 

function modifier_saito_mind_eye:IsHidden()	return false end
function modifier_saito_mind_eye:RemoveOnDeath()return true end 
function modifier_saito_mind_eye:IsDebuff() 	return false end
 

 


modifier_saito_mind_eye_buff = class({})

function modifier_saito_mind_eye_buff:DeclareFunctions()

    return { MODIFIER_PROPERTY_EVASION_CONSTANT, 
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }

end

function modifier_saito_mind_eye_buff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("mr")
end

function modifier_saito_mind_eye_buff:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("evasion")
end

function modifier_saito_mind_eye_buff:OnDestroy()
    HardCleanse(self:GetParent())
end


function modifier_saito_mind_eye_buff:IsHidden()	return false end
function modifier_saito_mind_eye_buff:RemoveOnDeath()return true end 
function modifier_saito_mind_eye_buff:IsDebuff() 	return false end
 


modifier_saito_mind_eye_magic_dmg_immune = class({})

function modifier_saito_mind_eye_magic_dmg_immune:DeclareFunctions()

    return { 
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }

end

function modifier_saito_mind_eye_magic_dmg_immune:GetModifierMagicalResistanceBonus()
    return 100
end
 
 

function modifier_saito_mind_eye_magic_dmg_immune:IsHidden()	return false end
function modifier_saito_mind_eye_magic_dmg_immune:RemoveOnDeath()return true end 
function modifier_saito_mind_eye_magic_dmg_immune:IsDebuff() 	return false end
 