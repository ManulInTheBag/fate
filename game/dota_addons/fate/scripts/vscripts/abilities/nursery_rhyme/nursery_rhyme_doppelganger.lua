-- nursery_rhyme_doppelganger — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_doppelganger = class({})

LinkLuaModifier("modifier_doppelganger", "abilities/nursery_rhyme/nursery_rhyme_doppelganger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doppelganger_enemy", "abilities/nursery_rhyme/nursery_rhyme_doppelganger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doppelganger_lookaway_slow", "abilities/nursery_rhyme/nursery_rhyme_doppelganger", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnCloneStart, OnCloneTakeDamage, OnCloneDeath, OnCloneThink, OnCloneOriginalTakeDamage, OnCloneOriginalDeath

OnCloneStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local duration = keys.Duration
	local cloneHealth = target:GetMaxHealth() * keys.Health/100 

	if IsSpellBlocked(keys.target) then return end -- Linken effect checker

	-- check for existing clone 
	if caster.bCloneExists then
		if IsValidEntity(caster.CurrentDoppelganger) and not caster.CurrentDoppelganger:IsNull() then
			caster.CurrentDoppelganger:ForceKill(false)
		end 
	end
	local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	local illusionSpawnLoc = Vector(0,0,0)
	
	if dist > 300 then 
		illusionSpawnLoc = target:GetAbsOrigin() + (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * 150
	else
		illusionSpawnLoc = target:GetAbsOrigin() + (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * dist/2
	end
	local illusion = CreateUnitByName("pseudo_illusion", illusionSpawnLoc, true, target, nil, target:GetTeamNumber()) 
	illusion:SetModel(target:GetModelName())
	illusion:SetOriginalModel(target:GetModelName())
	illusion:SetModelScale(target:GetModelScale())
	--illusion:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
	StartAnimation(illusion, {duration=duration, activity=ACT_DOTA_IDLE, rate=1})
	--illusion:SetPlayerID(target:GetPlayerID()) 
	--illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = 0, incoming_damage = 0 })
	--illusion:MakeIllusion()
	illusion:SetBaseMagicalResistanceValue(0)
	-- god why do i have to always wait 1 damn frame
	Timers:CreateTimer(0.033, function()
		illusion:SetBaseMaxHealth(cloneHealth)
		illusion:SetMaxHealth(cloneHealth)
		illusion:ModifyHealth(cloneHealth, nil, false, 0)
	end)
	Timers:CreateTimer(duration, function()
		if IsValidEntity(illusion) and not illusion:IsNull() then 
			illusion:ForceKill(false)
			illusion:AddEffects(EF_NODRAW)
			--illusion:SetAbsOrigin(Vector(10000,10000,0))
		end
	end)

	caster.CurrentDoppelganger = illusion
	caster.CurrentDoppelgangerOriginal = target
	caster.bCloneExists = true
	illusion:AddNewModifier(caster, ability, "modifier_doppelganger", {})
	target:AddNewModifier(caster, ability, "modifier_doppelganger_enemy", {})
	giveUnitDataDrivenModifier(caster, illusion, "pause_sealdisabled", duration)

	target:EmitSound("Hero_Terrorblade.Sunder.Target")
	local cloneFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( cloneFx, 0, target:GetAbsOrigin())
	local cloneFx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( cloneFx2, 0, illusion:GetAbsOrigin())
	Timers:CreateTimer( 0.7, function()
		ParticleManager:DestroyParticle( cloneFx, false )
		ParticleManager:ReleaseParticleIndex( cloneFx )
		ParticleManager:DestroyParticle( cloneFx2, false )
		ParticleManager:ReleaseParticleIndex( cloneFx2 )
	end)
end

OnCloneTakeDamage = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local damageTaken = keys.DamageTaken
	local damageShared = keys.SharedDamage

	DoDamage(caster, caster.CurrentDoppelgangerOriginal, damageTaken*damageShared/100, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
end

OnCloneDeath = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local cloneKillFx = ParticleManager:CreateParticle( "particles/generic_gameplay/illusion_killed.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( cloneKillFx, 0, caster.CurrentDoppelganger:GetAbsOrigin()+Vector(0,0,100) )

	caster.CurrentDoppelganger:AddEffects(EF_NODRAW)
	--illusion:SetModel("models/development/invisiblebox.vmdl")
	--illusion:SetOriginalModel("models/development/invisiblebox.vmdl")

	--caster.CurrentDoppelganger:SetHealth(1)
	--caster.CurrentDoppelganger:SetAbsOrigin(Vector(10000,10000,0))
	caster.CurrentDoppelgangerOriginal:RemoveModifierByName("modifier_doppelganger_enemy")
	caster.CurrentDoppelganger:ForceKill(false)
	caster.CurrentDoppelgangerOriginal = nil
	caster.bCloneExists = false
end

OnCloneThink = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster.bIsFTAcquired then
		if not IsFacingUnit(caster.CurrentDoppelgangerOriginal, caster.CurrentDoppelganger, 180) then
			DoDamage(caster, caster.CurrentDoppelgangerOriginal, caster:GetIntellect()*0.25 + keys.damage_per_sec/3 , DAMAGE_TYPE_PHYSICAL, 0, ability, false)
			caster.CurrentDoppelgangerOriginal:AddNewModifier(caster, ability, "modifier_doppelganger_lookaway_slow", {})
		end
	end
end

OnCloneOriginalTakeDamage = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local damageTaken = keys.DamageTaken

	if caster.CurrentDoppelgangerOriginal.bIsInvulDuetoDoppel then
		caster.CurrentDoppelgangerOriginal:SetHealth(1)
		caster.CurrentDoppelgangerOriginal.bIsInvulDuetoDoppel = false

		caster.CurrentDoppelganger:ForceKill(false)
	end
end

OnCloneOriginalDeath = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster.CurrentDoppelganger:ForceKill(false)
end


function nursery_rhyme_doppelganger:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: nursery_rhyme_ability / OnCloneStart
	OnCloneStart({
		caster = caster,
		ability = self,
		target = target,
		Duration = self:GetSpecialValueFor("duration"),
		Health = self:GetSpecialValueFor("doppelganger_health")
	})
end

modifier_doppelganger = class({})

function modifier_doppelganger:GetEffectName() return "particles/custom/nursery_rhyme/doppelganger/doppelganger.vpcf" end
function modifier_doppelganger:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_doppelganger:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_doppelganger:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	self:StartIntervalThink(0.33)
end

function modifier_doppelganger:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_doppelganger:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: nursery_rhyme_ability / OnCloneDeath
	OnCloneDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_doppelganger:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: nursery_rhyme_ability / OnCloneThink
	OnCloneThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		damage_per_sec = self:GetAbility():GetSpecialValueFor("damage_per_sec_flat")
	})
end

function modifier_doppelganger:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: nursery_rhyme_ability / OnCloneTakeDamage
	OnCloneTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage"),
		SharedDamage = self:GetAbility():GetSpecialValueFor("damage_shared")
	})
end

modifier_doppelganger_enemy = class({})

function modifier_doppelganger_enemy:IsDebuff() return true end
function modifier_doppelganger_enemy:GetEffectName() return "particles/custom/nursery_rhyme/doppelganger/doppelganger.vpcf" end
function modifier_doppelganger_enemy:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_doppelganger_enemy:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_doppelganger_enemy:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_doppelganger_enemy:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_doppelganger_enemy:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: nursery_rhyme_ability / OnCloneOriginalTakeDamage
	OnCloneOriginalTakeDamage({
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

function modifier_doppelganger_enemy:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: nursery_rhyme_ability / OnCloneOriginalDeath
	OnCloneOriginalDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_doppelganger_lookaway_slow = class({})

function modifier_doppelganger_lookaway_slow:IsDebuff() return true end
function modifier_doppelganger_lookaway_slow:GetEffectName() return "particles/units/heroes/hero_bane/bane_fiendsgrip_hands.vpcf" end
function modifier_doppelganger_lookaway_slow:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_doppelganger_lookaway_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_doppelganger_lookaway_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

function modifier_doppelganger_lookaway_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.75" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.75, true)
	end
end

function modifier_doppelganger_lookaway_slow:OnRefresh(kv)
	self:OnCreated(kv)
end
