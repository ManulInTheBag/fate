LinkLuaModifier("modifier_tsubame_mai", "abilities/sasaki/false_assassin_tsubame_mai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tsubame_mai_omnislash", "abilities/sasaki/false_assassin_tsubame_mai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tsubame_mai_cooldown", "abilities/sasaki/false_assassin_tsubame_mai", LUA_MODIFIER_MOTION_NONE)

false_assassin_tsubame_mai = class({})

function false_assassin_tsubame_mai:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	if not caster:IsRealHero() then
		ability:EndCooldown()
		return
	end
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_tsubame_mai", {})
	caster:AddNewModifier(caster, self, "modifier_tsubame_mai", {duration = 3})
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))
	caster:AddNewModifier(caster, self, "modifier_tsubame_mai_cooldown", {duration = ability:GetCooldown(1)})
end

modifier_tsubame_mai = class({})

function modifier_tsubame_mai:DeclareFunctions()
	local funcs = { 
			--MODIFIER_EVENT_ON_ATTACK_LANDED,
			--MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		}
	return funcs
end

function modifier_tsubame_mai:GetModifierIncomingDamage_Percentage()
	return -90
end

function modifier_tsubame_mai:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
	local caster = self:GetParent()
	local attacker = args.attacker
	local damageTaken = args.damage

	-- if caster is alive and damage is above threshold, do something
	if caster:GetHealth() ~= 0 and (caster:GetAbsOrigin()-attacker:GetAbsOrigin()):Length2D() < 3000 and not attacker:IsInvulnerable() and caster:GetTeam() ~= attacker:GetTeam() then
		caster:AddNewModifier(caster, self:GetAbility(), "modifier_tsubame_mai_omnislash", {duration = 5})
		caster:FindModifierByName("modifier_tsubame_mai_omnislash"):Omnislash(attacker)
	end
end

function modifier_tsubame_mai:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.parent = self:GetParent()
	self.parent:AddNewModifier(caster, self:GetAbility(), "modifier_tsubame_mai_omnislash", {duration = 5})
	self.parent:FindModifierByName("modifier_tsubame_mai_omnislash"):Omnislash(args.target)
end

modifier_tsubame_mai_omnislash = class({})

function modifier_tsubame_mai_omnislash:IsHidden() return true end

function modifier_tsubame_mai_omnislash:Omnislash(initialtarget)
	self.parent = self:GetParent()
	self.target = initialtarget
	ApplyAirborne(self.parent, initialtarget, 2.0)
	FindClearSpaceForUnit(self.parent, self.target:GetAbsOrigin() + RandomVector(100), false)
	giveUnitDataDrivenModifier(self.parent, self.parent, "jump_pause", 5)
	self.parent:RemoveModifierByName("modifier_tsubame_mai")
	EmitGlobalSound("FA.Owarida")
	EmitGlobalSound("FA.Quickdraw")

	local slash_rate = (self.parent:GetSecondsPerAttack() / 2)
	if IsServer() then
		self:StartIntervalThink(slash_rate)
	end
end

function modifier_tsubame_mai_omnislash:OnIntervalThink()
	self.nearby_enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		500,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	if #self.nearby_enemies >= 1 then
		for _,enemy in pairs(self.nearby_enemies) do
			local previous_position = self.parent:GetAbsOrigin()
			-- Used to be 128 but it seems to interrupt a lot at fast speeds if there's Lotus battles...
			FindClearSpaceForUnit(self.parent, enemy:GetAbsOrigin() + RandomVector(100), false)

			CreateSlashFx(caster, enemy:GetAbsOrigin()+RandomVector(400), enemy:GetAbsOrigin()+RandomVector(400))
			

			local current_position = self.parent:GetAbsOrigin()

			-- Face the enemy every slash
			self.parent:FaceTowards(enemy:GetAbsOrigin())

			StartAnimation(self.parent, {duration=self.parent:GetSecondsPerAttack()/2, activity=ACT_DOTA_ATTACK, rate=0.5*2/self.parent:GetSecondsPerAttack()})
			
			-- Provide vision of the target for a short duration
			AddFOWViewer(self.parent:GetTeamNumber(), enemy:GetAbsOrigin(), 200, 1, false)

			-- Perform the slash
			self.slash = true
			
			self.parent:PerformAttack(enemy, true, true, true, true, true, false, false)

			-- If the target is not Roshan or a hero, instantly kill it

			-- Play hit sound
			enemy:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
			self.parent:EmitSound("Hero_Juggernaut.OmniSlash.Damage")

			-- Play hit particle on the current target
			local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControl(hit_pfx, 0, current_position)
			ParticleManager:SetParticleControl(hit_pfx, 1, current_position)
			ParticleManager:ReleaseParticleIndex(hit_pfx)

			-- Play particle trail when moving
			local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_ABSORIGIN, self.parent)
			ParticleManager:SetParticleControl(trail_pfx, 0, previous_position)
			ParticleManager:SetParticleControl(trail_pfx, 1, current_position)
			ParticleManager:ReleaseParticleIndex(trail_pfx)

			if self.last_enemy ~= enemy then
				local dash_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_dash.vpcf", PATTACH_ABSORIGIN, self.parent)
				ParticleManager:SetParticleControl(dash_pfx, 0, previous_position)
				ParticleManager:SetParticleControl(dash_pfx, 2, current_position)
				ParticleManager:ReleaseParticleIndex(dash_pfx)
			end

			self.last_enemy = enemy
			break
		end
	else
		self.parent:RemoveModifierByName("jump_pause")
		self:Destroy()
	end
end

modifier_tsubame_mai_cooldown = class({})

function modifier_tsubame_mai_cooldown:GetTexture()
	return "custom/false_assassin_tsubame_mai"
end

function modifier_tsubame_mai_cooldown:IsHidden()
	return false 
end

function modifier_tsubame_mai_cooldown:RemoveOnDeath()
	return false
end

function modifier_tsubame_mai_cooldown:IsDebuff()
	return true 
end

function modifier_tsubame_mai_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end