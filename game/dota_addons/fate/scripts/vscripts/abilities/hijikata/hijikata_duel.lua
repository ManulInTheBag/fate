hijikata_duel = class({})

LinkLuaModifier("modifier_hijikata_duel", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_duel_aura", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)


function hijikata_duel:OnSpellStart()
	self.caster = self:GetCaster()
	local ability = self
    self.target = self:GetCursorTarget()
    local targetpos = (-self.target:GetAbsOrigin() + self.caster:GetAbsOrigin())/2 + self.target:GetAbsOrigin()
    local duration = self:GetSpecialValueFor("duration")
    local modifier = self.caster:FindModifierByName("modifier_hijikata_laws")
    if modifier.duel_restriction == false then
        modifier:IncrementStackCount()
        modifier.duel_restriction = true
    end
    if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
        self.AuraDummy:RemoveModifierByName("modifier_hijikata_duel_aura")
        local pepe = self.AuraDummy
        Timers:CreateTimer(1, function()
            if pepe then
                pepe:RemoveSelf()
            end
        end)
    end
    self.AuraDummy = CreateUnitByName("sight_dummy_unit", targetpos, false, nil, nil, self.caster:GetTeamNumber())
	self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.AuraDummy:SetDayTimeVisionRange(0)
	self.AuraDummy:SetNightTimeVisionRange(0)
    self.castfx = ParticleManager:CreateParticle("particles/hijikata/hijikata_duel.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.AuraDummy )
    ParticleManager:SetParticleControl(self.castfx, 19, Vector(self:GetSpecialValueFor("radius"),duration,self:GetSpecialValueFor("radius")))
    --ParticleManager:ReleaseParticleIndex(self.castfx)
	self.AuraDummy:AddNewModifier(self.caster, self, "modifier_hijikata_duel_aura", { duration = duration, --aura for aura modifiers
																				 auraRadius = self:GetSpecialValueFor("radius")})

    local duelself = ParticleManager:CreateParticle("particles/hijikata/hijikata_duel_text.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.caster )
    ParticleManager:SetParticleControl(duelself, 2, Vector(3,0,0))
    ParticleManager:SetParticleControl(duelself, 3, targetpos + Vector(0,0,self:GetSpecialValueFor("radius")/2))

    ParticleManager:ReleaseParticleIndex(duelself)
    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(self.castfx, false)
        ParticleManager:ReleaseParticleIndex(self.castfx)

        if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
			self.AuraDummy:RemoveModifierByName("modifier_hijikata_duel_aura")

			local pepe = self.AuraDummy
			Timers:CreateTimer(1, function()
				if pepe then
					pepe:RemoveSelf()
				end
			end)
		end
    end)
	
end

modifier_hijikata_duel_aura = class({})

function modifier_hijikata_duel_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY 
end

function modifier_hijikata_duel_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_hijikata_duel_aura:OnCreated(args)
    self.radius = args.auraRadius
end


function modifier_hijikata_duel_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_hijikata_duel_aura:GetAuraRadius()
	return  self.radius
end

function modifier_hijikata_duel_aura:GetModifierAura()
	return "modifier_hijikata_duel"
end

function modifier_hijikata_duel_aura:IsHidden()
	return true
end

function modifier_hijikata_duel_aura:RemoveOnDeath()
	return true
end

function modifier_hijikata_duel_aura:IsDebuff()
	return false 
end

function modifier_hijikata_duel_aura:IsAura()
	return true 
end

function modifier_hijikata_duel_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 
 

modifier_hijikata_duel = class({})

function modifier_hijikata_duel:IsHidden()
    return false 
end

function modifier_hijikata_duel:OnCreated()
    self.dmg_res = self:GetAbility():GetSpecialValueFor("dmg_res")
    self.parent = self:GetParent()
    self.hijikata = self:GetAbility().caster
    self.initialTarget = self:GetAbility().target
end

function modifier_hijikata_duel:RemoveOnDeath()
    return true
end

function modifier_hijikata_duel:IsDebuff()
    return true 
end

function modifier_hijikata_duel:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_duel:OnDestroy()

end

function modifier_hijikata_duel:DeclareFunctions()
   	return {	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end
function modifier_hijikata_duel:GetModifierDamageOutgoing_Percentage(args)
    local attacker = args.attacker
    local target = args.target
    --  if target:IsNotNull() ~= true then return end
    if attacker == self.initialTarget then return end
    if target == self.hijikata then
    print("attacking_hij")
        print(-self.dmg_res  )
       return -self.dmg_res 
    end
    print("attacking not hij")
    return 
end