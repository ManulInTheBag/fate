LinkLuaModifier("modifier_okita_zekken", "abilities/okita/okita_zekken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_zekken_anim", "abilities/okita/okita_zekken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_zekken_cd", "abilities/okita/modifiers/modifier_okita_zekken_cd", LUA_MODIFIER_MOTION_NONE)

okita_zekken = class({})

function okita_zekken:OnAbilityPhaseStart()
    EmitGlobalSound("Okita.Precombo")
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="vergil_prepare"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    return true
end

function okita_zekken:OnAbilityPhaseInterrupted()
    StopGlobalSound("Okita.Precombo")
end

function okita_zekken:OnSpellStart()
	local caster = self:GetCaster()
	local init_origin = caster:GetAbsOrigin()
    local target = self:GetCursorTarget()
    local origin = target:GetAbsOrigin()
    local ability = self
    local interval = ability:GetSpecialValueFor("interval")
    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")
    local range = self:GetSpecialValueFor("beam_distance")
    local bradius = self:GetSpecialValueFor("beam_radius")
    local ability_cooldown = caster:FindAbilityByName("okita_sandanzuki")
    ability_cooldown:StartCooldown(ability_cooldown:GetCooldown(1))

    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="vergil_to_die"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    
    local damage = ability:GetSpecialValueFor("damage") + (caster.IsKikuIchimonjiAcquired and caster:GetAgility()*self:GetSpecialValueFor("kiku_agi_ratio") or 0)
    local count = 0

    caster:AddNewModifier(caster, self, "modifier_okita_zekken", {duration = 3.9})
    caster:AddNewModifier(caster, self, "modifier_okita_zekken_cd", {duration = ability:GetCooldown(1)})

    --EmitGlobalSound("Okita.Precombo")
    --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance.vpcf",PATTACH_ABSORIGIN,caster,2)
    --ParticleManager:SetParticleControl( p, 0, caster:GetAbsOrigin())
    --ParticleManager:SetParticleControl( p, 2, point)
    Timers:CreateTimer(function()
        if count < duration and caster and caster:IsAlive() then
            local angle = RandomInt(0, 360)
            local startLoc = GetRotationPoint(origin,RandomInt(300, 600),angle)
            local endLoc = GetRotationPoint(origin,RandomInt(300, 600),angle + RandomInt(120, 240))
            local fxIndex = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl( fxIndex, 0, startLoc)
            ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,50))
            --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance_a.vpcf",PATTACH_ABSORIGIN,caster,2)
            --ParticleManager:SetParticleControl( p, 0, startLoc)
            --ParticleManager:SetParticleControl( p, 2, endLoc + Vector(0,0,50))
            local unitGroup = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
            for i = 1, #unitGroup do
				--DoDamage(caster, unitGroup[i], damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
                caster:PerformAttack( unitGroup[i], true, true, true, true, false, false, true )
			end
            FindClearSpaceForUnit(caster,endLoc,true)
            for k,v in pairs(unitGroup) do
                --CauseDamage(caster,unitGroup,damage,damageType,ability3)
                --caster:PerformAttack(v,true,true,true,false,false,false,true)
            end
            --if #unitGroup == 0 then
                caster:EmitSound("Tsubame_Focus")
            --end
            count = count + interval
            return interval
        elseif caster and caster:IsAlive() then
            FindClearSpaceForUnit(caster,init_origin,true)
            EmitGlobalSound("Okita.Zekken")
            Timers:CreateTimer(1.0, function()
            	if caster and caster:IsAlive() then
            		caster:AddNewModifier(caster, self, "modifier_okita_zekken_anim", {duration = 0.2})
            	end
            end)
            Timers:CreateTimer(1.35, function()
            	if caster and caster:IsAlive() then
            		EmitGlobalSound("karna_vasavi_explosion")
            	end
            end)
   			Timers:CreateTimer(1.4, function()
   				if caster and caster:IsAlive() then	
   				local smg = 
    			{
       				Ability = self,
        			--EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
        			iMoveSpeed = 5000,
        			vSpawnOrigin = caster:GetAbsOrigin(),
        			fDistance = range,
        			fStartRadius = bradius,
        			fEndRadius = bradius,
        			Source = caster,
        			bHasFrontalCone = true,
        			bReplaceExisting = true,
        			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        			iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        			fExpireTime = GameRules:GetGameTime() + 2.0,
       				bDeleteOnHit = false,
        			vVelocity = caster:GetForwardVector() * 5000
    			}
    			ProjectileManager:CreateLinearProjectile(smg)
    			AddFOWViewer(2,caster:GetAbsOrigin(), 50, 1, false)
    			AddFOWViewer(3,caster:GetAbsOrigin(), 50, 1, false)
    			local beam_fx = ParticleManager:CreateParticle("particles/okita/okita_zekken_beam.vpcf", PATTACH_ABSORIGIN, caster)
    			ParticleManager:SetParticleControl(beam_fx, 0, caster:GetAbsOrigin() + Vector(0,0,100))
    			ParticleManager:SetParticleControl(beam_fx, 1, caster:GetAbsOrigin() + Vector(0,0,100))
    			ParticleManager:SetParticleControl(beam_fx, 3, caster:GetAbsOrigin() + caster:GetForwardVector()*range + Vector(0,0,100))
    			Timers:CreateTimer(0.2, function()
    				ParticleManager:DestroyParticle(beam_fx, true)
    			end)
    			end
    		end)
            --local p = CreateParticle("particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_end.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster,3)
            --ParticleManager:SetParticleControlEnt( p, 2, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
            --ParticleManager:SetParticleControlEnt( p, 3, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
        end
    end)
end

function okita_zekken:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

    --print("hit", hTarget)
	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("beam_damage") + (hCaster.IsKikuIchimonjiAcquired and self:GetSpecialValueFor("beam_kiku_agi_ratio") or 0)*hCaster:GetAgility()

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

modifier_okita_zekken = class({})
function modifier_okita_zekken:IsHidden() return true end
function modifier_okita_zekken:IsDebuff() return false end
function modifier_okita_zekken:IsPurgable() return false end
function modifier_okita_zekken:IsPurgeException() return false end
function modifier_okita_zekken:RemoveOnDeath() return true end
function modifier_okita_zekken:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_zekken:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_zekken:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                        [MODIFIER_STATE_UNTARGETABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                        [MODIFIER_STATE_INVULNERABLE] = true,
                    }
    return state
end
function modifier_okita_zekken:OnCreated()
	if IsServer() then
		self.target = self:GetAbility():GetCursorTarget()
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_okita_zekken:OnIntervalThink()
	self:GetParent():FaceTowards(self.target:GetAbsOrigin())
end

modifier_okita_zekken_anim = class({})

function modifier_okita_zekken_anim:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    				MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
    return func
end
function modifier_okita_zekken_anim:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end
function modifier_okita_zekken_anim:GetOverrideAnimationRate()
    return 0.5
end