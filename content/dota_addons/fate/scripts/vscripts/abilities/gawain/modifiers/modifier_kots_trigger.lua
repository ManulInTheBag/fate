modifier_kots_trigger = class({})

if IsServer() then
	function modifier_kots_trigger:OnCreated(args)
		self:SetStackCount(5)
	end

	function modifier_kots_trigger:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_kots_trigger:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		local stacks = self:GetStackCount()

		if stacks - 1 > 0 then
			self:SetStackCount(stacks - 1)
		else
			self:Destroy()
		end
	end
end

function modifier_kots_trigger:GetModifierAttackSpeedBonus_Constant()
	return 400
end

function modifier_kots_trigger:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

function modifier_kots_trigger:IsHidden()
	return true 
end