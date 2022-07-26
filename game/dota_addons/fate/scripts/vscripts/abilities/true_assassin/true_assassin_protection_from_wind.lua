LinkLuaModifier("modifier_wind_protection_passive", "abilities/true_assassin/true_assassin_protection_from_wind", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wind_protection_active", "abilities/true_assassin/true_assassin_protection_from_wind", LUA_MODIFIER_MOTION_NONE)

true_assassin_protection_from_wind = class({})

function true_assassin_protection_from_wind:GetIntrinsicModifierName()
	return "modifier_wind_protection_passive"
end

function true_assassin_protection_from_wind:GetBehavior()
	return self:GetSpecialValueFor("behavior") + 64 + 2048--64 for not learnable, 2 passive, 4 no target, 2048 immediate
end

function true_assassin_protection_from_wind:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_wind_protection_active", {duration = self:GetSpecialValueFor("duration")})
end

modifier_wind_protection_passive = class({})

function modifier_wind_protection_passive:IsHidden() return false end
function modifier_wind_protection_passive:IsDebuff() return false end
function modifier_wind_protection_passive:RemoveOnDeath() return false end
function modifier_wind_protection_passive:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

modifier_wind_protection_active = class({})

function modifier_wind_protection_active:OnCreated()
	--[[self.fx = ParticleManager:CreateParticle("particles/okita/okita_windrun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 3, self:GetParent():GetAbsOrigin())]]
	if self:GetParent().DesertNomadAcquired then
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_wind_protection_active:IsDebuff() return false end

function modifier_wind_protection_active:IsHidden() return false end

function modifier_wind_protection_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			--MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ORDER,}
end

function modifier_wind_protection_active:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end

function modifier_wind_protection_active:OnIntervalThink()
	if self:GetParent():AttackReady() and not self:GetParent():IsStunned() and self.target and not self.target:IsNull() and self.target:IsAlive() and (self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D() <= (self:GetParent():Script_GetAttackRange()+75) and self.bFocusing then
		--self:GetParent():SetForwardVector((self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Normalized())
		self:GetParent():StartGesture(ACT_DOTA_ATTACK)
		self:GetParent():PerformAttack(self.target, true, true, false, true, true, false, false)
	end
end

function modifier_wind_protection_active:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return nil end
	self.target = args.target
	self.bFocusing = true
end

function modifier_wind_protection_active:OnOrder(keys)
	if keys.unit == self:GetParent() then
		if keys.order_type == DOTA_UNIT_ORDER_STOP or keys.order_type == DOTA_UNIT_ORDER_CONTINUE or not self:GetParent():AttackReady() then
			self.bFocusing	= false
		else
			self.bFocusing	= true
		end
	end
end