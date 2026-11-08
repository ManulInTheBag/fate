modifier_hecatic_graea_anim = class({})

function modifier_hecatic_graea_anim:IsHidden()
	return true 
end
function modifier_hecatic_graea_anim:RemoveOnDeath()
	return true 
end
function modifier_hecatic_graea_anim:OnCreated(kv)
	if self:GetCaster():HasModifier("modifier_hero_selection_skin") then
		self:SetStackCount(1000)
	end
	-- SetBodygroup существует только в серверной VM: на клиенте это был
	-- «attempt to call method (a nil value)», т.е. метода нет, а не кастера
	if not IsServer() then return end
	self:GetCaster():SetBodygroup(0,2)
end

function modifier_hecatic_graea_anim:OnDestroy()
	-- SetBodygroup существует только в серверной VM: на клиенте это был
	-- «attempt to call method (a nil value)», т.е. метода нет, а не кастера
	if not IsServer() then return end
	self:GetCaster():SetBodygroup(0,0)
end
function modifier_hecatic_graea_anim:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
			 MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end

function modifier_hecatic_graea_anim:GetOverrideAnimation()
	if self:GetStackCount() == 1000 then
		return ACT_DOTA_CAST_ABILITY_6
	else
		return ACT_DOTA_CAST_ABILITY_4
	end
end

function modifier_hecatic_graea_anim:GetOverrideAnimationRate()
	return 1.0
end