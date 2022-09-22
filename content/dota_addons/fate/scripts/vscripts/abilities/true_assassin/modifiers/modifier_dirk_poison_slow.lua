modifier_dirk_poison_slow = class({})

LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_poison_slow", "abilities/true_assassin/modifiers/modifier_dirk_poison_slow", LUA_MODIFIER_MOTION_NONE)

function modifier_dirk_poison_slow:OnCreated(args)
	if IsServer() then
		Timers:CreateTimer(FrameTime(), function()
			self.PoisonSlow	= -1*args.PoisonSlow*self:GetStackCount()
			print(self:GetStackCount())
			if self:GetAbility():GetCaster().IsWeakeningWenomAcquired then
				self.PoisonSlow = self.PoisonSlow/2
			end
			CustomNetTables:SetTableValue("sync","dirk_poison_slow", {poison_slow = self.PoisonSlow})
		end)
	end
end

function modifier_dirk_poison_slow:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_dirk_poison_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_dirk_poison_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
    	return self.PoisonSlow
    elseif IsClient() then
        local poison_slow = CustomNetTables:GetTableValue("sync","dirk_poison_slow").poison_slow
        return poison_slow 
    end
end

function modifier_dirk_poison_slow:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_dirk_poison_slow:IsDebuff()
	return true 
end

function modifier_dirk_poison_slow:RemoveOnDeath()
	return true 
end

function modifier_dirk_poison_slow:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf"
end

function modifier_dirk_poison_slow:GetTexture()
    return "custom/true_assassin_dirk"
end

function modifier_dirk_poison_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end