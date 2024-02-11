LinkLuaModifier("modifier_lu_bu_rage", "abilities/lu_bu/lu_bu_rage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_rage_slow", "abilities/lu_bu/lu_bu_rage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_assault_skillswap_3", "abilities/lu_bu/modifiers/modifier_assault_skillswap_3", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker", LUA_MODIFIER_MOTION_NONE )
lu_bu_rage = class({})

function lu_bu_rage:OnUpgrade()
    local relentless_assault = self:GetCaster():FindAbilityByName("lu_bu_relentless_assault_three")
    relentless_assault:SetLevel(self:GetLevel())
end

function lu_bu_rage:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function lu_bu_rage:OnSpellStart()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_lu_bu_rage") then
		caster:RemoveModifierByName("modifier_lu_bu_rage")
		return
	end
	caster:EmitSound("lu_bu_rage")
	local duration = self:GetSpecialValueFor("active_duration")
	caster:AddNewModifier(caster,self,"modifier_lu_bu_rage",{duration = duration})

	self.resolutionFx = ParticleManager:CreateParticle("particles/lu_bu/lu_bu_rage.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   	ParticleManager:SetParticleControl( self.resolutionFx, 4, caster:GetAbsOrigin())
   	ParticleManager:SetParticleControl( self.resolutionFx, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius")))
	local relentless_assault = caster:FindModifierByNameAndCaster( "modifier_lu_bu_relentless_assault", caster )
	local assault_stack = caster:GetModifierStackCount("modifier_lu_bu_relentless_assault", caster)
	   
	if caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack < 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
	   relentless_assault:SetStackCount(assault_stack + 1)
	elseif caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack >= 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
	   caster:AddNewModifier(caster, self, "modifier_assault_skillswap_3", {})
	   caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker", {})
	end
end



modifier_lu_bu_rage = class({})

function modifier_lu_bu_rage:IsDebuff() return false end
function modifier_lu_bu_rage:IsHidden() return false end
function modifier_lu_bu_rage:RemoveOnDeath() return false end

function modifier_lu_bu_rage:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_OVERRIDE_ANIMATION
		 }
end

function modifier_lu_bu_rage:CheckState()
	local state = {[MODIFIER_STATE_STUNNED] = true,

				}
	return state
end
function modifier_lu_bu_rage:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_3_END
end

function modifier_lu_bu_rage:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_bonus")
end

function modifier_lu_bu_rage:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr_bonus")
end

function modifier_lu_bu_rage:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	--self.caster:EmitSound("Hero_ArcWarden.MagneticField")

	self.interval = 0.1

	self.tickDamage = self.ability:GetSpecialValueFor("damage")*self.interval

	self.radius = self.ability:GetSpecialValueFor("radius")


	self:StartIntervalThink(self.interval)
end

function modifier_lu_bu_rage:OnIntervalThink()
	if not IsServer() then return end

	local targets = FindUnitsInRadius(self.caster:GetTeam(), self.caster:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
	    DoDamage(self.caster, v, self.tickDamage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
		giveUnitDataDrivenModifier(self.caster, v, "locked", 0.2)
	    if not IsImmuneToSlow(v) then v:AddNewModifier(self.caster, self.ability, "modifier_lu_bu_rage_slow", {duration = 0.2}) end
    end
end



modifier_lu_bu_rage_slow = class({})

function modifier_lu_bu_rage_slow:DeclareFunctions()
	return {	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	}
end

function modifier_lu_bu_rage_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_amount")
end