modifier_breaker_gorgon_self = class({})

LinkLuaModifier("modifier_breaker_gorgon_self_frozen", "abilities/medusa/modifiers/modifier_breaker_gorgon_self_frozen", LUA_MODIFIER_MOTION_NONE)

function modifier_breaker_gorgon_self:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE }
end

function modifier_breaker_gorgon_self:OnCreated(args)
	if IsServer() then	
		self:GetParent():EmitSound("Hero_Medusa.StoneGaze.Cast")
		self:StartIntervalThink(0.1)
	end
end

function modifier_breaker_gorgon_self:OnRefresh(args)
	if IsServer() then
		self:GetParent():StopSound("Hero_Medusa.StoneGaze.Cast")
		self:OnCreated(args)
	end
end

function modifier_breaker_gorgon_self:OnIntervalThink()
	local caster = self:GetParent()

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
	for _,v in pairs(targets) do            
        if not v:IsMagicImmune() and not v:HasModifier("modifier_breaker_gorgon") then
            v:AddNewModifier(caster, self, "modifier_breaker_gorgon", { duration = self:GetRemainingTime() })
        end        
    end
end

function modifier_breaker_gorgon_self:OnDestroy()
	if IsServer() then
		self:GetParent():StopSound("Hero_Medusa.StoneGaze.Cast")
	end
end

function modifier_breaker_gorgon_self:GetEffectName()
	return "particles/custom/rider/rider_breaker_gorgon_debuff.vpcf"
end

function modifier_breaker_gorgon_self:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_breaker_gorgon_self:IsHidden()
	return false
end

function modifier_breaker_gorgon_self:IsDebuff()
	return true
end

function modifier_breaker_gorgon_self:RemoveOnDeath()
	return true
end

function modifier_breaker_gorgon_self:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_breaker_gorgon_self:GetTexture()
	return "custom/rider_5th_breaker_gorgon"
end