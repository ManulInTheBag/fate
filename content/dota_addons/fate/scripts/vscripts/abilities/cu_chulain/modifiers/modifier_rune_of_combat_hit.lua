modifier_rune_of_combat_hit = class({})

if IsServer() then
	function modifier_rune_of_combat_hit:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
	end

	function modifier_rune_of_combat_hit:OnRefresh(args)
		args.Stacks = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_rune_of_combat_hit:IsHidden()
	return true
end

function modifier_rune_of_combat_hit:IsPurgable()
	return false
end

function modifier_rune_of_combat_hit:IsDebuff()
	return true
end

function modifier_rune_of_combat_hit:RemoveOnDeath()
	return true
end

function modifier_rune_of_combat_hit:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end