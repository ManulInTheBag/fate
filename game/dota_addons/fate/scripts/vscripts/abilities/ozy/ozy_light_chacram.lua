LinkLuaModifier("modifier_ozy_chacram_ability_change", "abilities/ozy/ozy_light_chacram", LUA_MODIFIER_MOTION_NONE)
ozy_light_chacram = class({})

function ozy_light_chacram:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if self.casted then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCESS
end

function ozy_light_chacram:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("ozy_light_chacram_recast"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("ozy_light_chacram_recast"):SetLevel(self:GetLevel())
    end
	
end

function ozy_light_chacram:GetCustomCastErrorLocation(hLocation)
    return "Only one at a timee"
end

function ozy_light_chacram:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
    self.casted = true
    
    
    EmitSoundOn("ozy_chacram_cast", caster)
    if target == caster:GetAbsOrigin() then
        target = caster:GetAbsOrigin() + caster:GetForwardVector()*100
    end
    local vector = (target - caster:GetAbsOrigin()):Normalized()
    vector.z = 0
    local speed = 1800
	local tProjectile = {
        EffectName = "particles/ozy/ozy_chacram.vpcf" ,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin() + Vector(0,0,120),
        vVelocity = vector * speed,
        fDistance = 1100,
        fStartRadius = 128,
        fEndRadius = 128,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = 0,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.1,
        --iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    }
    Timers:CreateTimer("ozymandias_chacram_checker", {
			endTime = 1100/speed + 0.1,
			callback = function()
			self.casted = false
    end})

 
    caster.ChacramProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)

end

---Linear version
function ozy_light_chacram:OnProjectileHit(target, location, tData )
    if target == nil then
        return false
    end
    if (target:GetName() == "npc_dota_ward_base") then
        return false
    end
    if target:HasModifier("modifier_protection_from_arrows_active") then return end
    local hModifier = nil

    local caster = self:GetCaster()
    if IsSpellBlocked(target, caster) then return true end
    DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
    if not target:IsMagicImmune() then
       giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
    end
    Timers:CreateTimer(0.033,function()
        ProjectileManager:DestroyLinearProjectile(caster.ChacramProjectile )
    end)
    EmitSoundOn("ozy_chacram_impact", target)
    caster.OzyChacramTarget = target
    caster:AddNewModifier(caster, self, "modifier_ozy_chacram_ability_change", {duration = self:GetSpecialValueFor("jopa_recast_duration")})
    

    return true
end


modifier_ozy_chacram_ability_change = class({})

function modifier_ozy_chacram_ability_change:IsHidden()
	return false 
end

function modifier_ozy_chacram_ability_change:RemoveOnDeath()
	return true
end

if IsServer() then
	function modifier_ozy_chacram_ability_change:OnCreated(args)
		local caster = self:GetParent()
        self.particle = ParticleManager:CreateParticle("particles/ozy/chacram_unit_hold.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster.OzyChacramTarget )
        self.ozyParticle = ParticleManager:CreateParticleForPlayer("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster.OzyChacramTarget,caster:GetPlayerOwner() )
        ParticleManager:SetParticleControl(self.ozyParticle, 0, caster.OzyChacramTarget:GetAbsOrigin())
        ParticleManager:SetParticleControl(self.ozyParticle, 1, Vector(1,1,0.01))
        ParticleManager:SetParticleControl(self.ozyParticle, 2, Vector(600,1,0))
        ParticleManager:SetParticleControl(self.particle, 0, caster.OzyChacramTarget:GetAbsOrigin() + Vector(0,0, 100))
         if caster:GetAbilityByIndex(0):GetName() == "ozy_light_chacram" then
		     caster:SwapAbilities("ozy_light_chacram", "ozy_light_chacram_recast", false, true)
         end
	end

	function modifier_ozy_chacram_ability_change:OnDestroy()	
		local caster = self:GetParent()	
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
        ParticleManager:DestroyParticle(self.ozyParticle, true)
        ParticleManager:ReleaseParticleIndex(self.ozyParticle)
        if caster:GetAbilityByIndex(0):GetName() == "ozy_light_chacram_recast" then
		     caster:SwapAbilities("ozy_light_chacram", "ozy_light_chacram_recast", true, false)
        end
        caster.OzyChacramTarget = nil
	end
end



