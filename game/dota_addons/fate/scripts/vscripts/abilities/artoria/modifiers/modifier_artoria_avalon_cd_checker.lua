modifier_artoria_avalon_cd_checker = class({})

function modifier_artoria_avalon_cd_checker:IsHidden()
	return true
end

function modifier_artoria_avalon_cd_checker:IsPermanent()
	return false
end

function modifier_artoria_avalon_cd_checker:RemoveOnDeath()
	return false
end

function modifier_artoria_avalon_cd_checker:IsDebuff()
	return true 
end

function modifier_artoria_avalon_cd_checker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end