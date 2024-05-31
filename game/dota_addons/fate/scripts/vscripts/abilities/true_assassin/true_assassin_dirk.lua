true_assassin_dirk = class({})
modifier_dirk_dagger_count = class({})
modifier_dirk_dagger_count_progress = class({})

LinkLuaModifier("modifier_dirk_poison", "abilities/true_assassin/modifiers/modifier_dirk_poison", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_dagger_count", "abilities/true_assassin/true_assassin_dirk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_dagger_count_progress", "abilities/true_assassin/true_assassin_dirk", LUA_MODIFIER_MOTION_NONE)

function true_assassin_dirk:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()

    if caster:HasDagger() then
        local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

		if(filter == UF_SUCCESS) then
			if hTarget:GetName() == "npc_dota_ward_base" then 
				return UF_FAIL_OTHER 
			else
				return UF_SUCCESS
			end
		else
			return filter
		end
    else
    	return UF_FAIL_CUSTOM
    end
end

function true_assassin_dirk:GetCustomCastErrorTarget(hTarget)
	return "No Daggers Available"
end

function true_assassin_dirk:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local maxTarget = self:GetSpecialValueFor("max_target")
	if IsSpellBlocked(target) then
        caster:UseDagger(5)
        self:StartCooldown(self:GetSpecialValueFor("restock_dur") - caster.nextDagger)
         return end
	--local range = caster:GetRangeToUnit(target) + 200
    Timers:CreateTimer(FrameTime(), function()
        if caster and caster:IsAlive() and caster:HasDagger() and (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() <= 950 then
        	caster:UseDagger(1)
        	caster:EmitSound("Hero_PhantomAssassin.Dagger.Cast")


            self:EndCooldown()
            if not caster:HasDagger() then
                self:StartCooldown(self:GetSpecialValueFor("restock_dur") - caster.nextDagger)
            end

        	local info = {
        		Target = target,
        		Source = caster, 
        		Ability = ability,
        		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
        		vSpawnOrigin = caster:GetAbsOrigin(),
        		iMoveSpeed = 1800,
                iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        	}
        	FATE_ProjectileManager:CreateTrackingProjectile(info) 

        	--[[
        		local targetCount = 1
        		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, range
        	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
        		for k,v in pairs(targets) do
        			--if v:CanEntityBeSeenByMyTeam(caster) then
        			if v ~= target then
        				targetCount = targetCount + 1
        		        info.Target = v
        		        ProjectileManager:CreateTrackingProjectile(info)
        		    end 

        	        if targetCount == maxTarget then return end
        	    end
            ]]
            return 0.1
        end
    end)
end

function true_assassin_dirk:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end
    local ability = self
    local hCaster = self:GetCaster()
    local fDamage = self:GetSpecialValueFor("damage") 
    local fPoisonDamage = self:GetSpecialValueFor("poison_dot")
    
   -- if IsSpellBlocked(hTarget) or hTarget:IsMagicImmune() then return end
 

    --if not hCaster.IsWeakeningVenomAcquired then
    	fDamage = fDamage + (hCaster:GetAverageTrueAttackDamage(hCaster) * self:GetSpecialValueFor("atk_ratio")/100)
        if hCaster:HasModifier("modifier_selfmod_agility") then
            local Damage = math.floor(self:GetCaster():GetAgility() * self:GetSpecialValueFor("agi_mult"))
            DoDamage(hCaster, hTarget, Damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        end
    --else
    	--fDamage = fDamage + (hCaster:GetAverageTrueAttackDamage(hCaster) * 2.5)
    --end

    local stacks = 0
    --[[if hTarget:HasModifier("modifier_weakening_venom") then 
        stacks = hTarget:GetModifierStackCount("modifier_weakening_venom", ability)
    end     

    hTarget:RemoveModifierByName("modifier_weakening_venom") 
    hTarget:AddNewModifier(hCaster, ability, "modifier_weakening_venom", { duration = 12 }) 

    if hCaster.IsWeakeningVenomAcquired then
        hTarget:SetModifierStackCount("modifier_weakening_venom", ability, stacks + self:GetSpecialValueFor("venom_stacks"))
    else
        hTarget:SetModifierStackCount("modifier_weakening_venom", ability, stacks + 1)
    end]]

    hTarget:AddNewModifier(hCaster, ability, "modifier_dirk_poison", {	Duration = self:GetSpecialValueFor("duration"),
																		PoisonDamage = fPoisonDamage,
																		PoisonSlow = self:GetSpecialValueFor("poison_slow") })

    local poison_stacks = 0
    if hTarget:HasModifier("modifier_dirk_poison_slow") then
        poison_stacks = hTarget:GetModifierStackCount("modifier_dirk_poison_slow", ability)
    end
    hTarget:RemoveModifierByName("modifier_dirk_poison_slow")
    if not IsImmuneToSlow(hTarget) then
        hTarget:AddNewModifier(hCaster, ability, "modifier_dirk_poison_slow", { PoisonSlow = self:GetSpecialValueFor("poison_slow"),
                                                                                Duration = self:GetSpecialValueFor("duration") })
    end
    hTarget:SetModifierStackCount("modifier_dirk_poison_slow", ability, poison_stacks + 1)

    hTarget:EmitSound("Hero_PhantomAssassin.Dagger.Target")

	DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
end

function true_assassin_dirk:OnUpgrade()
    local hero = self:GetCaster()
    if not hero:HasModifier("modifier_dirk_dagger_count_progress") then
        hero:AddNewModifier(hero, self, "modifier_dirk_dagger_count_progress", {})
    end
end

function true_assassin_dirk:GetIntrinsicModifierName()
	return "modifier_dirk_dagger_count"
end

local THINK_INTERVAL = 0.05
function modifier_dirk_dagger_count:OnCreated()
    local hero = self:GetParent()
    if IsServer() then
        hero.nextDagger = 0

        self:SetStackCount(self:GetMaxStackCount())
        self:StartIntervalThink(THINK_INTERVAL)
    end

    local modifier = self

    function hero:HasDagger()
        return modifier:GetStackCount() > 0
    end

    function hero:GetDaggerCount()
        return modifier:GetStackCount()
    end

    function hero:UseDagger(number)
        local count = modifier:GetStackCount()
        modifier:SetStackCount(math.max(count - number, 0))
    end

    function hero:AddDagger(number)
        local count = modifier:GetStackCount()
        modifier:SetStackCount(math.min(count + number, modifier:GetMaxStackCount()))
    end
end

function modifier_dirk_dagger_count:DeclareFunctions()
    return { MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_dirk_dagger_count:OnRespawn()
    self:SetStackCount(self:GetMaxStackCount())
    local hero = self:GetParent()
    hero.nextDagger = 0
    self:UpdateProgress()
end

function modifier_dirk_dagger_count:GetMaxStackCount()
    return self:GetAbility():GetSpecialValueFor("max_daggers")
end

function modifier_dirk_dagger_count:OnIntervalThink()
    if IsServer() then
        local hero = self:GetParent()
        local nextDagger = hero.nextDagger

        if self:GetStackCount() >= self:GetMaxStackCount() then
            return
        end

        nextDagger = nextDagger + THINK_INTERVAL

        if nextDagger >= self:GetAbility():GetSpecialValueFor("restock_dur") then
            nextDagger = 0
            self:SetStackCount(self:GetStackCount() + 1)
        end

        hero.nextDagger = nextDagger
        self:UpdateProgress()
    end
end

function modifier_dirk_dagger_count:UpdateProgress() 
    local hero = self:GetParent()
    local progress = hero:FindModifierByName("modifier_dirk_dagger_count_progress")
    progress:SetStackCount(hero.nextDagger * 100 / self:GetAbility():GetSpecialValueFor("restock_dur"))
end

function modifier_dirk_dagger_count:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_dirk_dagger_count:IsDebuff()
    return false
end

function modifier_dirk_dagger_count:RemoveOnDeath()
    return false
end

function modifier_dirk_dagger_count:GetTexture()
    return "custom/true_assassin_dirk"
end


function modifier_dirk_dagger_count_progress:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_dirk_dagger_count_progress:IsHidden()
    return true
end

function modifier_dirk_dagger_count_progress:IsDebuff()
    return false
end

function modifier_dirk_dagger_count_progress:RemoveOnDeath()
    return false
end
