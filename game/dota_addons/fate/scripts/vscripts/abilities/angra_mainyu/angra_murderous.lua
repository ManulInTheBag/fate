LinkLuaModifier("modifier_angra_murderous", "abilities/angra_mainyu/angra_murderous", LUA_MODIFIER_MOTION_NONE)
angra_murderous = class({})

function angra_murderous:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("avenger_unlimited_remains"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("avenger_unlimited_remains"):SetLevel(self:GetLevel())
    end

end

function angra_murderous:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_angra_murderous", {duration  = self:GetSpecialValueFor("duration")})


	ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster))
	ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/jugg_crit_blur_impact.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster))
	caster:EmitSound("Hero_OgreMagi.Bloodlust.Cast")
end


modifier_angra_murderous = class({})

function modifier_angra_murderous:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function modifier_angra_murderous:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr")
end

function modifier_angra_murderous:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_angra_murderous:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("regen")
end

function modifier_angra_murderous:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana")
end

function modifier_angra_murderous:IsDebuff()                                                             return false end
function modifier_angra_murderous:IsPurgable()                                                           return false end
function modifier_angra_murderous:IsPurgeException()                                                     return false end
function modifier_angra_murderous:RemoveOnDeath()                                                        return true end
function modifier_angra_murderous:IsHidden()															  return false end

function modifier_angra_murderous:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_angra_murderous:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


function angra_murderous:GetIntrinsicModifierName()
    return "modifier_angra_idle_animation"
end
LinkLuaModifier("modifier_angra_idle_animation", "abilities/angra_mainyu/angra_murderous", LUA_MODIFIER_MOTION_NONE)
modifier_angra_idle_animation = class({})
function modifier_angra_idle_animation:OnCreated(args)
    self.activity = "not_in_fight"
	self:StartIntervalThink(0.5)
end
function modifier_angra_idle_animation:OnIntervalThink()
	if self:GetRemainingTime() < 0.5 then
		self.activity = "not_in_fight"
	end
end
function modifier_angra_idle_animation:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
 	self.activity = "in_fight"
	self:SetDuration(4, true)
end
function modifier_angra_idle_animation:OnAttackLanded(args)
    if args.attacker ~= self:GetParent() then return end
    self.activity = "in_fight"
	self:SetDuration(4, true)
end

function modifier_angra_idle_animation:IsHidden() return true end
function modifier_angra_idle_animation:IsDebuff() return false end
function modifier_angra_idle_animation:IsPurgable() return false end
function modifier_angra_idle_animation:IsPurgeException() return false end
function modifier_angra_idle_animation:DestroyOnExpire() return false end
function modifier_angra_idle_animation:RemoveOnDeath() return false end

function modifier_angra_idle_animation:DeclareFunctions()
    local func = {    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS}
    return func
end

function modifier_angra_idle_animation:GetActivityTranslationModifiers()
	return self.activity
end

