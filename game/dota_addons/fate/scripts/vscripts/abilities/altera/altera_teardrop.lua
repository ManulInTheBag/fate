LinkLuaModifier("modifier_altera_teardrop_anim", "abilities/altera/altera_teardrop", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_teardrop_thinker", "abilities/altera/altera_teardrop", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_teardrop_slow", "abilities/altera/altera_teardrop", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_teardrop_cooldown", "abilities/altera/altera_teardrop", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_combo_window", "abilities/altera/altera_teardrop", LUA_MODIFIER_MOTION_NONE)

altera_teardrop = class({})

function altera_teardrop:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_altera_teardrop_cooldown", {duration = self:GetCooldown(1)/2})

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1)/2)

	self:EndCooldown()
    self:StartCooldown(self:GetCooldown(1)/2)

	local attach = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_laser"))

	caster:AddNewModifier(caster, self, "modifier_altera_teardrop_anim", {duration = 0.5})
	EmitGlobalSound("altera_teardrop_1")
	caster:EmitSound("altera_teardrop_laser")

	local laser = ParticleManager:CreateParticle("particles/altera/altera_teardrop_laser.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( laser, 1, attach)
	ParticleManager:SetParticleControl( laser, 9, caster:GetAbsOrigin() - caster:GetLeftVector()*2000 + caster:GetForwardVector()*100 + Vector(0, 0, 2700))

	caster:AddNewModifier(caster, self, "modifier_altera_combo_window", {duration = 10})
end

modifier_altera_combo_window = class({})

function modifier_altera_combo_window:IsHidden() return false end
function modifier_altera_combo_window:IsDebuff() return false end
function modifier_altera_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(5):GetName() == "altera_teardrop" then	    		
			caster:SwapAbilities("altera_teardrop_release", "altera_teardrop", true, false)	
		end
	end
end
function modifier_altera_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(5):GetName() == "altera_teardrop_release" then
			caster:SwapAbilities("altera_teardrop_release", "altera_beam", false, true)
		end
	end
end

modifier_altera_teardrop_anim = class({})

function modifier_altera_teardrop_anim:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_altera_teardrop_anim:IsHidden() return true end

------------

altera_teardrop_release = class({})

function altera_teardrop_release:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function altera_teardrop_release:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function altera_teardrop_release:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local abil = caster:FindAbilityByName("altera_teardrop")
	caster:AddNewModifier(caster, self, "modifier_altera_teardrop_cooldown", {duration = abil:GetCooldown(1)})

	local masterCombo = caster.MasterUnit2:FindAbilityByName(abil:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(abil:GetCooldown(-1))
    local ultability = caster:FindAbilityByName("altera_beam")
    ultability:EndCooldown()
    ultability:StartCooldown(ultability:GetCooldown(-1))
	abil:EndCooldown()
    abil:StartCooldown(abil:GetCooldown(-1))

	local impact_damage = self:GetSpecialValueFor("impact_damage")
	local beam_damage = self:GetSpecialValueFor("beam_damage")

	caster:RemoveModifierByName("modifier_altera_combo_window")

	Timers:CreateTimer(1.0, function()
		SpawnVisionDummy(caster, target, self:GetAOERadius() + 200, 4.5, false)
	end)

	Timers:CreateTimer(2.0, function()
		local marker = ParticleManager:CreateParticle( "particles/altera/altera_teardrop_marker.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( marker, 0, target)
		ParticleManager:SetParticleControl( marker, 1, target)
	end)

	EmitGlobalSound("altera_teardrop_2")
	Timers:CreateTimer(0.2, function()
		EmitGlobalSound("altera_teardrop_charge")
	end)
	Timers:CreateTimer(1.5, function()
		EmitGlobalSound("altera_teardrop_3")
	end)
	Timers:CreateTimer(3.5, function()
		EmitSoundOnLocationWithCaster(target, "altera_teardrop_impact", caster)
		local laser = ParticleManager:CreateParticle( "particles/altera/altera_teardrop_beam.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( laser, 0, target + Vector(0,0,3000))
		ParticleManager:SetParticleControl( laser, 1, target)

		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(laser, false)
			ParticleManager:ReleaseParticleIndex(laser)
		end)

		CreateModifierThinker(caster, self, "modifier_altera_teardrop_thinker", { Duration = 1.65,
																			 Damage = beam_damage,
																			 Radius = self:GetAOERadius()}
																			, target, caster:GetTeamNumber(), false)

		local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

		for i = 1, #targets do
			print("zuzup2")
			DoDamage(caster, targets[i], impact_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end)
end

-----------

modifier_altera_teardrop_thinker = class({})

if IsServer() then
	function modifier_altera_teardrop_thinker:OnCreated(args)
		self.Damage = args.Damage
		self.Radius = args.Radius

		self.ThinkCount = 0

		self:StartIntervalThink(0.1)
	end

	function modifier_altera_teardrop_thinker:OnIntervalThink()
		local location = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local damage = self.Damage

		for i = 1, #targets do
			damage = self.Damage

			DoDamage(caster, targets[i], damage/15, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			targets[i]:AddNewModifier(caster, ability, "modifier_altera_teardrop_slow", { Duration = 0.3 })
		end

		self.ThinkCount = self.ThinkCount + 1

		if self.ThinkCount >= 15 then
			self:Destroy()
		end
	end
end

modifier_altera_teardrop_slow = class({})

function modifier_altera_teardrop_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_altera_teardrop_slow:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

function modifier_altera_teardrop_slow:IsHidden()
	return true 
end

---

modifier_altera_teardrop_cooldown = class({})

function modifier_altera_teardrop_cooldown:GetTexture()
	return "custom/altera/altera_teardrop"
end

function modifier_altera_teardrop_cooldown:IsHidden()
	return false 
end

function modifier_altera_teardrop_cooldown:RemoveOnDeath()
	return false
end

function modifier_altera_teardrop_cooldown:IsDebuff()
	return true 
end

function modifier_altera_teardrop_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end