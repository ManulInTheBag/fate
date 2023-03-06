 
LinkLuaModifier("modifier_saito_combo_silence","abilities/saito/saito_undefeatable_style_active", LUA_MODIFIER_MOTION_NONE)
saito_undefeatable_style_active = class({})
 
 
function saito_undefeatable_style_active:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

 


function saito_undefeatable_style_active:OnSpellStart()
    
    local caster = self:GetCaster()
    StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})	
    Timers:CreateTimer(0.2, function()
    local ability = self
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")

    self.cast = ParticleManager:CreateParticle("particles/saito/saito_combo_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    Timers:CreateTimer(self:GetCastPoint(), function()
        ParticleManager:DestroyParticle(self.cast, false)
        ParticleManager:ReleaseParticleIndex(self.cast)
    
    
    end)
 
    local point = caster:GetAbsOrigin()  
 
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_lockerhit"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
 

    local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = stun_duration})     
        v:AddNewModifier(caster, self, "modifier_saito_combo_silence", {Duration = self:GetSpecialValueFor("silence_duration")})    
        v:EmitSound("saito_combo_kick")
        local pushback = Physics:Unit(v)
					v:PreventDI()
					v:SetPhysicsFriction(0)
					v:SetPhysicsVelocity((v:GetAbsOrigin() -  caster:GetAbsOrigin()):Normalized() * 2000)
					v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
					v:FollowNavMesh(false)

					Timers:CreateTimer(0.15, function()  
						v:PreventDI(false)
						v:SetPhysicsVelocity(Vector(0,0,0))
						v:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
						return 
					end)
    end 

end)
end

modifier_saito_combo_silence = class({})

function modifier_saito_combo_silence:CheckState()
    local state =   { 
    				[MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end
 
function modifier_saito_combo_silence:IsHidden() return false end
function modifier_saito_combo_silence:RemoveOnDeath() return true end