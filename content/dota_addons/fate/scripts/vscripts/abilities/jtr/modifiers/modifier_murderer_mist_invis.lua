modifier_murderer_mist_invis = class({})

LinkLuaModifier("modifier_murderer_mist_slow", "abilities/jtr/modifiers/modifier_murderer_mist_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderer_mist_invis_cd", "abilities/jtr/modifiers/modifier_murderer_mist_invis_cd", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function modifier_murderer_mist_invis:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
	MODIFIER_EVENT_ON_ABILITY_USED,
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS  }
end

function modifier_murderer_mist_invis:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

if IsServer() then 
	function modifier_murderer_mist_invis:OnCreated(args)
		self.initpos = self:GetParent():GetAbsOrigin()
		self.State = {}
		self.SlowPct = args.SlowPct
		self.OnHitDamage = args.BaseAgiDmg + (args.AgiDmg * self:GetParent():GetAgility() / 100)
		self.radius = self:GetAbility():GetSpecialValueFor("reveal_radius")

		if self:GetParent().InformationErasureAcquired then
			self.radius = self:GetAbility():GetSpecialValueFor("ie_radius")
		end

		self.ring_fx = ParticleManager:CreateParticleForTeam("particles/clinkz_death_pact_buff_ring_rope_bright.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), self:GetParent():GetTeamNumber()) --i am kinda drunk right now so particle radius is written in particle itself (position along ring -> initial radius) cause no freaking idea how to make it linked to CP and i don't want to fuck with it right now (i know it's possible and maybe easy, but i'm a lazy ass)
		ParticleManager:SetParticleControl(self.ring_fx, 2, self:GetParent():GetAbsOrigin())	
		ParticleManager:SetParticleControl(self.ring_fx, 3, Vector(self.radius, 0, 0))

		self:StartIntervalThink(0.033)
	end

	function modifier_murderer_mist_invis:OnRefresh(args)
		self:OnDestroy(args)
		self:OnCreated(args)
	end

	function modifier_murderer_mist_invis:OnDestroy()
		ParticleManager:DestroyParticle(self.ring_fx, false)
		ParticleManager:ReleaseParticleIndex(self.ring_fx)
	end

	function modifier_murderer_mist_invis:OnIntervalThink()
		local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		local kappa = true
		local kappa1 = true
		ParticleManager:SetParticleControl(self.ring_fx, 2, self:GetParent():GetAbsOrigin())
		for i,j in pairs(targets) do
			kappa = false
		end
		if (self:GetParent():GetAbsOrigin()-self.initpos):Length2D() > self:GetAbility():GetSpecialValueFor("radius") then
			kappa1 = false
		end
		if ((kappa and kappa1) or self:GetParent():HasModifier("modifier_whitechapel_murderer"))
		and not (self:GetParent():HasModifier("modifier_inside_marble") or self:GetParent():HasModifier("modifier_jeanne_vision" or self:GetParent():HasModifier("modifier_sex_scroll_slow"))) then
			self.State = { [MODIFIER_STATE_INVISIBLE] = true,
					   	   --[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true
					   	   }
			self.hidden = false
		else
			if self.hidden == false then
				LoopOverPlayers(function(player, playerID, playerHero)
			        --print("looping through " .. playerHero:GetName())
			        if playerHero.voice == true then
			            -- apply legion horn vsnd on their client
			            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Twitch_"..math.random(1,4)})
			            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			        end
    			end)
    		end
			self.State = {}
			self.hidden = true
			--print("pidor")
		end
	end

	function modifier_murderer_mist_invis:CheckState()
		return self.State
	end

	function modifier_murderer_mist_invis:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		args.attacker:AddNewModifier(args.attacker, self:GetAbility(),"modifier_murderer_mist_invis_cd", {Duration = 1})

		--if not IsFacingUnit(args.target, args.attacker, 90) then
		--	DoDamage(args.attacker, args.target, self.OnHitDamage, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)

		--	if not IsImmuneToSlow(args.target) then
			--	args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_murderer_mist_slow", { Duration = 0.4,
			--																								  SlowPct = self.SlowPct })
		--	end
		--	args.target:EmitSound("jtr_backstab")
		-- end
	end
	function modifier_murderer_mist_invis:OnAbilityUsed(args)
		if args.caster ~= self:GetParent() then return end

		args.caster:AddNewModifier(args.caster, self:GetAbility(),"modifier_murderer_mist_invis_cd", {Duration = 1})

		--if not IsFacingUnit(args.target, args.attacker, 90) then
		--	DoDamage(args.attacker, args.target, self.OnHitDamage, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)

		--	if not IsImmuneToSlow(args.target) then
			--	args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_murderer_mist_slow", { Duration = 0.4,
			--																								  SlowPct = self.SlowPct })
		--	end
		--	args.target:EmitSound("jtr_backstab")
		-- end
	end
end

function modifier_murderer_mist_invis:IsHidden()
	return self.hidden
end

function modifier_murderer_mist_invis:GetEffectName()
	return "particles/generic_hero_status/status_invisibility_start.vpcf"
end

function modifier_murderer_mist_invis:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_murderer_mist_invis:GetTexture()
	return "custom/jtr/murderer_mist"
end

function modifier_murderer_mist_invis:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_murderer_mist_invis:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_murderer_mist_invis:GetAuraRadius()
	return 0--800
end

function modifier_murderer_mist_invis:GetModifierAura()
	return "modifier_vision_provider"
end

function modifier_murderer_mist_invis:RemoveOnDeath()
	return true
end

function modifier_murderer_mist_invis:IsDebuff()
	return false 
end

function modifier_murderer_mist_invis:IsAura()
	return true 
end