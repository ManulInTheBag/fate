modifier_team_emiya_artoria = class({})

function modifier_team_emiya_artoria:IsHidden()
	return true
end

function modifier_team_emiya_artoria:IsPermanent()
	return true
end

function modifier_team_emiya_artoria:RemoveOnDeath()
	return false
end

function modifier_team_emiya_artoria:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end