lancelot_vajra = class({})

LinkLuaModifier("modifier_vajra_slow", "abilities/lancelot/modifier/modifier_vajra_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vajra_root", "abilities/lancelot/modifier/modifier_vajra_root", LUA_MODIFIER_MOTION_NONE)

function lancelot_vajra:OnSpellStart()
    local caster = self:GetCaster()
    local targetPoint = self:GetCursorPosition()
    local delay = self:GetSpecialValueFor("lighting_delay")
    local slowRadius = self:GetSpecialValueFor("slow_radius")
    local rootRadius = self:GetSpecialValueFor("root_radius")
    local damage = self:GetSpecialValueFor("damage")

    local lightning_part = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_blink_start.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(lightning_part, 0, targetPoint)
    --ParticleManager:SetParticleControl(fireFx, 1, Vector(duration,0,0))
    --particles/econ/items/zeus/arcana_chariot/zeus_arcana_blink_start.vpcf
    --particles/econ/items/zeus/arcana_chariot/zeus_arcana_loadout_start_core.vpcf
    --particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start_strike.vpcf
    
    caster:EmitSound("Hero_Zuus.GodsWrath.PreCast")

    Timers:CreateTimer(delay, function()  
        local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, slowRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        for k, v in pairs(targets) do
            self:StrikeOuterUnits(v)
        end 

        local lightning_impact_part = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start_strike.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(lightning_impact_part, 0, targetPoint)

        targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, rootRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        for k, v in pairs(targets) do
            self:StrikeCenterUnits(v, damage)
        end 

        return 
    end)
end

function lancelot_vajra:StrikeCenterUnits(target, damage)
    target:AddNewModifier(self:GetCaster(), self, "modifier_vajra_root", {duration = self:GetSpecialValueFor("root_duration")})

    DoDamage(self:GetCaster(), target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false) 
    target:EmitSound("Hero_Zuus.GodsWrath")
end

function lancelot_vajra:StrikeOuterUnits(target)
    target:AddNewModifier(self:GetCaster(), self, "modifier_vajra_slow", {duration = self:GetSpecialValueFor("slow_duration"),
                                                                          slowPerc = self:GetSpecialValueFor("slow_percentage")})

    target:EmitSound("Hero_Zuus.GodsWrath.Target")
end