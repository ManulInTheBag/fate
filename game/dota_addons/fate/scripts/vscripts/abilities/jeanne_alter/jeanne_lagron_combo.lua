jeanne_lagron_combo = class({})

LinkLuaModifier("modifier_lagron_combo_thinker", "abilities/jeanne_alter/jeanne_lagron_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_lagron_combo_block", "abilities/jeanne_alter/jeanne_lagron_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lagron_combo_ally", "abilities/jeanne_alter/jeanne_lagron_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_lagron_combo_cooldown", "abilities/jeanne_alter/jeanne_lagron_combo", LUA_MODIFIER_MOTION_NONE)

function jeanne_lagron_combo:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function jeanne_lagron_combo:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function jeanne_lagron_combo:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local delay = 4.5

	caster:AddNewModifier(caster, self, "modifier_jeanne_lagron_combo_cooldown", {duration = self:GetCooldown(1)})

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

	EmitGlobalSound("lagron_combo_charge")

	caster:AddNewModifier(caster, self, "modifier_jeanne_lagron_combo_block", {duration = delay + 1.65})

	local ascendCount = 0
	local descendCount = 0

	self.FxDestroyed = false

	local dummy = CreateUnitByName("dummy_unit", target_point, false, caster, caster, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

	--giveUnitDataDrivenModifier(caster, caster, "jump_pause", delay + 1.65)
	--giveUnitDataDrivenModifier(caster, caster, "jump_pause_postlock", delay + 1.65)
	StartAnimation(caster, {duration=delay + 1.65, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=1})

	Timers:CreateTimer(delay, function()
	   	if caster:IsAlive() then
	   		local damage = math.min(self:GetSpecialValueFor("damage") + caster:FindModifierByName("modifier_jeanne_lagron_combo_block").stored_damage, self:GetSpecialValueFor("max_damage"))
	   		StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=4})

	   		EmitGlobalSound("lagron")

	   		--[[self.FireParticle = ParticleManager:CreateParticle("particles/jeanne_alter/vasavi_ground.vpcf", PATTACH_CUSTOMORIGIN, dummy)
	   		ParticleManager:SetParticleControl(self.FireParticle, 0, target_point)]]

	   		CreateGlobalParticle("particles/jeanne_alter/vasavi_ground.vpcf", {[0] = target_point}, 1.65)

	   		CreateGlobalParticle("particles/jeanne_alter/nightstalker_crippling_fear_aura.vpcf", {[0] = target_point, [2] = Vector( self:GetAOERadius(), 0, 0 )}, 1.65)

	   		--[[local particle_cast1 = "particles/jeanne_alter/nightstalker_crippling_fear_aura.vpcf"

			local effect_cast1 = ParticleManager:CreateParticle( particle_cast1, PATTACH_ABSORIGIN_FOLLOW, dummy )
			ParticleManager:SetParticleControl( effect_cast1, 2, Vector( self:GetAOERadius(), 0, 0 ) )]]

			--[[Timers:CreateTimer(1.65, function()
				ParticleManager:DestroyParticle(effect_cast1, false)
			end)]]

	   		CreateModifierThinker(caster, self, "modifier_lagron_combo_thinker", { Duration = 1.65,
																			 Damage = damage,
																			 Radius = self:GetAOERadius()}
																			, target_point, caster:GetTeamNumber(), false)

	   		EmitGlobalSound("karna_vasavi_explosion")

	   		Timers:CreateTimer(1.5, function()
				dummy:RemoveSelf()
			end)
		end
	end)

	--[[Timers:CreateTimer(delay + 1.65, function()		
		--self.FxDestroyed = true
		ParticleManager:DestroyParticle(self.FireParticle, true)
		ParticleManager:ReleaseParticleIndex(self.FireParticle)		

		return
	end)]]
end

--[[function karna_vasavi_shakti:OnOwnerDied()
	if not self.FxDestroyed then
		ParticleManager:DestroyParticle(self.FireParticle, true)
		ParticleManager:ReleaseParticleIndex(self.FireParticle)
	end
end]]


modifier_jeanne_lagron_combo_block = class({})

function modifier_jeanne_lagron_combo_block:IsHidden() return true end
function modifier_jeanne_lagron_combo_block:IsDebuff() return false end
function modifier_jeanne_lagron_combo_block:IsPurgable() return false end
function modifier_jeanne_lagron_combo_block:IsPurgeException() return false end
function modifier_jeanne_lagron_combo_block:RemoveOnDeath() return true end
function modifier_jeanne_lagron_combo_block:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_jeanne_lagron_combo_block:DeclareFunctions()
    local func = {  --MODIFIER_PROPERTY_AVOID_DAMAGE,
                --MODIFIER_EVENT_ON_TAKEDAMAGE
            }
    return func
end

--[[function modifier_jeanne_lagron_block:GetModifierAvoidDamage(keys)
    if IsServer() then
        self.stored_damage = self.stored_damage + keys.damage
        return 1
    end
end]]

--[[function modifier_jeanne_lagron_combo_block:OnTakeDamage(args)
    if IsServer() then
        if args.unit:GetTeam() ~= self:GetParent():GetTeam() then return end
        if not args.unit:IsHero() then return end

        self.stored_damage = self.stored_damage + args.damage*self.ability:GetSpecialValueFor("return_percentage")/100
    end
end]]

function modifier_jeanne_lagron_combo_block:OnCreated()
    if IsServer() then
        self.parent = self:GetParent()
        self.ability = self:GetAbility()
        self.stored_damage = 0

        LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
            if playerHero:GetTeam() == self.parent:GetTeam() then
            	playerHero:AddNewModifier(self.parent, self.ability, "modifier_lagron_combo_ally", {duration = 4.5})
            end
        end)
    end
end

modifier_lagron_combo_ally = class({})

function modifier_lagron_combo_ally:IsHidden() return true end
function modifier_lagron_combo_ally:IsDebuff() return false end
function modifier_lagron_combo_ally:IsPurgable() return false end
function modifier_lagron_combo_ally:IsPurgeException() return false end
function modifier_lagron_combo_ally:RemoveOnDeath() return true end
function modifier_lagron_combo_ally:DeclareFunctions()
    local func = {  --MODIFIER_PROPERTY_AVOID_DAMAGE,
                --MODIFIER_EVENT_ON_TAKEDAMAGE
            }
    return func
end

--[[function modifier_jeanne_lagron_block:GetModifierAvoidDamage(keys)
    if IsServer() then
        self.stored_damage = self.stored_damage + keys.damage
        return 1
    end
end]]

function modifier_lagron_combo_ally:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end

        hTarget = self:GetParent()
        previousHealth = self.hp
        local return_percentage = (self.ability:GetSpecialValueFor("return_percentage") + (self:GetCaster().AvengerAcquired and 10 or 0))/100
        if (previousHealth - args.damage*(1 - return_percentage) > 0) then
            hTarget:SetHealth(previousHealth - args.damage*(1 - return_percentage))
        end
        self:GetCaster():FindModifierByName("modifier_jeanne_lagron_combo_block").stored_damage = self:GetCaster():FindModifierByName("modifier_jeanne_lagron_combo_block").stored_damage + args.damage*return_percentage
        --self.stored_damage = self.stored_damage + args.damage*return_percentage
    end
end

function modifier_lagron_combo_ally:OnCreated()
    if IsServer() then
        self.parent = self:GetParent()
        self.ability = self:GetAbility()

        --[[if self.target and self.target:HasModifier("modifier_lagron_damage_checker_enemy") then
            self.checker = true
            self.point = self.target
        end]]
        self.stored_damage = 0
        self.hp = self.parent:GetHealth()
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_lagron_combo_ally:OnIntervalThink()
    if IsServer() then
        self.hp = self.parent:GetHealth()
    end
end

--

modifier_lagron_combo_thinker = class({})

LinkLuaModifier("modifier_lagron_combo_slow", "abilities/jeanne_alter/jeanne_lagron_combo", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_lagron_combo_thinker:OnCreated(args)
		self.Damage = args.Damage
		self.Radius = args.Radius

		self.ThinkCount = 0

		self:StartIntervalThink(0.1)
	end

	function modifier_lagron_combo_thinker:OnIntervalThink()
		local location = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local damage = self.Damage

		for i = 1, #targets do
			damage = self.Damage

			DoDamage(caster, targets[i], damage/15, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			targets[i]:AddNewModifier(caster, ability, "modifier_lagron_combo_slow", { Duration = 0.3 })
		end

		for i = 1, 5 do
			local beamLoc = RandomPointInCircle(location, self.Radius * 0.9)
			
			local beam_particle = ParticleManager:CreateParticle("particles/jeanne_alter/karna_fire_eruption.vpcf", PATTACH_CUSTOMORIGIN, caster)
		   	ParticleManager:SetParticleControl(beam_particle, 0, beamLoc) 

			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(beam_particle, true)
				ParticleManager:ReleaseParticleIndex(beam_particle)
				return
			end)
		end

		self.ThinkCount = self.ThinkCount + 1

		if self.ThinkCount >= 15 then
			self:Destroy()
		end
	end
end

modifier_lagron_combo_slow = class({})

function modifier_lagron_combo_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_lagron_combo_slow:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

function modifier_lagron_combo_slow:IsHidden()
	return true 
end

modifier_jeanne_lagron_combo_cooldown = class({})

function modifier_jeanne_lagron_combo_cooldown:GetTexture()
	return "custom/jeanne_alter/jeanne_combo2"
end

function modifier_jeanne_lagron_combo_cooldown:IsHidden()
	return false 
end

function modifier_jeanne_lagron_combo_cooldown:RemoveOnDeath()
	return false
end

function modifier_jeanne_lagron_combo_cooldown:IsDebuff()
	return true 
end

function modifier_jeanne_lagron_combo_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end