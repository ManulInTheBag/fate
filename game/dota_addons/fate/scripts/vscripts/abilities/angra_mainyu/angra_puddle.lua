LinkLuaModifier("modifier_angra_puddle", "abilities/angra_mainyu/angra_puddle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_puddle_debuff", "abilities/angra_mainyu/angra_puddle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_puddle_check", "abilities/angra_mainyu/angra_puddle", LUA_MODIFIER_MOTION_NONE)

angra_puddle = class({})

--[[function jeanne_trail:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = self:GetCaster():GetSecondsPerAttack()/1.2})

        return true
    end
end]]
function angra_puddle:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    --self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = 0.5})

    if not self.TrailTable then
        self.TrailTable = {}
    end

    --caster:EmitSound("Hero_Phoenix.FireSpirits.Launch")

    local trailDummy = CreateUnitByName("sight_dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
    trailDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
    trailDummy:SetDayTimeVisionRange(0)
    trailDummy:SetNightTimeVisionRange(0)
    --trailDummy:FaceTowards(self:GetCursorPosition())

    trailDummy:AddNewModifier(caster, self, "modifier_angra_puddle", {duration = duration})

    table.insert(self.TrailTable, trailDummy)

    for i = 1, #self.TrailTable do
        --PrintTable(self.TrailTable[i])
    end

end

function angra_puddle:DeathPuddle(spawn)

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    --self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = 0.5})

    if not self.TrailTable then
        self.TrailTable = {}
    end

    --caster:EmitSound("Hero_Phoenix.FireSpirits.Launch")

    local trailDummy = CreateUnitByName("sight_dummy_unit", spawn, false, nil, nil, caster:GetTeamNumber())
    trailDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
    trailDummy:SetDayTimeVisionRange(0)
    trailDummy:SetNightTimeVisionRange(0)
    --trailDummy:FaceTowards(self:GetCursorPosition())

    trailDummy:AddNewModifier(caster, self, "modifier_angra_puddle", {duration = duration})

    table.insert(self.TrailTable, trailDummy)

    for i = 1, #self.TrailTable do
        --PrintTable(self.TrailTable[i])
    end

end


modifier_angra_puddle = class({})

function modifier_angra_puddle:IsHidden()            return false end
function modifier_angra_puddle:IsDebuff()            return false end
function modifier_angra_puddle:IsPurgable()          return false end
function modifier_angra_puddle:IsPurgeException()    return false end
function modifier_angra_puddle:RemoveOnDeath()       return true end
function modifier_angra_puddle:OnCreated(args)
    if IsServer() then
        self.caster = self:GetCaster()
        self.parent  = self:GetParent()
        self.ability = self:GetAbility()
        self.origin = self:GetParent():GetAbsOrigin()
        self.radius = self.ability:GetSpecialValueFor("radius")
        self.army_counter = 0

        EmitSoundOnLocationWithCaster(self.origin, "Hero_VoidSpirit.Dissimilate.Portals", self.caster)

        self.index = ParticleManager:CreateParticle("particles/angra_jopa_pool.vpcf", PATTACH_WORLDORIGIN, nil) 
        ParticleManager:SetParticleControl(self.index, 0, self.origin)
        ParticleManager:SetParticleControl(self.index, 2, Vector(0, self:GetDuration()+0.25, 0))
        ParticleManager:SetParticleControl(self.index, 5, Vector(self.radius, self.radius, self.radius))
        
        self:StartIntervalThink(0.25)
        
    end
end

function modifier_angra_puddle:OnIntervalThink()
    if IsServer() then
        self.army_counter = self.army_counter + 1
        if self.army_counter >= 6 and self.caster.PuddleArmy then


            giveUnitDataDrivenModifier(self.caster, self.caster, "modifier_avenger_death_checker", {})
            local attackmove = {
            UnitIndex = nil,
            OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
            Position = nil
            }
            self.caster:EmitSound("Hero_Nevermore.Shadowraze")
            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControl(particle, 0, self.parent:GetAbsOrigin()) 
            Timers:CreateTimer( 0.75, function()
                ParticleManager:DestroyParticle( particle, false )
                ParticleManager:ReleaseParticleIndex( particle )
            end)


            local remain = CreateUnitByName("avenger_remain", self.parent:GetAbsOrigin(), true, nil, nil, self.parent:GetTeamNumber()) 
            --remain:SetControllableByPlayer(caster:GetPlayerID(), true)
            remain:SetOwner(self.caster:GetPlayerOwner():GetAssignedHero())
            LevelAllAbility(remain)
            FindClearSpaceForUnit(remain, remain:GetAbsOrigin(), true)
            remain:FindAbilityByName("avenger_remain_passive"):SetLevel(self.caster:FindAbilityByName("avenger_unlimited_remains"):GetLevel())
            remain:AddNewModifier(self.caster, nil, "modifier_kill", {duration = 24})
            Timers:CreateTimer(3.0, function() 
                if not remain:IsAlive() then return end
                attackmove.UnitIndex = remain:entindex()
                attackmove.Position = remain:GetOrigin() + RandomVector(1000) 
                ExecuteOrderFromTable(attackmove)
                return 3.0
            end)

            self.army_counter = 0

        end
        local enemies2 = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        local allies = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for _, ally in pairs(allies) do
            if ally:GetUnitName() == "npc_dota_hero_vengefulspirit" and not ally.healcd then
                ally:Heal(self:GetAbility():GetSpecialValueFor("heal_per_tick"), ally)
                ally.healcd = true
                Timers:CreateTimer(0.15, function()
                    ally.healcd = false
                
                end)
            end
        end
        for _, enemy in pairs(enemies2) do
            local stackcount = 0
            if enemy.PuddleChecker or enemy:HasModifier("modifier_puddle_check") then -- Лужи стакаются частично Злодемон ебись сам
                return
            end
            local damage = self:GetAbility():GetSpecialValueFor("damage")
            DoDamage(self.caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            enemy.PuddleChecker = true
            Timers:CreateTimer(0.15, function()
                enemy.PuddleChecker = false
            end)
            if enemy:HasModifier("modifier_puddle_debuff") then
                stackcount = enemy:GetModifierStackCount("modifier_puddle_debuff", self.caster)
            end
            enemy:AddNewModifier(self.caster, self.ability,"modifier_puddle_debuff", {duration = 5})
            if stackcount < 100 then
                enemy:FindModifierByName("modifier_puddle_debuff"):SetStackCount(stackcount + 10)
            else
                giveUnitDataDrivenModifier(self.caster, enemy, "locked", self:GetAbility():GetSpecialValueFor("lock_duration"))
                enemy:AddNewModifier(self.caster, self:GetAbility(), "modifier_puddle_check", {duration = self.ability:GetSpecialValueFor("puddle_cooldown")})
                
                if self.caster.PuddleArmy then
                    giveUnitDataDrivenModifier(self.caster, enemy , "revoked", self:GetAbility():GetSpecialValueFor("revoke_duration"))
                    LoopOverPlayers(function(player, playerID, playerHero)
					if playerHero == enemy then
						CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="angra_revoke"})
						end
				   end)
                end
                enemy:RemoveModifierByName("modifier_puddle_debuff")
            end
        end
    end
end

function modifier_angra_puddle:OnDestroy()
    if IsServer() then

        ParticleManager:DestroyParticle(self.index, true)
        ParticleManager:ReleaseParticleIndex(self.index)

        self.parent:ForceKill(false)
        UTIL_Remove(self.parent)
    end


end

modifier_puddle_debuff = class({})

-- function modifier_puddle_debuff:CheckState()
--     return { [MODIFIER_STATE_SILENCED] = false,
--              [MODIFIER_STATE_ROOTED] = true }
-- end

function modifier_puddle_debuff:IsHidden() return false end
function modifier_puddle_debuff:IsDebuff() return true end
function modifier_puddle_debuff:RemoveOnDeath() return true end

function modifier_puddle_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_puddle_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -25
end
 
function modifier_puddle_debuff:GetEffectName()
    return "particles/units/heroes/hero_clinkz/clinkz_tar_bomb_debuff.vpcf"
end
function modifier_puddle_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end


modifier_puddle_check = class({})

function modifier_puddle_check:IsHidden() return false end
function modifier_puddle_check:IsDebuff() return true end