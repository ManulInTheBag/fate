LinkLuaModifier("modifier_ryougi_mystic_eyes_active", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_mystic_eyes_vision", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_combo_window", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_lines", "abilities/ryougi/ryougi_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

ryougi_mystic_eyes = class({})

function ryougi_mystic_eyes:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("ryougi_eyes")

	if caster:HasModifier("modifier_ryougi_pure_knowledge") then
		caster:AddNewModifier(caster, self, "modifier_item_ward_true_sight", {true_sight_range = self:GetSpecialValueFor("true_sight_range"), duration = self:GetSpecialValueFor("duration")})
		caster:AddNewModifier(caster, self, "modifier_ryougi_mystic_eyes_vision", {duration = self:GetSpecialValueFor("duration")})
	end

	if caster.SelflessKnowledgeAcquired then
		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for i = 1, #enemies do
			if enemies[i]:HasModifier("modifier_ryougi_lines") then
				enemies[i]:AddNewModifier(caster, self, "modifier_vision_provider", {duration = 3})
			end
		end
	end
	
	caster:AddNewModifier(caster, self, "modifier_ryougi_mystic_eyes_active", {duration = self:GetSpecialValueFor("duration")})

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if caster:FindAbilityByName("ryougi_collapse"):IsCooldownReady() and caster:IsAlive() then	    		
	    	caster:AddNewModifier(caster, self, "modifier_ryougi_combo_window", {duration = 4})
		end
	end
end

function ryougi_mystic_eyes:CutLine(enemy, line_name, is_fan)
	local caster = self:GetCaster()

	local multiplier = 1
	if is_fan then
		multiplier = 1/6
	end

	if not enemy:IsAlive() then return end

	DoDamage(caster, enemy, caster:GetAverageTrueAttackDamage(caster)*multiplier, DAMAGE_TYPE_PHYSICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)

	if caster.DemiseAcquired then
		DoDamage(caster, enemy, (self:GetSpecialValueFor("demise_damage") + caster:GetAgility()*self:GetSpecialValueFor("agi_mult"))*multiplier, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
	end

	if not enemy:IsHero() then
		if caster:HasModifier("modifier_ryougi_mystic_eyes_active") then
			DoDamage(caster, enemy, enemy:GetMaxHealth()*0.1*multiplier, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
		end
		return
	end

	if not caster:HasModifier("modifier_ryougi_mystic_eyes_active") then return end

	if not enemy:HasModifier("modifier_ryougi_lines") then
		local modifier = enemy:AddNewModifier(caster, self, "modifier_ryougi_lines", {duration = self:GetSpecialValueFor("line_duration")})
		modifier.lines[line_name] = true
		modifier:SetStackCount(1)
	else
		local modifier = enemy:FindModifierByName("modifier_ryougi_lines")
		if not modifier.lines[line_name] then
			modifier.lines[line_name] = true
			if modifier:GetStackCount() == 9 then
				enemy:AddNewModifier(caster, self, "modifier_ryougi_lines", {duration = 120})
			else
				enemy:AddNewModifier(caster, self, "modifier_ryougi_lines", {duration = self:GetSpecialValueFor("line_duration")})
			end
			modifier:SetStackCount(modifier:GetStackCount() + 1)
			if modifier:GetStackCount()%4 == 0 then
				giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("stun_duration"))
				--enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
			end
		end
	end
end

modifier_ryougi_combo_window = class({})

function modifier_ryougi_combo_window:IsHidden() return true end
function modifier_ryougi_combo_window:IsDebuff() return false end
function modifier_ryougi_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(5):GetName() == "ryougi_mystic_eyes" then	    		
			caster:SwapAbilities("ryougi_collapse", "ryougi_mystic_eyes", true, false)	
		end
	end
end
function modifier_ryougi_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(5):GetName() == "ryougi_collapse" then
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

		local damage = self.ability:GetSpecialValueFor("immediate_damage")*self.parent:GetMaxHealth()/100

		DoDamage(self.caster, self.parent, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)

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

		EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.parent)

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_ryougi_lines:OnRefresh()
	if IsServer() then
		local damage = self.ability:GetSpecialValueFor("immediate_damage")*self.parent:GetMaxHealth()/100

		DoDamage(self.caster, self.parent, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.ability, false)

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

		EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.parent)
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