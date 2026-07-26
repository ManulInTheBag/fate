-- tamamo_mantra — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_mantra = class({})

LinkLuaModifier("modifier_mantra_ally", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mantra_enemy", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mantra_vfx", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mantra_tether", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mantra_mr_buff", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mantra_mr_debuff", "abilities/tamamo/tamamo_mantra", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMantraCast, OnMantraStart, OnMantraTakeDamage

OnMantraCast = function(keys)
	local caster = keys.caster
	local target = keys.target 
	if target:GetName() == "npc_dota_ward_base" then
		caster:Interrupt()
		return
	end
end

OnMantraStart = function(keys)
	local caster = keys.caster
	local target = keys.target 
	local ability = keys.ability
	local orbAmount = keys.OrbAmount
	local modifierName = 0
	if caster:GetTeam() ~= target:GetTeam() then
		if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker
	end
	
	--[[if target:HasModifier("modifier_mantra_ally") or target:HasModifier("modifier_mantra_enemy") then
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Target Already Affected By Mantra" } )
		keys.ability:EndCooldown()
		caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(1))
		return	
	end]]
	caster.MantraTarget = target
	caster.MantraLocation = caster:GetAbsOrigin()
	target.IsMantraProcOnCooldown = false 

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		modifierName = "modifier_mantra_ally"
		if caster.IsSeveredFateAcquired then
			target:AddNewModifier(caster, ability, "modifier_mantra_mr_buff", {})
		end
	else
		if IsSpellBlocked(keys.target) then return end
		modifierName = "modifier_mantra_enemy"
		--[[if caster.IsSeveredFateAcquired then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_mantra_mr_debuff", {})
		end]]
	end

	if caster.IsSeveredFateAcquired then
		--caster.IsSeveredFateActive = true
		caster.TetheredTarget = target
		
		--ability:ApplyDataDrivenModifier(caster, target, "modifier_mantra_tether", {})
		if caster:GetAbilityByIndex(2):GetName() == "tamamo_mantra" then
			caster:SwapAbilities("tamamo_mantra", "tamamo_mystic_shackle", false,true) 
			caster.bIsShackleAvailable = true
			Timers:CreateTimer(3.0, function()
				caster:SwapAbilities("tamamo_mantra", "tamamo_mystic_shackle", true,false) 
				caster.bIsShackleAvailable = false
			end)
		end
	end

	local castFx = ParticleManager:CreateParticle('particles/units/heroes/hero_oracle/oracle_purifyingflames_halo.vpcf', PATTACH_CUSTOMORIGIN, target) 
    ParticleManager:SetParticleControl(castFx, 0, target:GetOrigin())
    target:EmitSound("Tamamo.Mantra")

	-- Set stack amount1
	target:RemoveModifierByName("modifier_mantra_ally")
	target:RemoveModifierByName("modifier_mantra_enemy")
	local pepega = target:AddNewModifier(caster, ability, modifierName, {})
	if caster:HasModifier("modifier_fiery_heaven_indicator") then
		pepega.ability = "fire"
	elseif caster:HasModifier("modifier_frigid_heaven_indicator") then 
		pepega.ability = "ice"
	elseif caster:HasModifier("modifier_gust_heaven_indicator") then
		pepega.ability = "wind"
	elseif caster:HasModifier("modifier_void_heaven_indicator") then
		pepega.ability = "void"
	end
	target:SetModifierStackCount(modifierName, ability, orbAmount)
	target:RemoveAllModifiersOfName("modifier_mantra_vfx")
	for i=1, orbAmount do target:AddNewModifier(caster, ability, "modifier_mantra_vfx", {}) end
end

OnMantraTakeDamage = function(keys)
	local caster = keys.caster 
	local target = caster.MantraTarget
	local attacker = keys.attacker
	local ability = keys.ability
	local damageTaken = keys.DamageTaken
	local orbBlockAmt = 0
	local orbDamageEnemy = 0
	local currentStack = 0
	local modifierName = 0
	local currentHealth = target:GetHealth()
	local charm_type = ""

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		if target.IsMantraProcOnCooldown then
			return
		end
		modifierName = "modifier_mantra_ally"
		local pepega = target:FindModifierByName(modifierName)
		target.IsMantraProcOnCooldown = true
		Timers:CreateTimer(0.5, function()
			target.IsMantraProcOnCooldown = false
		end)
		charm_type = pepega.ability
		orbBlockAmt = keys.BlockAmt + caster:GetIntellect() * 0.5
		if currentHealth == 0 then
			--print("lethal")
		else
			if orbBlockAmt < keys.DamageTaken then
				target:SetHealth(currentHealth + orbBlockAmt)
			else
				target:SetHealth(currentHealth + keys.DamageTaken)
			end
		end
		if charm_type == "fire" then
			local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_fire_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
			ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("ally_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)
    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("ally_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				DoDamage(caster, tEnemies[i], ability:GetSpecialValueFor("fire_damage"), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end
    	elseif charm_type == "ice" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_ice_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
    		ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("ally_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)

    		local tAllies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("ally_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
			for i = 1, #tAllies do
				tAllies[i]:Heal(ability:GetSpecialValueFor("ice_damage"), ability)
			end
    	elseif charm_type == "wind" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_wind_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
    		ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("ally_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)

    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("ally_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				tEnemies[i]:Script_ReduceMana(ability:GetSpecialValueFor("wind_mana"), ability)
			end
    	elseif charm_type == "void" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_void_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
    		ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("ally_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)
    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("ally_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				fDamage = ability:GetSpecialValueFor("void_damage")
				local diff = (tEnemies[i]:GetMaxHealth() - tEnemies[i]:GetHealth())/tEnemies[i]:GetMaxHealth()/2
				DoDamage(caster, tEnemies[i], fDamage*(diff + 1), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end

    		--[[local tEnemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("ally_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				for j=0, 5 do 
					local pepe_ability = tEnemies[i]:GetAbilityByIndex(j)
					if pepe_ability ~= nil then
						rCooldown = pepe_ability:GetCooldownTimeRemaining()
						pepe_ability:EndCooldown()
						pepe_ability:StartCooldown(rCooldown + ability:GetSpecialValueFor("void_cooldowns"))
					else 
						break
					end
				end
			end]]--
    	end
	else
		if target.IsMantraProcOnCooldown or target:IsMagicImmune() then
			return
		else
			--print(attacker:GetName() .. " attacked " .. target:GetName())
			target.IsMantraProcOnCooldown = true
			orbDamageEnemy = keys.Damage + caster:GetIntellect() * 0.5
			DoDamage(caster, target, orbDamageEnemy, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			Timers:CreateTimer(0.5, function()
				target.IsMantraProcOnCooldown = false
			end)
		end 
		modifierName = "modifier_mantra_enemy"
		local pepega = target:FindModifierByName(modifierName)
		charm_type = pepega.ability

		if charm_type == "fire" then
			local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_fire_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
			ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("enemy_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)
    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				DoDamage(caster, tEnemies[i], ability:GetSpecialValueFor("fire_damage"), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end
    	elseif charm_type == "ice" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_ice_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
    		ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("ally_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)

    		local tAllies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
			for i = 1, #tAllies do
				tAllies[i]:Heal(ability:GetSpecialValueFor("ice_damage"), ability)
			end
    	elseif charm_type == "wind" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_wind_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
			ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("enemy_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)
    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				tEnemies[i]:Script_ReduceMana(ability:GetSpecialValueFor("wind_mana"), ability)
			end
    	elseif charm_type == "void" then
    		local warpFx = ParticleManager:CreateParticle('particles/tamamo/tamamo_mantra_void_warp.vpcf', PATTACH_CUSTOMORIGIN, target) 
    		ParticleManager:SetParticleControlEnt(warpFx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    		ParticleManager:SetParticleControl(warpFx, 1, Vector(ability:GetSpecialValueFor("enemy_radius")/10, 0, 0))

    		Timers:CreateTimer(1, function()
    			ParticleManager:DestroyParticle(warpFx, false)
    			ParticleManager:ReleaseParticleIndex(warpFx)
    		end)

    		local tEnemies = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				local fdamage = ability:GetSpecialValueFor("void_damage")
				local diff = (tEnemies[i]:GetMaxHealth() - tEnemies[i]:GetHealth())/tEnemies[i]:GetMaxHealth()/2
				DoDamage(caster, tEnemies[i], fdamage*(diff + 1), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end

    		--[[local tEnemies = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				for j=0, 5 do 
					local pepe_ability = tEnemies[i]:GetAbilityByIndex(j)
					if pepe_ability ~= nil then
						rCooldown = pepe_ability:GetCooldownTimeRemaining()
						pepe_ability:EndCooldown()
						pepe_ability:StartCooldown(rCooldown + ability:GetSpecialValueFor("void_cooldowns"))
					else 
						break
					end
				end
			end]]--
    	end
	end

	local shieldFx = ParticleManager:CreateParticle('particles/units/heroes/hero_templar_assassin/templar_assassin_refraction_break.vpcf', PATTACH_CUSTOMORIGIN, caster) 
    ParticleManager:SetParticleControl(shieldFx, 1, target:GetOrigin())
	target:EmitSound("Hero_Lich.ChainFrostImpact.Hero")

	-- Set stack amount
	currentStack = target:GetModifierStackCount(modifierName, ability)
	--print("current mantra stack :" .. currentStack)
	--target:RemoveModifierByName(modifierName)
	--target:RemoveModifierByName("modifier_mantra_vfx")

	if currentStack == 1 then
		target:RemoveModifierByName(modifierName)
		target:RemoveAllModifiersOfName("modifier_mantra_vfx")
		--target:RemoveModifierByName("modifier_mantra_vfx")
	else
		target:SetModifierStackCount(modifierName, ability, currentStack-1)
		target:RemoveModifierByName("modifier_mantra_vfx")
		--for i=1, currentStack-1 do ability:ApplyDataDrivenModifier(caster, target, "modifier_mantra_vfx", {}) end
	end
end


function tamamo_mantra:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: tamamo_ability / OnMantraCast
	OnMantraCast({ caster = caster, ability = self, target = target })
	return true
end

function tamamo_mantra:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: tamamo_ability / OnMantraStart
	OnMantraStart({
		caster = caster,
		ability = self,
		target = target,
		OrbAmount = self:GetSpecialValueFor("orb_amount")
	})
end

modifier_mantra_ally = class({})

function modifier_mantra_ally:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_mantra_ally:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_mantra_ally:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_mantra_ally:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_mantra_ally:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: tamamo_ability / OnMantraTakeDamage
	-- TODO(dd2lua): функция читает keys.Damage — проверить
	OnMantraTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage"),
		BlockAmt = self:GetAbility():GetSpecialValueFor("damage_modifier")
	})
end

modifier_mantra_enemy = class({})

function modifier_mantra_enemy:IsDebuff() return true end
function modifier_mantra_enemy:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_mantra_enemy:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_mantra_enemy:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_mantra_enemy:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_mantra_enemy:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: tamamo_ability / OnMantraTakeDamage
	-- TODO(dd2lua): функция читает keys.BlockAmt — проверить
	OnMantraTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage"),
		Damage = self:GetAbility():GetSpecialValueFor("damage_modifier_enemy")
	})
end

modifier_mantra_vfx = class({})

function modifier_mantra_vfx:IsHidden() return true end
function modifier_mantra_vfx:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_mantra_vfx:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/tamamo/tamamo_mantra.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_mantra_vfx:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_mantra_tether = class({})


function modifier_mantra_tether:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_mantra_tether:GetModifierMagicalResistanceBonus()
	return 15
end

function modifier_mantra_tether:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "7.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(7.0, true)
	end
	self:StartIntervalThink(0.033)
	EmitSoundOn("Hero_Wisp.Tether.Target", self:GetParent())
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_mantra_tether:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_mantra_tether:OnDestroy()
	if not IsServer() then return end
end

function modifier_mantra_tether:OnIntervalThink()
	if not IsServer() then return end
end

modifier_mantra_mr_buff = class({})

function modifier_mantra_mr_buff:IsHidden() return true end

function modifier_mantra_mr_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_mantra_mr_buff:GetModifierMagicalResistanceBonus()
	return 15
end

function modifier_mantra_mr_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_mantra_mr_buff:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_mantra_mr_debuff = class({})

function modifier_mantra_mr_debuff:IsHidden() return true end
function modifier_mantra_mr_debuff:IsDebuff() return true end

function modifier_mantra_mr_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_mantra_mr_debuff:GetModifierMagicalResistanceBonus()
	return -15
end

function modifier_mantra_mr_debuff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_mantra_mr_debuff:OnRefresh(kv)
	self:OnCreated(kv)
end
