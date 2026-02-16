
LinkLuaModifier("modifier_okada_manslayer", "abilities/okada/okada_manslayer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okada_manslayer_passive", "abilities/okada/okada_manslayer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
okada_manslayer = class({})



function okada_manslayer:GetIntrinsicModifierName()
	return "modifier_okada_manslayer_passive"
end


function okada_manslayer:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("okada_d")
	caster:AddNewModifier(caster, self, "modifier_okada_manslayer", {duration = self:GetSpecialValueFor("active_duration")})
end


modifier_okada_manslayer = class({})

function modifier_okada_manslayer:IsHidden() 
	return false
end

function modifier_okada_manslayer:RemoveOnDeath()
	return true
end

function modifier_okada_manslayer:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
    
    return state
end

function modifier_okada_manslayer:GetEffectName()
	return "particles/okada/okada_manslayer_ambient.vpcf"
end

function modifier_okada_manslayer:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end




modifier_okada_manslayer_passive = class({})



function modifier_okada_manslayer_passive:IsHidden() 
	return true
end

function modifier_okada_manslayer_passive:IsPermanent()
	return true
end

function modifier_okada_manslayer_passive:RemoveOnDeath()
	return false
end

function modifier_okada_manslayer_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_okada_manslayer_passive:DeclareFunctions()
	return {	MODIFIER_EVENT_ON_HERO_KILLED	}
end
function modifier_okada_manslayer_passive:OnHeroDiedNearby( hVictim, hKiller, kv )
	if hVictim == nil or hKiller == nil then
		return
	end
	if hKiller == self:GetCaster() or ((hVictim:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() < 300 and hVictim:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() )then
		self:ActivateThirst()
	end
end
function modifier_okada_manslayer_passive:ActivateThirst()
	if not self.pepega then
			self.pepega = 1
			self.parent = self:GetParent()
			self.player_id = self.parent:GetPlayerOwnerID()
			self.player = PlayerResource:GetPlayer(self.player_id)
			self.ability = self:GetAbility()
	end
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_okada_manslayer", {duration = self.ability:GetSpecialValueFor("passive_duration")})
	if self.parent.OkadaSa2Acquired then
		self:GetAbility():EndCooldown()
		 self.parent:Heal(self.parent:GetMaxHealth() * 0.25, self.ability)
		 self.parent:GiveMana(self.parent:GetMaxMana() * 0.25)
		 self.parent:FindAbilityByName("okada_flashblade")
		 self.parent:FindAbilityByName("okada_reduced_earth")
		local targets = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _,v in pairs(targets) do
    		if not v:HasModifier("modifier_murderer_mist_in") then
			self.OverheadFx = ParticleManager:CreateParticle( "particles/zlodemon/zlodemon_overhead_eye.vpcf", PATTACH_OVERHEAD_FOLLOW, v )
			ParticleManager:SetParticleControl( self.OverheadFx , 1, Vector( 1,0.1,0.1 ) )
			ParticleManager:SetParticleControl( self.OverheadFx , 2, Vector( 5,0,0 ) )
			ParticleManager:ReleaseParticleIndex(self.OverheadFx)
			v:AddNewModifier(self.parent, self, "modifier_vision_provider", { duration = 5 })
			end
		end
    end

end
function modifier_okada_manslayer_passive:OnHeroKilled(args)
	if args.target:IsHero() and args.attacker == self:GetParent() then
		if IsServer() then
			self:ActivateThirst()
		end
	end
end
