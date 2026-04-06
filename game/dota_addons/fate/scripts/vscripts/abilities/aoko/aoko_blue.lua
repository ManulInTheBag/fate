LinkLuaModifier("modifier_aoko_blue_ally", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_cd", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_fx", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_shield", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_shield_decaying", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_ms", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_damage_field", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_slow", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_blue_ring_slow", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_pink_ring_haste", "abilities/aoko/aoko_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

aoko_blue = class({})

function aoko_blue:GetCastRange()
	if self:GetCaster():HasModifier("modifier_aoko_magician_attribute") then
		return (self:GetSpecialValueFor("cast_range") + self:GetSpecialValueFor("attribute_bonus_cast_range"))
	end
	return self:GetSpecialValueFor("cast_range")
end

function aoko_blue:GetAOERadius()
	return self:GetSpecialValueFor("ally_search_radius")
end

function aoko_blue:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("aoko_blue")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:RemoveModifierByName("modifier_aoko_combo_window")

    caster:AddNewModifier(caster, self, "modifier_aoko_blue_cd", {duration = self:GetCooldown(1)})

    caster:AddNewModifier(caster, self, "modifier_aoko_blue_shield", {duration = 7.5})

	local search_radius = self:GetSpecialValueFor("ally_search_radius")

	local dead = FindUnitsInRadius(caster:GetTeam(), target, nil, search_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_DEAD, FIND_CLOSEST, false)

	local target = nil

	if #dead > 0 then
		for i = 1,#dead do
			if not dead[i]:IsAlive() then
				if not dead[i]:HasModifier("modifier_god_hand_stock") and not (dead[i]:GetName() == "gille_gigantic_horror" or dead[i]:GetName() == "f16_at_vinta") then
					target = dead[i]
					break
				end
			end
		end
	end

	--[[if target then
		EmitGlobalSound("aoko_blue_2")
	else]]
		EmitGlobalSound("aoko_blue_1")
	--end

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 7.5)
	caster:AddNewModifier(caster, self, "modifier_aoko_blue_fx", {duration = 8.5, targetexists = (target and 1 or 0), target = (target and target:entindex() or 0)})
	caster:AddNewModifier(caster, self, "modifier_aoko_blue_damage_field", {duration = 7.5})

	--[[
	local enemy = PickRandomEnemy(caster)

    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 7.5 })
    end

    AddFOWViewer(2, caster:GetAbsOrigin(), 40, 3.3, false)
	AddFOWViewer(3, caster:GetAbsOrigin(), 40, 3.3, false)
	]]
	Timers:CreateTimer(7.5, function()
		if not caster:IsAlive() then return end

		--if not target then
			EmitGlobalSound("aoko_blue_1_revive")
		--end

		--if caster.MagicianOfFifthAcquired then
			caster:AddNewModifier(caster, self, "modifier_aoko_blue_shield_decaying", {duration = self:GetSpecialValueFor("end_shield_duration")})
		--end
		
		if target and not target:IsNull() and not target:IsAlive() and (_G.CurrentGameState == "FATE_ROUND_ONGOING") then
			--EmitGlobalSound("aoko_blue_2_revive")

			EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "aoko_blue_revive_sfx", caster)

			target:SetRespawnPosition(target:GetAbsOrigin())
			target:RespawnHero(false, false)
			ResetAbilities(target)
			ResetItems(target)

			target:AddNewModifier(caster, self, "modifier_aoko_blue_ally", {duration = self:GetSpecialValueFor("duration")})
			--if caster.MagicianOfFifthAcquired then
				target:AddNewModifier(caster, self, "modifier_aoko_blue_shield_decaying", {duration = self:GetSpecialValueFor("end_shield_duration")})
			--end

			target:SetRespawnPosition(target.RespawnPos)
		end

		if caster.MagicianOfFifthAcquired then
			local teammates = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)

			for _, teammate in pairs(teammates) do
				teammate:AddNewModifier(caster, self, "modifier_aoko_blue_ms", {duration = self:GetSpecialValueFor("attribute_ms_duration")})
			end
		end

		local circuits = caster:FindAbilityByName("aoko_circuits")
		circuits:StartOverload()
	end)
end

modifier_aoko_blue_ally = class({})

function modifier_aoko_blue_ally:IsHidden() return false end
function modifier_aoko_blue_ally:IsDebuff() return true end

function modifier_aoko_blue_ally:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	
	self.overhead_fx = ParticleManager:CreateParticle("particles/aoko/aoko_res_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
	self:AddParticle(self.overhead_fx, false, false, -1, false, true)
	--ParticleManager:SetParticleControl(self.runes_fx, 0, caster:GetAbsOrigin())
end

function modifier_aoko_blue_ally:OnDestroy()
	if IsServer() then
		self.parent:Kill(self.ability, self.caster)
	end
end

--

modifier_aoko_blue_fx = class({})

function modifier_aoko_blue_fx:IsHidden() return true end
function modifier_aoko_blue_fx:IsDebuff() return true end

function modifier_aoko_blue_fx:OnCreated(args)
	if IsServer() then
		self.caster = self:GetCaster()
		local caster = self.caster
		self.ability = self:GetAbility()
		local target = nil
		if args.targetexists == 1 then
			target = EntIndexToHScript(args.target)
		end

		self.radius = self.ability:GetSpecialValueFor("rings_radius")

		self.runes_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_runes.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(self.runes_fx, 0, caster:GetAbsOrigin())

		self.runes_fx_2 = nil

		if target then
			self.runes_fx_2 = ParticleManager:CreateParticle("particles/aoko/aoko_blue_runes_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(self.runes_fx_2, 0, target:GetAbsOrigin())
			
			AddFOWViewer(2, target:GetAbsOrigin(), 40, 7.5, false)
			AddFOWViewer(3, target:GetAbsOrigin(), 40, 7.5, false)
		end

		AddFOWViewer(2, caster:GetAbsOrigin(), 40, 7.5, false)
		AddFOWViewer(3, caster:GetAbsOrigin(), 40, 7.5, false)

		local green_heal = self.ability:GetSpecialValueFor("green_heal")
		local yellow_vision = self.ability:GetSpecialValueFor("yellow_vision_duration")
		local blue_slow = self.ability:GetSpecialValueFor("blue_slow_duration")
		local pink_haste = self.ability:GetSpecialValueFor("pink_haste_duration")

		print(pink_haste)

		Timers:CreateTimer(1.2, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_green.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			local allies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(allies) do
				v:ApplyHeal(green_heal, self.ability)
			end
		end)

		Timers:CreateTimer(1.7, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_yellow.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			AddFOWViewer(caster:GetTeamNumber(), caster:GetAbsOrigin(), self.radius, yellow_vision, false)
		end)

		Timers:CreateTimer(2.0, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_blue.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.3, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(enemies) do
				v:AddNewModifier(caster, self.ability, "modifier_aoko_blue_ring_slow", {duration = blue_slow})
			end
		end)

		Timers:CreateTimer(2.3, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_pink.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.2, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			local allies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(allies) do
				v:AddNewModifier(caster, self.ability, "modifier_aoko_pink_ring_haste", {duration = pink_haste})
			end
		end)

		Timers:CreateTimer(2.55, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_green.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.2, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			local allies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(allies) do
				v:ApplyHeal(green_heal, self.ability)
			end
		end)

		Timers:CreateTimer(2.75, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_yellow.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.2, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)
			AddFOWViewer(caster:GetTeamNumber(), caster:GetAbsOrigin(), self.radius, yellow_vision, false)
		end)

		Timers:CreateTimer(2.95, function()
			if not caster:IsAlive() then return end
			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_blue.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			Timers:CreateTimer(0.1, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(enemies) do
				v:AddNewModifier(caster, self.ability, "modifier_aoko_blue_ring_slow", {duration = blue_slow})
			end
		end)

		self.flowers_fx = nil

		Timers:CreateTimer(3.2, function()
			if not caster:IsAlive() then return end

			local ring_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_pulse_ring_white.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(ring_fx, 0, caster:GetAbsOrigin())

			local allies = FindUnitsInRadius(self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

			for k,v in pairs(allies) do
				HardCleanse(v)
			end

			Timers:CreateTimer(4.3, function()
				ParticleManager:DestroyParticle(ring_fx, false)
				ParticleManager:ReleaseParticleIndex(ring_fx)
			end)

			self.flowers_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_flowers.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(self.flowers_fx, 9, caster:GetAbsOrigin())
			--[[
			AddFOWViewer(2, caster:GetAbsOrigin(), 40, 4.3, false)
			AddFOWViewer(3, caster:GetAbsOrigin(), 40, 4.3, false)
			]]
			Timers:CreateTimer(4.3, function()
				ParticleManager:DestroyParticle(self.flowers_fx, false)
				ParticleManager:ReleaseParticleIndex(self.flowers_fx)
			end)
		end)
		Timers:CreateTimer(7.5, function()
			if self.runes_fx then
				ParticleManager:DestroyParticle(self.runes_fx, false)
				ParticleManager:ReleaseParticleIndex(self.runes_fx)
			end

			if self.runes_fx_2 then
				ParticleManager:DestroyParticle(self.runes_fx_2, false)
				ParticleManager:ReleaseParticleIndex(self.runes_fx_2)
			end
		end)
	end
end

function modifier_aoko_blue_fx:OnDestroy()
	if IsServer() then
		StopGlobalSound("aoko_blue")
		StopGlobalSound("aoko_blue_2")
		StopGlobalSound("aoko_blue_1")

		if self.runes_fx then
			ParticleManager:DestroyParticle(self.runes_fx, false)
			ParticleManager:ReleaseParticleIndex(self.runes_fx)
		end

		if self.runes_fx_2 then
			ParticleManager:DestroyParticle(self.runes_fx_2, false)
			ParticleManager:ReleaseParticleIndex(self.runes_fx_2)
		end

		if self.flowers_fx then
			ParticleManager:DestroyParticle(self.flowers_fx, true)
			ParticleManager:ReleaseParticleIndex(self.flowers_fx)
		end
	end
end

--

modifier_aoko_blue_cd = class({})

function modifier_aoko_blue_cd:GetTexture()
	return "custom/aoko/aoko_blue"
end

function modifier_aoko_blue_cd:IsHidden()
	return false 
end

function modifier_aoko_blue_cd:RemoveOnDeath()
	return false
end

function modifier_aoko_blue_cd:IsDebuff()
	return true 
end

function modifier_aoko_blue_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--

modifier_aoko_blue_shield = class({})

function modifier_aoko_blue_shield:IsHidden() return false end
function modifier_aoko_blue_shield:IsDebuff() return false end

function modifier_aoko_blue_shield:OnCreated()

end

function modifier_aoko_blue_shield:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_aoko_blue_shield:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now

            	local dmgtable = {
		            attacker = keys.attacker,
		            victim = keys.target,
		            damage = damage,
		            damage_type = keys.damage_type,
		            damage_flags = keys.damage_flags,
		            ability = keys.inflictor
		        }
                self:Destroy()
                ApplyDamage(dmgtable)
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_aoko_blue_shield:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
	if self.hCaster.MagicianOfFifthAcquired then
		self.fBarrierBlock = self.fBarrierBlock + self.hAbility:GetSpecialValueFor("attribute_bonus_shield")
	end
    
    --[[if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/custom/jeanne/jeanne_luminosite_eternelle_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end]]

	if IsServer() then
		--self.hCaster:EmitSound("aoko_shield_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_aoko_blue_shield:OnRefresh(hTable)
	self:OnCreated(hTable)
end

--

modifier_aoko_blue_shield_decaying = class({})

function modifier_aoko_blue_shield_decaying:IsHidden() return false end
function modifier_aoko_blue_shield_decaying:IsDebuff() return false end

function modifier_aoko_blue_shield_decaying:OnCreated()

end

function modifier_aoko_blue_shield_decaying:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_aoko_blue_shield_decaying:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now

            	local dmgtable = {
		            attacker = keys.attacker,
		            victim = keys.target,
		            damage = damage,
		            damage_type = keys.damage_type,
		            damage_flags = keys.damage_flags,
		            ability = keys.inflictor
		        }
                self:Destroy()
                ApplyDamage(dmgtable)
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_aoko_blue_shield_decaying:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("end_shield_amount")
	self.barrier_decay = self.hAbility:GetSpecialValueFor("end_shield_decay")*0.1
    
    --[[if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/custom/jeanne/jeanne_luminosite_eternelle_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end]]

	if IsServer() then
		--self.hCaster:EmitSound("aoko_shield_sfx")
		self:SetStackCount(self.fBarrierBlock)
		self:StartIntervalThink(0.1)
	end
end

function modifier_aoko_blue_shield_decaying:OnIntervalThink()
	if not IsServer() then return end

	local stacks = self:GetStackCount() - self.barrier_decay
	if stacks <= 0 then
		self:Destroy()
		return
	end
	self:SetStackCount(stacks)
end

function modifier_aoko_blue_shield_decaying:OnRefresh(hTable)
	self:OnCreated(hTable)
end

--

modifier_aoko_blue_ms = class({})

function modifier_aoko_blue_ms:IsHidden() return false end
function modifier_aoko_blue_ms:IsDebuff() return false end
function modifier_aoko_blue_ms:RemoveOnDeath() return true end
function modifier_aoko_blue_ms:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
           }
end

function modifier_aoko_blue_ms:GetModifierMoveSpeed_Absolute(keys)
    return self:GetAbility():GetSpecialValueFor("attribute_ms")
end

--

modifier_aoko_blue_damage_field = class({})

function modifier_aoko_blue_damage_field:IsHidden() return true end
function modifier_aoko_blue_damage_field:IsDebuff() return true end

function modifier_aoko_blue_damage_field:OnCreated(args)
	if IsServer() then
		self.caster = self:GetCaster()
		local caster = self.caster
		self.ability = self:GetAbility()

		self.circuits = caster:FindAbilityByName("aoko_circuits")
		self.stacks = self.ability:GetSpecialValueFor("stack_gain")

		self.time_for_stack = 7.5/self.stacks

		self.elapsed = 0
		self.gained = 0

		self.radius = self.ability:GetSpecialValueFor("damage_radius")

		self:StartIntervalThink(FrameTime())
		self:OnIntervalThink()
	end
end

function modifier_aoko_blue_damage_field:OnIntervalThink()
	if IsServer() then
		self.elapsed = self.elapsed + FrameTime()

		local diff = self.elapsed/self.time_for_stack - self.gained
		if diff > 1 then
			self.gained = self.gained + math.floor(diff)
			self.circuits:GainStacks(math.floor(diff))
		end

		local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

		for k,v in pairs(enemies) do
			v:AddNewModifier(self.caster, self.ability, "modifier_aoko_blue_slow", {duration = 0.1 + FrameTime()})
			giveUnitDataDrivenModifier(self.caster, v, "locked", 0.1)
		end
	end
end

--

modifier_aoko_blue_slow = class({})

function modifier_aoko_blue_slow:IsHidden() return false end
function modifier_aoko_blue_slow:IsDebuff() return true end
function modifier_aoko_blue_slow:RemoveOnDeath() return true end
function modifier_aoko_blue_slow:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_blue_slow:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.damage = self.ability:GetSpecialValueFor("damage_per_second")*0.1

	self:StartIntervalThink(0.1)
end

function modifier_aoko_blue_slow:OnIntervalThink()
	if not IsServer() then return end

	DoDamage(self.caster, self.parent, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end

function modifier_aoko_blue_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self.ability:GetSpecialValueFor("slow")
end

--

modifier_aoko_blue_ring_slow = class({})

function modifier_aoko_blue_ring_slow:IsHidden() return false end
function modifier_aoko_blue_ring_slow:IsDebuff() return true end
function modifier_aoko_blue_ring_slow:RemoveOnDeath() return true end
function modifier_aoko_blue_ring_slow:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_blue_ring_slow:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_aoko_blue_ring_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self.ability:GetSpecialValueFor("blue_slow")
end

--

modifier_aoko_pink_ring_haste = class({})

function modifier_aoko_pink_ring_haste:IsHidden() return false end
function modifier_aoko_pink_ring_haste:IsDebuff() return true end
function modifier_aoko_pink_ring_haste:RemoveOnDeath() return true end
function modifier_aoko_pink_ring_haste:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_pink_ring_haste:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_aoko_pink_ring_haste:GetModifierMoveSpeedBonus_Percentage(keys)
    return self.ability:GetSpecialValueFor("pink_haste")
end