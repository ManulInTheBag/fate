ozy_piramid_barrier = class({})
LinkLuaModifier("modifier_barrier_new","modifiers/modifier_barrier_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_piramid_barrier_particle","abilities/ozy/ozy_piramid_barrier", LUA_MODIFIER_MOTION_NONE)


IsNotNull = function(hScript)
    local sType = type(hScript)
    if sType ~= "nil" then
        if sType == "table" 
            and type(hScript.IsNull) == "function" then
            return not hScript:IsNull()
        end
        return true
    end
    return false
end
function ozy_piramid_barrier:OptionalDestroy(parent)
    if IsServer() then
        Timers:CreateTimer(FrameTime() * 2, function() 
            if not IsNotNull(parent:FindModifierByNameAndCaster("modifier_barrier_new", self:GetCaster())) then
                parent:RemoveModifierByName("modifier_ozy_piramid_barrier_particle")
            end

        end)
    end
end
function ozy_piramid_barrier:OnSpellStart()
	local targetPoint = self:GetCursorPosition()
	local caster = self:GetCaster()
	local shield_amount = self:GetSpecialValueFor("barrier")

	caster:AddNewModifier(caster, self, "modifier_ozy_piramid_barrier_particle", { Duration =  self:GetSpecialValueFor("duration")})            
	caster:AddNewModifier(caster, self, "modifier_barrier_new", { Duration =  self:GetSpecialValueFor("duration"), decreaseDamageOnProck = 0, beforeBScroll = true, ShouldEndChannel = true, debuff_immune = true, shield_amount =shield_amount, HasCounter = false })            
    caster:SetHullRadius(550)
    
    EmitSoundOn("ozy_barrier_cast", caster)
end

function ozy_piramid_barrier:OnChannelFinish()
	local caster = self:GetCaster()

	caster:RemoveModifierByNameAndCaster("modifier_barrier_new", caster)
	caster:RemoveModifierByName("modifier_ozy_piramid_barrier_particle")
    caster:SetHullRadius(400)
end


modifier_ozy_piramid_barrier_particle = class({})

function modifier_ozy_piramid_barrier_particle:OnCreated(table)
    if IsServer() then
        EmitSoundOn("ozy_piramid_barrier", self:GetParent())
    
    self:StartIntervalThink(0.1)
    end

end

function modifier_ozy_piramid_barrier_particle:OnIntervalThink()
    local caster = self:GetCaster()
    local tEnemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(tEnemies) do
        if v:GetUnitName() ~= "ozy_piramid" then
						local Distance = (v:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
						local knockbackDistance = 0
						local knockbackHeight = 0
						if Distance<= 600 then
							knockbackDistance = 700 - Distance
							knockbackHeight = knockbackDistance * 1.5
						end
			--v:RemoveModifierByName("modifier_knockback")
	
                local knockback1 = { should_stun = false,
                                        knockback_duration = 0.2,
                                        duration = 0.2,
                                        knockback_distance = knockbackDistance ,
                                        knockback_height = knockbackHeight,
                                        center_x =caster:GetAbsOrigin().x,
                                        center_y = caster:GetAbsOrigin().y,
                                        center_z = caster:GetAbsOrigin().z }
                    v:AddNewModifier(hCaster, self, "modifier_knockback", knockback1)
        end
    end



end

function modifier_ozy_piramid_barrier_particle:IsHidden() return true end
function modifier_ozy_piramid_barrier_particle:IsDebuff() return false end



function modifier_ozy_piramid_barrier_particle:GetEffectName()
    return "particles/ozy/piramid/piramid_barrier_new.vpcf"
end
function modifier_ozy_piramid_barrier_particle:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_ozy_piramid_barrier_particle:OnDestroy()
    StopSoundOn("ozy_piramid_barrier", self:GetParent())
end
