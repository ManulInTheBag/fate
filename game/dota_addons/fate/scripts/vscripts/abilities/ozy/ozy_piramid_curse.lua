ozy_piramid_curse = class({})
LinkLuaModifier("modifier_ozy_piramid_curse","abilities/ozy/ozy_piramid_curse", LUA_MODIFIER_MOTION_NONE)


function ozy_piramid_curse:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

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


function ozy_piramid_curse:OnSpellStart()
	local targetPoint = self:GetCursorPosition()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local EruptionPreParticle = ParticleManager:CreateParticle("particles/ozy/piramid/ozy_piramid_curse_precast.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl(EruptionPreParticle, 0, targetPoint)
	ParticleManager:SetParticleControl(EruptionPreParticle, 1, Vector(radius, 1, 1))

	local EruptionPreParticlePiramid = ParticleManager:CreateParticle("particles/ozy/piramid/ozy_scale.vpcf", PATTACH_OVERHEAD_FOLLOW, caster )
	ParticleManager:SetParticleControl(EruptionPreParticlePiramid, 3, caster:GetAbsOrigin())

	Timers:CreateTimer(1, function() 
        caster:EmitSound("merlin_illusion")
		local EruptionParticle = ParticleManager:CreateParticle("particles/ozy/piramid/ozy_piramid_curse_blast.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl(EruptionParticle, 0, targetPoint)
		ParticleManager:SetParticleControl(EruptionParticle, 1, Vector(radius * 1.2, radius, radius))
		ParticleManager:DestroyParticle(EruptionPreParticle, false)
		ParticleManager:ReleaseParticleIndex(EruptionPreParticle)
		Timers:CreateTimer(1, function() 
			ParticleManager:DestroyParticle(EruptionParticle, true)
			ParticleManager:ReleaseParticleIndex(EruptionParticle)
		end)
		
        local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        for k,v in pairs(targets) do
            v:AddNewModifier(caster, self, "modifier_ozy_piramid_curse", { Duration =  self:GetSpecialValueFor("duration")})            
         end

    end)
end


modifier_ozy_piramid_curse = class({})

function modifier_ozy_piramid_curse:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS


           }
end




function modifier_ozy_piramid_curse:GetEffectName()
    return "particles/ozy/piramid/curse_debuff_enemy.vpcf"
end
function modifier_ozy_piramid_curse:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end
function modifier_ozy_piramid_curse:IsDebuff() return true end
function modifier_ozy_piramid_curse:OnCreated()
	self.debuffSTATValue = self:GetAbility():GetSpecialValueFor("stat_debuff")
	self.debuffArmorValue = self:GetAbility():GetSpecialValueFor("armor_debuff")
	self.debuffMRValue = self:GetAbility():GetSpecialValueFor("magres_debuff")
	self.debuffHealthValue = self:GetAbility():GetSpecialValueFor("health_debuff")
    self:StartIntervalThink(0.5)
end
function modifier_ozy_piramid_curse:OnIntervalThink()
    if(not IsServer() ) then return end
    local caster = self:GetCaster()
    local target = self:GetParent()
    local damage = self:GetAbility():GetSpecialValueFor("damage")

    DoDamage(caster, target, damage * 0.5, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)



end



function modifier_ozy_piramid_curse:GetModifierBonusStats_Strength()
	return  -self.debuffSTATValue
end
function modifier_ozy_piramid_curse:GetModifierBonusStats_Agility()
	return  -self.debuffSTATValue
end

function modifier_ozy_piramid_curse:GetModifierPhysicalArmorBonus()
	return  -self.debuffArmorValue
end
function modifier_ozy_piramid_curse:GetModifierMagicalResistanceBonus()
	return  -self.debuffMRValue
end
function modifier_ozy_piramid_curse:GetModifierHealthBonus()
	return  -self.debuffHealthValue
end