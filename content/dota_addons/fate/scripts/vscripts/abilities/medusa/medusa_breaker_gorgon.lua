medusa_breaker_gorgon = class({})

LinkLuaModifier("modifier_breaker_gorgon", "abilities/medusa/modifiers/modifier_breaker_gorgon", LUA_MODIFIER_MOTION_NONE)

function medusa_breaker_gorgon:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function medusa_breaker_gorgon:OnSpellStart()
	local caster = self:GetCaster()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)

	caster:EmitSound("Medusa_Skill1")
	for _,v in pairs(targets) do            
        if not v:IsMagicImmune() then
            v:AddNewModifier(caster, self, "modifier_breaker_gorgon", { Duration = self:GetSpecialValueFor("slow_duration"),
            															SlowPerc = self:GetSpecialValueFor("slow_perc"),
            															TurnRateSlow = self:GetSpecialValueFor("turn_slow"),
            															ExtraSlow = self:GetSpecialValueFor("stack_slow") })
        end
    end

    caster:AddNewModifier(caster, self, "modifier_breaker_gorgon_self", { Duration = self:GetSpecialValueFor("slow_duration"),
	            														  SlowPerc = self:GetSpecialValueFor("slow_perc"),
	            														  TurnRateSlow = self:GetSpecialValueFor("turn_slow"),
	            														  ExtraSlow = self:GetSpecialValueFor("stack_slow") })
end