LinkLuaModifier("modifier_jeanne_mana", "abilities/jeanne_alter/jeanne_mana", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_lagron_combo_window", "abilities/jeanne_alter/jeanne_mana", LUA_MODIFIER_MOTION_NONE)

jeanne_mana = class({})

function jeanne_mana:GetIntrinsicModifierName()
    return "modifier_jeanne_mana"
end

function jeanne_mana:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_jeanne_lagron_combo_window", {duration = self:GetSpecialValueFor("combo_window")})
end
---------------------------------------------------------------------------------------------------------------------
modifier_jeanne_mana = class({})
function modifier_jeanne_mana:IsHidden() return false end
function modifier_jeanne_mana:IsDebuff() return false end
function modifier_jeanne_mana:IsPurgable() return false end
function modifier_jeanne_mana:IsPurgeException() return false end
function modifier_jeanne_mana:RemoveOnDeath() return false end
function modifier_jeanne_mana:DeclareFunctions()
    local func = {  --MODIFIER_PROPERTY_AVOID_DAMAGE,
    				--MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    				MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
    				--MODIFIER_EVENT_ON_ATTACK_LANDED,
                    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
                MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,}
    return func
end
-- do NOT turn this on, it works, but it can't be balanced at all (not in this skillset)
--[[function modifier_jeanne_mana:GetModifierAvoidDamage(keys)
	self.mana_per_damage = self.ability:GetSpecialValueFor("mana_per_damage")
	
    local health_will_be = self.parent:GetHealth() - keys.damage

    if health_will_be <= 1 and self.parent:IsRealHero() and not self.parent:IsTempestDouble() then
   		if self.parent:PassivesDisabled() or not self.parent.EphemeralDreamAcquired then
			return nil
		end

    	local spend_mana = math.abs(health_will_be) * self.mana_per_damage

    	if self.parent:HasModifier("modifier_jeanne_lagron_block") then
    		spend_mana = spend_mana * self.parent:FindAbilityByName("jeanne_lagron"):GetSpecialValueFor("return_percentage")/100
    	end

    	self.parent:SpendMana(spend_mana, self.ability)

    	local mana_will_be = self.parent:GetMana()
    	if mana_will_be > 0 then
	    	self.parent:SetHealth(1)

	    	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, self.parent, mana_will_be, nil)  

    		return 1
    	end
    end
end]]
--[[function modifier_jeanne_mana:GetModifierMagicalResistanceBonus()
	if self:GetParent().EphemeralDreamAcquired then
    	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("resistance")
    end
end]]
function modifier_jeanne_mana:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "Tsubame_Slash_"..math.random(1,3)
end

function modifier_jeanne_mana:GetAttackSound()
	return self.sound
end

function modifier_jeanne_mana:GetModifierConstantManaRegen()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("mana_per_stack")
end
function modifier_jeanne_mana:GetModifierConstantHealthRegen()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("health_per_stack")
end
function modifier_jeanne_mana:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.sound = "Tsubame_Slash_"..math.random(1,3)
    if IsServer() then
        self:StartIntervalThink(FrameTime())

        self.particle_unbreak = ParticleManager:CreateParticle("particles/jeanne_alter/cd_unbreak.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
                                ParticleManager:SetParticleControl(self.particle_unbreak, 0, self:GetParent():GetAbsOrigin())
                                --ParticleManager:SetParticleControlEnt(self.particle_unbreak, 1, self:GetParent(), PATTACH_POINT_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
                                --ParticleManager:SetParticleControl(self.particle_unbreak, 3, Vector(1,0,0))
                                --ParticleManager:SetParticleControl(self.particle_unbreak, 4, Vector(1,0,0))
                                ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(self:GetStackCount(),0,0))

        self:AddParticle(self.particle_unbreak, false, true, -1, true, false)
    end
end
function modifier_jeanne_mana:OnIntervalThink()
    --if IsServer() then
        if self:GetParent():IsIllusion() then
            return nil
        end
        local health_perc = self:GetParent():GetHealthPercent()/100
        local newStackCount = -1

        for i = 1, 0.01, -(self:GetAbility():GetSpecialValueFor("health") * 0.01) do
            if health_perc <= i then
                newStackCount = newStackCount+1
            else
                break
            end
        end

        self:SetStackCount(newStackCount)

        ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(self:GetStackCount() * 10,0,0))
    --end
end

modifier_jeanne_lagron_combo_window = class({})
function modifier_jeanne_lagron_combo_window:IsHidden() return true end
function modifier_jeanne_lagron_combo_window:IsDebuff() return false end
function modifier_jeanne_lagron_combo_window:IsPurgable() return false end
function modifier_jeanne_lagron_combo_window:IsPurgeException() return false end
function modifier_jeanne_lagron_combo_window:RemoveOnDeath() return false end