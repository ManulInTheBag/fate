-- avenger_endless_loop — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_endless_loop = class({})

LinkLuaModifier("modifier_endless_loop_cooldown", "abilities/avenger/avenger_endless_loop", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_endless_loop", "abilities/avenger/avenger_endless_loop", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua, scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnEndlessStart, OnEndlessTakeDamage, ResetAbilities, ResetItems, RemoveChargeModifiers

OnEndlessStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local resetCounter = 0
	local initHealth = caster:GetHealth()

	LoopOverPlayers(function(player, playerID, playerHero)
       	if playerHero.gachi == true then
           	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound = "ballin_sped_up"})
       	end
    end)

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_endless_loop_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	EmitGlobalSound("Avenger.Darkness")
	EmitGlobalSound("Avenger.Berg")
	caster:AddNewModifier(caster, ability, "modifier_endless_loop", {})
	caster:SwapAbilities("angra_mainyu_verg_avesta", "avenger_endless_loop", true, false)
	
	Timers:CreateTimer(3.0, function() 
		if resetCounter == 4 or not caster:IsAlive() then return end
		caster:SetHealth(initHealth) 
		ResetAbilities(caster)
		ResetItems(caster)
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)
		caster:EmitSound("Avenger.Consume")
		resetCounter = resetCounter + 1
		return 3.0
	end)
end

OnEndlessTakeDamage = function(keys)
	--[[local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local attacker = keys.attacker
	local verg = caster:FindAbilityByName("avenger_verg_avesta")
	local multiplier = verg:GetLevelSpecialValueFor("multiplier", verg:GetLevel()-1)
	if caster.IsDIAcquired then multiplier = multiplier + 25 end
	local returnDamage = keys.DamageTaken * multiplier / 100

	if caster:GetHealth() ~= 0 then
		DoDamage(caster, attacker, returnDamage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, verg, false)
		if attacker:IsRealHero() then attacker:EmitSound("Hero_WitchDoctor.Maledict_Tick") end
		local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_ABSORIGIN, attacker)
		ParticleManager:SetParticleControl(particle, 1, attacker:GetAbsOrigin())
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)
	end]]
end

ResetAbilities = function(hero)
	-- Reset all resetable abilities
	RemoveChargeModifiers(hero)
	for i=0, 23 do 
		local ability = hero:GetAbilityByIndex(i)
		if ability ~= nil then
			if ability.IsResetable ~= false then
				ability:EndCooldown()
			end
		else 
			break
		end
	end
end

ResetItems = function(hero)
	-- Reset all items
	for i=0, 16 do
		local item = hero:GetItemInSlot(i) 
		if item ~= nil then
			item:EndCooldown()
		end
	end
end

RemoveChargeModifiers = function(hero)
	for i=1, #ChargeBasedBuffs do
		--print(ChargeBasedBuffs[i])
        hero:RemoveModifierByName(ChargeBasedBuffs[i])        
    end
end


function avenger_endless_loop:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnEndlessStart
	OnEndlessStart({ caster = caster, ability = self, target = caster })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_endless_loop_cooldown = class({})

function modifier_endless_loop_cooldown:IsDebuff() return true end
function modifier_endless_loop_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_endless_loop = class({})

function modifier_endless_loop:GetEffectName() return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf" end
function modifier_endless_loop:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_endless_loop:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_endless_loop:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_endless_loop:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_endless_loop:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: avenger_ability / OnEndlessTakeDamage
	OnEndlessTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end
