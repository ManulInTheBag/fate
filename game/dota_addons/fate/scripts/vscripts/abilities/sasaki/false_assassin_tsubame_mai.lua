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
	if caster:GetHealth() ~= 0 and (caster:GetAbsOrigin()-attacker:GetAbsOrigin()):Length2D() < 3000 and not attacker:IsInvulnerable() and caster:GetTeam() ~= attacker:GetTeam() and attacker:IsConsideredHero() then
		self:MaiBuffer(attacker)
		--[[caster:AddNewModifier(caster, self:GetAbility(), "modifier_tsubame_mai_omnislash", {duration = 5})
		caster:FindModifierByName("modifier_tsubame_mai_omnislash"):TsubameMai(attacker)]]
	end
end

function modifier_tsubame_mai:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	if not args.target:IsConsideredHero() then return end
	self.parent = self:GetParent()
	self:MaiBuffer(args.target)
	--[[self.parent:AddNewModifier(caster, self:GetAbility(), "modifier_tsubame_mai_omnislash", {duration = 5})
	self.parent:FindModifierByName("modifier_tsubame_mai_omnislash"):TsubameMai(args.target)]]
end

function modifier_tsubame_mai:MaiBuffer(initialtarget)
	self.parent = self:GetParent()
	self.parent:AddNewModifier(caster, self:GetAbility(), "modifier_tsubame_mai_omnislash", {duration = 5})
	self.parent:FindModifierByName("modifier_tsubame_mai_omnislash"):TsubameMai(initialtarget)
end

modifier_tsubame_mai_omnislash = class({})

function modifier_tsubame_mai_omnislash:IsHidden() return true end

function modifier_tsubame_mai_omnislash:TsubameMai(initialtarget)
	local caster = self:GetParent()
	local target = initialtarget
	local ability = self:GetAbility()

	caster:FindAbilityByName("sasaki_tsubame_gaeshi"):StartCooldown(caster:FindAbilityByName("sasaki_tsubame_gaeshi"):GetCooldown(-1))

	local dummy = CreateUnitByName("godhand_res_locator", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	dummy:AddNewModifier(caster, nil, "modifier_phased", {duration=4})
	dummy:AddNewModifier(caster, nil, "modifier_kill", {duration=4})

	--[[local tgabil = caster:FindAbilityByName("sasaki_tsubame_gaeshi")
	keys.Damage = tgabil:GetLevelSpecialValueFor("damage", tgabil:GetLevel()-1)
	keys.LastDamage = tgabil:GetLevelSpecialValueFor("lasthit_damage", tgabil:GetLevel()-1)
	keys.StunDuration = tgabil:GetLevelSpecialValueFor("stun_duration", tgabil:GetLevel()-1)
	keys.GCD = 0]]

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100)
	caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0}) 
	ApplyAirborne(caster, target, 2.0)
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 2.3)
	caster:RemoveModifierByName("modifier_tsubame_mai")
	--EmitGlobalSound("FA.Owarida")
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_owarida"})

			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		else
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="FA.Owarida"})
		end

	end)
	EmitGlobalSound("FA.Quickdraw")
	CreateSlashFx(caster, target:GetAbsOrigin()+Vector(300, 300, 0), target:GetAbsOrigin()+Vector(-300,-300,0))

	local tsubame = caster:FindAbilityByName("sasaki_tsubame_gaeshi")
	--tsubame:EndCooldown()

	local slashCounter = 0
	Timers:CreateTimer(0.4, function()
		if slashCounter == 0 then caster:SetModel("models/development/invisiblebox.vmdl") end
		if slashCounter == 5 or not caster:IsAlive() then caster:SetModel("models/assassin/asn.vmdl") return end
		caster:PerformAttack( target, true, true, true, true, false, false, false )
		CreateSlashFx(caster, target:GetAbsOrigin()+RandomVector(400), target:GetAbsOrigin()+RandomVector(400))
		caster:SetAbsOrigin(target:GetAbsOrigin()+RandomVector(400))
		EmitGlobalSound("FA.Quickdraw") 

		slashCounter = slashCounter + 1
		return 0.2-slashCounter*0.03
	end)

	Timers:CreateTimer(1.0, function()
		if caster:IsAlive() and target:IsAlive() then
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,target:GetAbsOrigin().z))
			--ability:ApplyDataDrivenModifier(caster, caster, "modifier_tsubame_mai_tg_cast_anim", {})
			StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
			--EmitGlobalSound("FA.TGReady")
			LoopOverPlayers(function(player, playerID, playerHero)
				--print("looping through " .. playerHero:GetName())
				if playerHero.zlodemon == true then
					-- apply legion horn vsnd on their client
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_hiken_ready"})
		
					--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
				else
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="FA.TGReady"})
				end
		
			end)
			
			--ExecuteOrderFromTable({
			--	UnitIndex = caster:entindex(),
				--TargetIndex = target:entindex(),
				--AbilityIndex = 5,
			--	OrderType = DOTA_UNIT_ORDER_STOP,
			--	Queue = false
			--})
			caster:SetForwardVector((target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized())
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
		end
	end)

	Timers:CreateTimer(1.4, function()
		if caster:IsAlive() and target:IsAlive() then
			tsubame:TsubameGaeshi(target)
		end
	end)
end

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