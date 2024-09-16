LinkLuaModifier("modifier_jeanne_lagron_block", "abilities/jeanne_alter/jeanne_lagron", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lagron_damage_checker", "abilities/jeanne_alter/jeanne_lagron", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lagron_damage_checker_enemy", "abilities/jeanne_alter/jeanne_lagron", LUA_MODIFIER_MOTION_NONE)

jeanne_lagron = class({})

function jeanne_lagron:GetBehavior()
    if self:GetCaster().AvengerAcquired then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE--+ DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE --+ DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

function jeanne_lagron:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

--[[function jeanne_lagron:GetIntrinsicModifierName()
    return "modifier_lagron_damage_checker"
end]]

function jeanne_lagron:OnSpellStart()
	local caster = self:GetCaster()
	local block = self:GetSpecialValueFor("block_duration")
    local target_point = self:GetCursorPosition()
    StartAnimation(caster, {duration=block + 0.5, activity=ACT_DOTA_CAST_ABILITY_6, rate=0.2})

    caster:EmitSound("lagron")

	caster:AddNewModifier(caster, self, "modifier_jeanne_lagron_block", {duration = block})
    Timers:CreateTimer(0.2, function()
		local point_particle = ParticleManager:CreateParticle("particles/jeanne_alter/lagron_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
	 
		ParticleManager:SetParticleControl(point_particle, 0,  target_point )
		ParticleManager:SetParticleControl(point_particle, 1,  Vector(350,0,0) )
 
		Timers:CreateTimer(1.0, function()
			ParticleManager:DestroyParticle(point_particle, false)
			ParticleManager:ReleaseParticleIndex(point_particle)
		 
		end)
		return
	end)
    caster:FaceTowards(self:GetCursorPosition())
end

function jeanne_lagron:LaunchLagronProjectile(checker, point, stored_damage)

    local tExtraData = { damage = stored_damage*self:GetSpecialValueFor("stored_damage_perc")/100 + self:GetSpecialValueFor("base_damage") }

    local caster = self:GetCaster()

    if not caster:IsAlive() then return end

    if not checker then
        local hTarget = CreateUnitByName("hrunt_illusion", point, true, nil, nil, caster:GetOpposingTeamNumber())
        hTarget:SetModel("models/development/invisiblebox.vmdl")
        hTarget:SetOriginalModel("models/development/invisiblebox.vmdl")
        hTarget:SetModelScale(1)
        hTarget:SetBaseMagicalResistanceValue(0)
        hTarget.IsHruntDummy = true
        local unseen = hTarget:FindAbilityByName("dummy_unit_passive")
        unseen:SetLevel(1)
        Timers:CreateTimer(0.033, function()
            hTarget:SetBaseMaxHealth(9999999)
            hTarget:SetMaxHealth(9999999)
            hTarget:ModifyHealth(9999999, nil, false, 0)
        end)
        Timers:CreateTimer(10, function()
            if IsValidEntity(hTarget) and not hTarget:IsNull() then 
                hTarget:ForceKill(false)
                hTarget:AddEffects(EF_NODRAW)
                --illusion:SetAbsOrigin(Vector(10000,10000,0))
            end
        end)
        point = hTarget
    end
    local tProjectile = {
        Target = point,
        Source = caster,
        Ability = self,
        level = -1,
        --EffectName = "particles/jeanne_alter/grimstroke_darkartistry_proj.vpcf",
        iMoveSpeed = 6000,
        vSourceLoc = caster:GetAbsOrigin(),
        bDodgeable = false,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        ExtraData = tExtraData
    }

    FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
end

function jeanne_lagron:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    local fTargetDamage = tData["damage"]
    local fStun = self:GetSpecialValueFor("stun_duration")
    local fRadius = self:GetSpecialValueFor("radius")

    AddFOWViewer(hCaster:GetTeamNumber(), vLocation, fRadius, fStun, false)
    AddFOWViewer(hCaster:GetOpposingTeamNumber(), vLocation, 10, fStun, false)

    Timers:CreateTimer(FrameTime(), function()
        hTarget:EmitSound("lagron_sfx")
    end)

    for i = 1,3 do
        for j = 1,3 do
            local explosionParticleIndex = ParticleManager:CreateParticle( "particles/jeanne_alter/sf_fire_arcana_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
            ParticleManager:SetParticleControl( explosionParticleIndex, 0, hTarget:GetAbsOrigin() + Vector(-200 + i*100, -200 + j*100, 0) )
        end
    end
    --ParticleManager:SetParticleControl( explosionParticleIndex, 1, Vector( fRadius, fRadius, 0 ) )
    
    local targets = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, fRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(targets) do
        if IsNotNull(v) then
            v:AddNewModifier(hCaster, v, "modifier_stunned", {Duration = fStun})
            DoDamage(hCaster, v, fTargetDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            
            ApplyAirborneOnly(v, 3000, 0.2, 1500)
            Timers:CreateTimer(0.2, function()
                v:SetAbsOrigin(GetGroundPosition(v:GetAbsOrigin(),v))
            end)
        end
    end
end

modifier_jeanne_lagron_block = class({})

function modifier_jeanne_lagron_block:IsHidden() return false end
function modifier_jeanne_lagron_block:IsDebuff() return false end
function modifier_jeanne_lagron_block:IsPurgable() return false end
function modifier_jeanne_lagron_block:IsPurgeException() return false end
function modifier_jeanne_lagron_block:RemoveOnDeath() return true end
function modifier_jeanne_lagron_block:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_jeanne_lagron_block:DeclareFunctions()
    local func = {  --MODIFIER_PROPERTY_AVOID_DAMAGE,
                --MODIFIER_EVENT_ON_TAKEDAMAGE
            }
    return func
end

--[[function modifier_jeanne_lagron_block:GetModifierAvoidDamage(keys)
    if IsServer() then
        self.stored_damage = self.stored_damage + keys.damage
        return 1
    end
end]]

function modifier_jeanne_lagron_block:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end

        hTarget = self:GetParent()
        previousHealth = self.hp
        local return_percentage = (self.ability:GetSpecialValueFor("return_percentage") + (self:GetParent().AvengerAcquired and 10 or 0))/100
        if (previousHealth - args.damage*(1 - return_percentage) > 0) then
            hTarget:SetHealth(previousHealth - args.damage*(1 - return_percentage))
        end
        self.stored_damage = self.stored_damage + args.damage*return_percentage
    end
end

function modifier_jeanne_lagron_block:OnCreated()
    if IsServer() then
        self.parent = self:GetParent()
        self.ability = self:GetAbility()
        --self.target = self.ability:GetCursorTarget()
        self.point = self.ability:GetCursorPosition()
        self.checker = false

        if (self.point - self.parent:GetAbsOrigin()):Length2D() > self.ability:GetSpecialValueFor("cast_range") then
            self.point = self.parent:GetAbsOrigin() + (((self.point - self.parent:GetAbsOrigin()):Normalized()) * self.ability:GetSpecialValueFor("cast_range"))
        end

        self.fx = ParticleManager:CreateParticle("particles/jeanne_alter/jeanne_alter_armor.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.fx, 0,  self.parent:GetAbsOrigin() )
        ParticleManager:SetParticleControl(self.fx, 1,  self.parent:GetAbsOrigin() )
        self:AddParticle(self.fx, false, false, -1, false, false)

        --[[if self.target and self.target:HasModifier("modifier_lagron_damage_checker_enemy") then
            self.checker = true
            self.point = self.target
        end]]
        self.stored_damage = 0
        self.hp = self.parent:GetHealth()
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_jeanne_lagron_block:OnIntervalThink()
    if IsServer() then
        self.hp = self.parent:GetHealth()
    end
end

function modifier_jeanne_lagron_block:OnDestroy()
    if IsServer() then
        self.ability:LaunchLagronProjectile(self.checker, self.point, self.stored_damage)
    end
end

modifier_lagron_damage_checker = class({})

function modifier_lagron_damage_checker:DeclareFunctions()
    return { --MODIFIER_EVENT_ON_TAKEDAMAGE
     }
end

function modifier_lagron_damage_checker:IsHidden() return true end
function modifier_lagron_damage_checker:IsDebuff() return false end
function modifier_lagron_damage_checker:IsPurgable() return false end
function modifier_lagron_damage_checker:IsPurgeException() return false end
function modifier_lagron_damage_checker:RemoveOnDeath() return false end

function modifier_lagron_damage_checker:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

if IsServer() then 
    function modifier_lagron_damage_checker:OnTakeDamage(args)
        if args.unit ~= self:GetParent() then return end

        if args.attacker == self:GetParent() then return end

        args.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lagron_damage_checker_enemy", { Duration = self:GetAbility():GetSpecialValueFor("marker_duration") })
    end
end

modifier_lagron_damage_checker_enemy = class({})

function modifier_lagron_damage_checker_enemy:IsHidden() return false end
function modifier_lagron_damage_checker_enemy:IsDebuff() return true end
function modifier_lagron_damage_checker_enemy:IsPurgable() return false end
function modifier_lagron_damage_checker_enemy:IsPurgeException() return false end
function modifier_lagron_damage_checker_enemy:RemoveOnDeath() return true end