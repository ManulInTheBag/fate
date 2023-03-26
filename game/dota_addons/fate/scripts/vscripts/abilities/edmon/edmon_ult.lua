LinkLuaModifier("modifier_edmon_ult", "abilities/edmon/edmon_ult", LUA_MODIFIER_MOTION_NONE)

edmon_ult = class({})

function edmon_ult:GetAOERadius()
	return 500
end

function edmon_ult:GetCastRange()
	if self:GetCaster():HasModifier("modifier_edmon_escape") then
		return 1000
	end
	return 700
end

function edmon_ult:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if (not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) )) or hCaster:HasModifier("modifier_edmon_escape") then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function edmon_ult:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
end

function edmon_ult:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local interval = self:GetSpecialValueFor("interval")
	local count = 0
	local radius = self:GetSpecialValueFor("radius")
    --local target = self:GetCursorTarget()
	local origin = self:GetCursorPosition()
	local damage = self:GetSpecialValueFor("damage") + (caster.HellfireAcquired and caster:GetAgility() * self:GetSpecialValueFor("agi_scaling") or 0)
    --if IsSpellBlocked(target) then return end
	caster:AddNewModifier(caster, self, "modifier_edmon_ult", {duration = duration})

	EmitGlobalSound("edmon_r"..math.random(1,2))

	Timers:CreateTimer(function()
        if count < duration and caster and caster:IsAlive() then
            --if target then
            --    origin = target:GetAbsOrigin()
            --end
            local angle = RandomInt(0, 360)
            local startLoc = GetRotationPoint(origin,RandomInt(radius, radius),angle)
            local endLoc = GetRotationPoint(origin,RandomInt(radius, radius),angle + RandomInt(120, 240))
            local fxIndex = ParticleManager:CreateParticle( "particles/custom/edmond/edmond_enfer_slash.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl( fxIndex, 0, startLoc)
            ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,50))
            --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance_a.vpcf",PATTACH_ABSORIGIN,caster,2)
            --ParticleManager:SetParticleControl( p, 0, startLoc)
            --ParticleManager:SetParticleControl( p, 2, endLoc + Vector(0,0,50))
            local unitGroup = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
            for i = 1, #unitGroup do
				DoDamage(caster, unitGroup[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                --caster:PerformAttack( unitGroup[i], true, true, true, true, false, false, true )
			end
            --FindClearSpaceForUnit(caster,endLoc,true)
            for k,v in pairs(unitGroup) do
                --CauseDamage(caster,unitGroup,damage,damageType,ability3)
                --caster:PerformAttack(v,true,true,true,false,false,false,true)
            end
            --if #unitGroup == 0 then
                caster:EmitSound("Tsubame_Focus")
            --end
            count = count + interval
            return interval
        end
        --FindClearSpaceForUnit(caster,origin,true)
    end)
end

modifier_edmon_ult = class({})
function modifier_edmon_ult:IsHidden() return true end
function modifier_edmon_ult:IsDebuff() return false end
function modifier_edmon_ult:IsPurgable() return false end
function modifier_edmon_ult:IsPurgeException() return false end
function modifier_edmon_ult:RemoveOnDeath() return true end
function modifier_edmon_ult:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_edmon_ult:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_edmon_ult:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        --[MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_STUNNED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                        [MODIFIER_STATE_UNTARGETABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                        [MODIFIER_STATE_INVULNERABLE] = true,
                    }
    return state
end
function modifier_edmon_ult:OnCreated()
	if IsServer() then
		self:GetParent():AddEffects(EF_NODRAW)
	end
end
function modifier_edmon_ult:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveEffects(EF_NODRAW)
	end
end