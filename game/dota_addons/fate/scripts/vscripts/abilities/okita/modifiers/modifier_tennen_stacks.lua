modifier_tennen_stacks = class({})

function modifier_tennen_stacks:IsHidden() return false end
function modifier_tennen_stacks:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_tennen_stacks:RemoveOnDeath() return false end
function modifier_tennen_stacks:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_tennen_stacks:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
					--MODIFIER_EVENT_ON_ATTACK_LANDED,
				}
	return func
end

function modifier_tennen_stacks:GetAttackSound()
	return self.sound
end

function modifier_tennen_stacks:GetModifierBonusStats_Agility()
	if self:GetParent():PassivesDisabled() then
		return nil
	end
	if self:GetStackCount() then
		return self:GetAbility():GetSpecialValueFor("bonus_agi")*self:GetStackCount()
	end
	return 0
end

function modifier_tennen_stacks:OnCreated()
	self.sound = "Tsubame_Slash_"..math.random(1,3)
end

function modifier_tennen_stacks:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "Tsubame_Slash_"..math.random(1,3)
	self.max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks") + (self:GetParent().IsTennenAcquired and 10 or 0)
	if self:GetStackCount() and self:GetStackCount() < self.max_stacks then
		self:SetStackCount(self:GetStackCount() + 1)
		Timers:CreateTimer(10, function()
			self:SetStackCount(self:GetStackCount()-1)
		end)
	else
		if not self:GetStackCount() then
			self:SetStackCount(1)
			Timers:CreateTimer(10, function()
				self:SetStackCount(self:GetStackCount()-1)
			end)
		end
	end
end