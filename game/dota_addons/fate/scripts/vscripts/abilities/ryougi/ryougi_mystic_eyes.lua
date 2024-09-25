LinkLuaModifier("modifier_ryougi_mystic_eyes_active", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_mystic_eyes_vision", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_combo_window", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_lines", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_ik", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)

ryougi_mystic_eyes = class({})

function ryougi_mystic_eyes:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("ryougi_eyes")

	if caster:HasModifier("modifier_ryougi_pure_knowledge") then
		caster:AddNewModifier(caster, self, "modifier_item_ward_true_sight", {true_sight_range = self:GetSpecialValueFor("true_sight_range"), duration = self:GetSpecialValueFor("duration")})
		caster:AddNewModifier(caster, self, "modifier_ryougi_mystic_eyes_vision", {duration = self:GetSpecialValueFor("duration")})
	end

	--[[if caster.SelflessKnowledgeAcquired then
		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for i = 1, #enemies do
			if enemies[i]:HasModifier("modifier_ryougi_lines") then
				enemies[i]:AddNewModifier(caster, self, "modifier_vision_provider", {duration = 3})
			end
		end
	end]]
	
	--caster:AddNewModifier(caster, self, "modifier_ryougi_mystic_eyes_active", {duration = self:GetSpecialValueFor("duration")})

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if caster:FindAbilityByName("ryougi_collapse"):IsCooldownReady() and caster:IsAlive() then	    		
	    	caster:AddNewModifier(caster, self, "modifier_ryougi_combo_window", {duration = 4})
		end
	end
end

function ryougi_mystic_eyes:OnOwnerDied()
	LoopOverHeroes(function(hero)
    	hero:RemoveModifierByName("modifier_ryougi_lines")
    end)
end

function ryougi_mystic_eyes:CutLine(enemy, line_name, is_fan)
	local caster = self:GetCaster()

	if not enemy:IsAlive() then return end

	local multiplier = 1
	if is_fan then
		multiplier = 1/6
	end

	if caster.DemiseAcquired then
		DoDamage(caster, enemy, (self:GetSpecialValueFor("demise_damage") + caster:GetAgility()*self:GetSpecialValueFor("agi_mult"))*multiplier, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
		if not enemy:IsAlive() then return end
	end

	local damage = self:GetSpecialValueFor("immediate_damage")*enemy:GetMaxHealth()/100

	DoDamage(caster, enemy, damage*multiplier, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NONE, self, false)
	--DoDamage(self.caster, self.parent, damage/2, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)

	local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		enemy,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		enemy:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, (caster:GetOrigin()-enemy:GetOrigin()):Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	if caster.KiyohimePassingAcquired then
		caster:GiveMana(self:GetSpecialValueFor("mana_restore"))
	end

	EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", enemy)

	if not enemy:IsAlive() then return end

	--if not caster:HasModifier("modifier_ryougi_mystic_eyes_active") then return end

	if not enemy:HasModifier("modifier_ryougi_lines") then
		local modifier = enemy:AddNewModifier(caster, self, "modifier_ryougi_lines", {duration = self:GetSpecialValueFor("line_duration")})
		modifier.lines[line_name] = true
		modifier:SetStackCount(1)
	else
		enemy:AddNewModifier(caster, self, "modifier_ryougi_lines", {duration = self:GetSpecialValueFor("line_duration")})
		local modifier = enemy:FindModifierByName("modifier_ryougi_lines")
		if not modifier.lines[line_name] then
			modifier.lines[line_name] = true
			modifier:SetStackCount(modifier:GetStackCount() + 1)
		end
	end
end

function ryougi_mystic_eyes:LastArc(enemy)
	local caster = self:GetCaster()

	enemy:Kill(self, caster)
	EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", enemy)

	--part temporary removed because bugging

	--[[local player_id = enemy:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(player_id)

	enemy:AddEffects(EF_NODRAW)

	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_wind_start"})

	Timers:CreateTimer(1.5, function()
		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_ik_start"})
	end)

	local hParticle3 = ParticleManager:CreateParticleForPlayer("particles/ryougi/ryougi_afterimages_2.vpcf",  PATTACH_ABSORIGIN, enemy, player)
	ParticleManager:SetParticleControl(hParticle3, 0, GetGroundPosition(enemy:GetAbsOrigin() + enemy:GetForwardVector()*300, enemy))
	ParticleManager:SetParticleShouldCheckFoW(hParticle3, false)

	enemy:AddNewModifier(caster, self, "modifier_ryougi_ik", {duration = 10})

	local hParticle4 = ParticleManager:CreateParticleForPlayer("particles/ryougi/ryougi_flash.vpcf",  PATTACH_ABSORIGIN, enemy, player)
	ParticleManager:SetParticleControl(hParticle4, 0, enemy:GetAbsOrigin())
	ParticleManager:SetParticleShouldCheckFoW(hParticle4, false)

	Timers:CreateTimer(0.6, function()
		ParticleManager:DestroyParticle(hParticle4, false)
		ParticleManager:ReleaseParticleIndex(hParticle4)
	end)

	Timers:CreateTimer(3.0, function()
		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_chimes"})
	end)

	Timers:CreateTimer(5.1, function()
		ParticleManager:DestroyParticle(hParticle3, true)
		ParticleManager:ReleaseParticleIndex(hParticle3)

		local hParticle = ParticleManager:CreateParticleForPlayer("particles/ryougi/ryougi_afterimages.vpcf",  PATTACH_ABSORIGIN, enemy, player)
		ParticleManager:SetParticleControl(hParticle, 0, GetGroundPosition(enemy:GetAbsOrigin() + enemy:GetForwardVector()*200, enemy))
		ParticleManager:SetParticleShouldCheckFoW(hParticle, false)
		ParticleManager:DestroyParticle(hParticle, false)
		ParticleManager:ReleaseParticleIndex(hParticle)
		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_slash"})

		Timers:CreateTimer(0.2, function()
			local hParticle2 = ParticleManager:CreateParticleForPlayer("particles/ryougi/ryougi_flash.vpcf",  PATTACH_ABSORIGIN, enemy, player)
			ParticleManager:SetParticleControl(hParticle2, 0, enemy:GetAbsOrigin())
			ParticleManager:SetParticleShouldCheckFoW(hParticle2, false)
			Timers:CreateTimer(0.6, function()
				ParticleManager:DestroyParticle(hParticle2, false)
				ParticleManager:ReleaseParticleIndex(hParticle2)
				hParticle = ParticleManager:CreateParticleForPlayer("particles/ryougi/ryougi_afterimages_3.vpcf",  PATTACH_ABSORIGIN, enemy, player)
				ParticleManager:SetParticleControl(hParticle, 0, GetGroundPosition(enemy:GetAbsOrigin() - enemy:GetForwardVector()*300, enemy))
				ParticleManager:SetParticleShouldCheckFoW(hParticle, false)
				Timers:CreateTimer(0.9, function()
					ParticleManager:DestroyParticle(hParticle, false)
					ParticleManager:ReleaseParticleIndex(hParticle)
				end)
			end)
			Timers:CreateTimer(0.9, function()
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_ik_end"})
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ryougi_wind_end"})
			end)
		end)
		Timers:CreateTimer(1.8, function()
			enemy:RemoveEffects(EF_NODRAW)
			enemy:Kill(self, caster)
		end)
	end)]]
end

modifier_ryougi_combo_window = class({})

function modifier_ryougi_combo_window:IsHidden() return true end
function modifier_ryougi_combo_window:IsDebuff() return false end
function modifier_ryougi_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "ryougi_mystic_eyes" then	    		
			caster:SwapAbilities("ryougi_collapse", "ryougi_mystic_eyes", true, false)	
		end
	end
end
function modifier_ryougi_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "ryougi_collapse" then
			caster:SwapAbilities("ryougi_collapse", "ryougi_mystic_eyes", false, true)
		end
	end
end

modifier_ryougi_mystic_eyes_active = class({})

function modifier_ryougi_mystic_eyes_active:IsHidden() return false end
function modifier_ryougi_mystic_eyes_active:IsDebuff() return false end

modifier_ryougi_mystic_eyes_vision = class({})

function modifier_ryougi_mystic_eyes_vision:IsHidden() return true end
function modifier_ryougi_mystic_eyes_vision:IsDebuff() return false end

function modifier_ryougi_mystic_eyes_vision:DeclareFunctions()
	return {	MODIFIER_PROPERTY_BONUS_DAY_VISION,
				MODIFIER_PROPERTY_BONUS_NIGHT_VISION }
end

function modifier_ryougi_mystic_eyes_vision:GetBonusDayVision()
	return self:GetAbility():GetSpecialValueFor("bonus_vision")
end
function modifier_ryougi_mystic_eyes_vision:GetBonusNightVision()
	return self:GetAbility():GetSpecialValueFor("bonus_vision")
end

modifier_ryougi_lines = class({})

function modifier_ryougi_lines:IsHidden() return false end
function modifier_ryougi_lines:IsDebuff() return true end

function modifier_ryougi_lines:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_ryougi_lines:GetModifierProvidesFOWVision()
	return self:CanBeDetected()
end

function modifier_ryougi_lines:CanBeDetected(hHero)
    if not (self:GetCaster().SelflessKnowledgeAcquired and self:GetCaster():IsAlive() and self:GetStackCount() >= 4) or self:GetParent():HasModifier("modifier_murderer_mist_in") then
        return 0
    end
    
    return 1
end

function modifier_ryougi_lines:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()

		self.lines = {}

		local hParticle2 = ParticleManager:CreateParticle("particles/ryougi/ryougi_line_status.vpcf",  PATTACH_ABSORIGIN, self.parent)
		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(hParticle2, false)
			ParticleManager:ReleaseParticleIndex(hParticle2)
		end)

		--[[local damage = self.ability:GetSpecialValueFor("immediate_damage")*self.parent:GetMaxHealth()/100

		DoDamage(self.caster, self.parent, damage/2, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)
		DoDamage(self.caster, self.parent, damage/2, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)

		local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self.parent,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			self.parent:GetOrigin(), -- unknown
			true -- unknown, true
		)
		ParticleManager:SetParticleControlForward( effect_cast, 1, (self.caster:GetOrigin()-self.parent:GetOrigin()):Normalized() )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		self.caster:GiveMana(self.ability:GetSpecialValueFor("mana_restore"))

		EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.parent)]]

		--self:StartIntervalThink(FrameTime())
	end
end

function modifier_ryougi_lines:OnRefresh()
	if IsServer() then
		--[[local damage = self.ability:GetSpecialValueFor("immediate_damage")*self.parent:GetMaxHealth()/100

		DoDamage(self.caster, self.parent, damage/2, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)
		DoDamage(self.caster, self.parent, damage/2, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)

		local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self.parent,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			self.parent:GetOrigin(), -- unknown
			true -- unknown, true
		)
		ParticleManager:SetParticleControlForward( effect_cast, 1, (self.caster:GetOrigin()-self.parent:GetOrigin()):Normalized() )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		self.caster:GiveMana(self.ability:GetSpecialValueFor("mana_restore"))

		EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.parent)]]
	end
end

function modifier_ryougi_lines:OnIntervalThink()
	if IsServer() then
		local max_hp = self.parent:GetMaxHealth()
		local hp = self.parent:GetHealth()

		local line_count = self:GetStackCount()
		local health_percent = self.ability:GetSpecialValueFor("health_percent")

		local active_hp = max_hp * (1 - line_count*health_percent/100)

		if hp < active_hp then return end

		if active_hp <= 0 then
			if (hp - FrameTime()*0.1*max_hp*line_count*health_percent/100) <= 0 then
				--self.parent:Kill(self.ability, self.caster)
				DoDamage(self.caster, self.parent, 10, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)
				hp = self.parent:GetHealth()
				if (hp - FrameTime()*0.1*max_hp*line_count*health_percent/100) <= 0 then
					self.parent:Kill(self.ability, self.caster)
				end
				return
			end
			self.parent:SetHealth(hp - FrameTime()*0.1*max_hp*line_count*health_percent/100)
		else
			self.parent:SetHealth(math.max(hp - FrameTime()*0.1*max_hp*line_count*health_percent/100, active_hp))
		end
	end
end

modifier_ryougi_ik = class({})

function modifier_ryougi_ik:IsHidden() return true end

function modifier_ryougi_ik:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end