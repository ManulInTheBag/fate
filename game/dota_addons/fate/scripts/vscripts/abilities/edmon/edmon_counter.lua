LinkLuaModifier("modifier_edmon_counter", "abilities/edmon/edmon_counter", LUA_MODIFIER_MOTION_NONE)

edmon_counter = class({})

function edmon_counter:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_edmon_counter", {duration = self:GetSpecialValueFor("duration")})
end

modifier_edmon_counter = class({})

function modifier_edmon_counter:OnCreated(keys)
    local caster = self:GetParent()
    self.ability = self:GetAbility()
    self.SlashCount = self.ability:GetSpecialValueFor("slash_count")
    self.Threshold = self.ability:GetSpecialValueFor("threshold")

    if IsServer() then
        self.particle = ParticleManager:CreateParticle( "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
        ParticleManager:SetParticleControl(self.particle, 1, Vector( 100, 100, 100 ) )
    end
end

function modifier_edmon_counter:OnRefresh(args)
    self:DestroyAttachedParticle()
    self:OnCreated(args)
end

function modifier_edmon_counter:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
 
    return funcs
end

function modifier_edmon_counter:CheckState()
    return self.State
end

function modifier_edmon_counter:FilterUnits(caster, target)    
    local filter = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

    if (filter == UF_SUCCESS) then
        if ((caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() < 1500) then
            return true
        end
    end

    return false
end

function modifier_edmon_counter:OnTakeDamage(args)
    --for k,v in pairs(args) do print(k,v) end
    if IsServer() then 
        local caster = self:GetParent()
        local target = args.attacker

        if args.unit ~= self:GetParent() then return end

        local ability = self:GetAbility()
        local damageTaken = args.original_damage
        local threshold = self.Threshold
        local slashcount = self.SlashCount

        if damageTaken >= threshold and caster:GetHealth() ~= 0 and self:FilterUnits(caster, target) then
        	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
            local position = target:GetAbsOrigin() - diff * 100

        	local chTarget = CreateUnitByName("hrunt_illusion", self:GetCaster():GetAbsOrigin(), true, nil, nil, self:GetCaster():GetTeamNumber())
			chTarget:SetModel("models/updated_by_seva_and_hudozhestvenniy_film_spizdili/edmon/edmon.vmdl")
		    chTarget:SetOriginalModel("models/updated_by_seva_and_hudozhestvenniy_film_spizdili/edmon/edmon.vmdl")
		    chTarget:SetModelScale(1.15)
		    local unseen = chTarget:FindAbilityByName("dummy_unit_passive")
		    unseen:SetLevel(1)
		    chTarget:SetForwardVector(diff)

		    StartAnimation(chTarget, {duration=2, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})

		    Timers:CreateTimer(2, function()
				if IsValidEntity(chTarget) and not chTarget:IsNull() then
		            chTarget:ForceKill(false)
		            chTarget:AddEffects(EF_NODRAW)
		    	end
		    end)

		    caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0}) 
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.5)

		    local slashCounter = 0
			Timers:CreateTimer(0.5, function()
				if slashCounter == 0 then caster:SetModel("models/development/invisiblebox.vmdl") end
				if slashCounter == 5 or not caster:IsAlive() or not target:IsAlive() then caster:SetModel("models/updated_by_seva_and_hudozhestvenniy_film_spizdili/edmon/edmon.vmdl") return end
				caster:PerformAttack( target, true, true, true, true, false, false, false )
				CreateSlashFx(caster, target:GetAbsOrigin()+RandomVector(400), target:GetAbsOrigin()+RandomVector(400))
				caster:SetAbsOrigin(target:GetAbsOrigin()+RandomVector(400))
				EmitGlobalSound("FA.Quickdraw") 

				slashCounter = slashCounter + 1
				return 0.2-slashCounter*0.03
			end)

			Timers:CreateTimer(1.0, function()
				if caster:IsAlive() and target:IsAlive() then
					caster:RemoveModifierByName("jump_pause")
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
				end
			end)

            FindClearSpaceForUnit(caster, position, true)             

            target:EmitSound("Sasaki_Counter_Success_" .. math.random(1,2))
            
            Timers:CreateTimer(0.033, function()                
                HardCleanse(caster)
                return
            end)
            
            EmitGlobalSound("FA.Quickdraw")
            self:Destroy()
        end
    end
end

function modifier_edmon_counter:OnDestroy()
    self:DestroyAttachedParticle()
end

function modifier_edmon_counter:DestroyAttachedParticle()
    if IsServer() then
        if self.particle ~= nil then
            ParticleManager:DestroyParticle( self.particle, false )
            ParticleManager:ReleaseParticleIndex( self.particle )
        end
    end
end

-----------------------------------------------------------------------------------
function modifier_edmon_counter:GetEffectName()
    return "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf"
end

function modifier_edmon_counter:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_edmon_counter:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_edmon_counter:IsPurgable()
    return false
end

function modifier_edmon_counter:IsDebuff()
    return false
end

function modifier_edmon_counter:RemoveOnDeath()
    return true
end