diarmuid_new_combo = class({})

LinkLuaModifier("modifier_diar_model_swap", "abilities/diarmuid/diarmuid_new_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diar_fw_controller", "abilities/diarmuid/diarmuid_new_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diar_combo_sequence_controller", "abilities/diarmuid/diarmuid_new_combo", LUA_MODIFIER_MOTION_NONE)
function diarmuid_new_combo:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	--caster:EmitSound("ZL.Dearg_Cast")

	self.SoundQueue = math.random(1,3)
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diarmuid_gaedearg_alt_" .. self.SoundQueue .. "_1"})
				end
	        	
	    
   		end)
		   caster:EmitSound("Diarmuid_GaeDearg_Alt" .. self.SoundQueue .. "_1")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) 
	ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin()) 
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	return true
end
function diarmuid_new_combo:ActivateCombo(target)
	local caster = self:GetCaster()
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", self:GetSpecialValueFor("duration"))
	giveUnitDataDrivenModifier(target, target, "pause_sealenabled", self:GetSpecialValueFor("duration"))
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Diar_combo_jopa"})
			end
	        	
	       
   		end)
	caster:AddNewModifier(caster, self, "modifier_diar_combo_sequence_controller", {duration = self:GetSpecialValueFor("duration"), htarget = target:entindex()})

end
function diarmuid_new_combo:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	if target == caster:GetAbsOrigin() then
        target = caster:GetAbsOrigin() + caster:GetForwardVector()*100
    end
	self.fw = caster:GetForwardVector()
    local vector = (target - caster:GetAbsOrigin()):Normalized()
    vector.z = 0
	local recast_time = self:GetSpecialValueFor("recast_timer")
	caster:AddNewModifier(caster, self, "modifier_diar_model_swap", {duration = self:GetSpecialValueFor("duration")+recast_time + 0.4})
	self.dearg_attach_fx = nil
    local speed = 3000
	local tProjectile = {
        EffectName = "particles/zlodemon/diar_combo/gae_dearg_projectile.vpcf",
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin() + Vector(0,0,120),
        vVelocity = vector * speed,
        fDistance = 1300,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = 0,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.1,
        --iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    }
	caster.diar_combo_projectile  = ProjectileManager:CreateLinearProjectile(tProjectile)
	local index0ability = caster:GetAbilityByIndex(0):GetName()
	if index0ability == "diarmuid_new_combo"  then
		 caster:SwapAbilities("diarmuid_new_combo", "diarmuid_warrior_charge", false, true)
	end
	Timers:CreateTimer(recast_time + 0.4, function()
		if self.dearg_attach_fx ~= nil and not caster:HasModifier("modifier_diar_combo_sequence_controller") then

			ParticleManager:DestroyParticle(self.dearg_attach_fx, true) 
			ParticleManager:ReleaseParticleIndex(self.dearg_attach_fx) 
			caster:RemoveModifierByName("modifier_diar_model_swap")
			caster:RemoveModifierByName("modifier_rampant_warrior_cooldown")
			caster:AddNewModifier(caster, self, "modifier_rampant_warrior_cooldown", { Duration = self:GetSpecialValueFor("reduced_cooldown")})
			local masterCombo = caster.MasterUnit2:FindAbilityByName("diarmuid_new_combo")
			self:EndCooldown()
			self:StartCooldown(self:GetSpecialValueFor("reduced_cooldown"))
			masterCombo:EndCooldown()
			masterCombo:StartCooldown(self:GetSpecialValueFor("reduced_cooldown"))			
		elseif self.dearg_attach_fx == nil then
			caster:RemoveModifierByName("modifier_rampant_warrior_cooldown")
			caster:AddNewModifier(caster, self, "modifier_rampant_warrior_cooldown", { Duration = self:GetSpecialValueFor("reduced_cooldown")})

			local masterCombo = caster.MasterUnit2:FindAbilityByName("diarmuid_new_combo")
			self:EndCooldown()
			self:StartCooldown(self:GetSpecialValueFor("reduced_cooldown"))
			masterCombo:EndCooldown()
			masterCombo:StartCooldown(self:GetSpecialValueFor("reduced_cooldown"))
		end
	
	end)
	caster:AddNewModifier(caster, self, "modifier_rampant_warrior_cooldown", { Duration = self:GetCooldown(1)})

	local masterCombo = caster.MasterUnit2:FindAbilityByName("diarmuid_new_combo")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(masterCombo:GetCooldown(1))

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diar_spear_throw"})
			end
	        	
	       
   		end)

end

function diarmuid_new_combo:OnProjectileHit(target, location, tData )
    if target == nil then
        return false
    end
    if (target:GetName() == "npc_dota_ward_base") then
        return false
    end

    local caster = self:GetCaster()
	ApplyDeargDispel(target)
	DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
	if caster.IsCrimsonRoseAcquired and target:IsHero() then
		if not IsManaLess(target) then
			target:SetMana(target:GetMana() - 500)
			target:AddNewModifier(caster, ability, "modifier_gae_dearg", { Duration = self:GetSpecialValueFor("duration") })
		end
	end
	target:EmitSound("Hero_Lion.Impale")
    giveUnitDataDrivenModifier(caster, target, "stunned", self:GetSpecialValueFor("recast_timer"))
	giveUnitDataDrivenModifier(caster,target , "revoked", self:GetSpecialValueFor("recast_timer"))
	self.dearg_attach_fx = ParticleManager:CreateParticle("particles/zlodemon/diar_combo/gae_dearg_target.vpcf", PATTACH_POINT_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(self.dearg_attach_fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin() , true)
	ParticleManager:SetParticleControlForward(self.dearg_attach_fx,1,target:GetForwardVector())
	


	target:AddNewModifier(caster, self, "modifier_diar_fw_controller", {duration = self:GetSpecialValueFor("recast_timer")})

    Timers:CreateTimer(0.033,function()
        ProjectileManager:DestroyLinearProjectile(caster.diar_combo_projectile )
    end)

    return true
end

---------------------------------------------------------------------------------------------------------------------


modifier_diar_model_swap = modifier_diar_model_swap or class({})

function modifier_diar_model_swap:IsHidden()                                                                       return true end
function modifier_diar_model_swap:IsDebuff()                                                                       return false end
function modifier_diar_model_swap:IsPurgable()                                                                     return false end
function modifier_diar_model_swap:IsPurgeException()                                                               return false end
function modifier_diar_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_diar_model_swap:IsDimensionException()                                                           return true end
function modifier_diar_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_diar_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_diar_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_diar_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_diar_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.sModelName = "models/diarmuid/diarmuid_no_dearg.vmdl"
    end
end
function modifier_diar_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_diar_model_swap:CheckState()
    local state =   { 
                        [MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end
--========================================--


modifier_diar_fw_controller = modifier_diar_fw_controller or class({})

function modifier_diar_fw_controller:IsHidden()                                                                       return true end
function modifier_diar_fw_controller:IsDebuff()                                                                       return false end
function modifier_diar_fw_controller:IsPurgable()                                                                     return false end
function modifier_diar_fw_controller:IsPurgeException()                                                               return false end
function modifier_diar_fw_controller:RemoveOnDeath()                                                                  return true end
function modifier_diar_fw_controller:IsDimensionException()                                                           return true end
function modifier_diar_fw_controller:AllowIllusionDuplicate()                                                         return true end
function modifier_diar_fw_controller:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end


function modifier_diar_fw_controller:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
	if IsServer() then
		--self.fw = self.hParent:GetForwardVector()
		--self.hParent:SetForwardVector(self.fw + Vector(0,0,100))
	end
end
function modifier_diar_fw_controller:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_diar_fw_controller:OnDestroy(hTable)
	if IsServer() then
    	--self.hParent:SetForwardVector(self.fw)
	end
end


modifier_diar_combo_sequence_controller = modifier_diar_combo_sequence_controller or class({})

function modifier_diar_combo_sequence_controller:IsHidden()                                                                       return true end
function modifier_diar_combo_sequence_controller:IsDebuff()                                                                       return false end
function modifier_diar_combo_sequence_controller:IsPurgable()                                                                     return false end
function modifier_diar_combo_sequence_controller:IsPurgeException()                                                               return false end
function modifier_diar_combo_sequence_controller:RemoveOnDeath()                                                                  return true end
function modifier_diar_combo_sequence_controller:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end


function modifier_diar_combo_sequence_controller:OnCreated(hTable)
	if IsServer() then
		self.hCaster  = self:GetCaster()
		self.hAbility = self:GetAbility()
		self.target = EntIndexToHScript(hTable.htarget)
		local gaeDeargHandlePosition = self.target:GetAttachmentOrigin(self.target:ScriptLookupAttachment("attach_hitloc")) + self.target:GetForwardVector() * 100
		self.hCaster:SetAbsOrigin(gaeDeargHandlePosition)
		self.fw = self.hCaster:GetForwardVector()
		self.totaldamage = self.hAbility:GetSpecialValueFor("total_damage")
		self.tick_damage = self.totaldamage/5
		self.hCaster:SetForwardVector((self.target:GetForwardVector() * -1 + Vector(0,0,-0.45)):Normalized())
		self.radius = self.hAbility:GetSpecialValueFor("radius")
		StartAnimation(self.hCaster, {duration=0.4, activity=ACT_DOTA_CAST_ALACRITY, rate=1.3})
		self.totalTime = 0
		self.bAct1 = false
		self.bAct2 = false
		self.bAct3 = false
		self.soundProckCount = 0
		self.lastsoundprock = false
		self:StartIntervalThink(0.033)
	end
end
function modifier_diar_combo_sequence_controller:OnIntervalThink()
	if not self.hCaster:IsAlive() then self:Destroy() end
	self.totalTime = self.totalTime + 0.033
	if self.totalTime > 1.25 and not self.lastsoundprock then
		self.lastsoundprock = true
		local currentStack = self.target:GetModifierStackCount("modifier_gae_buidhe", self.hAbility)
		local healthDiff = self.target:GetHealth()
		DoDamage(self.hCaster, self.target, self.tick_damage + 200, DAMAGE_TYPE_MAGICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self.hAbility, false)
		healthDiff = healthDiff - self.target:GetHealth()
		nStacks = math.ceil(healthDiff/10)
		if self.target:GetHealth() > 0 and self.target:IsAlive() and self.hCaster:IsAlive() and nStacks > 1 then
			--target:RemoveModifierByName("modifier_gae_buidhe") 
			self.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_gae_buidhe", { Stacks = currentStack + nStacks, Duration = 70})
		end

		self.target:EmitSound("diar_new_combo_attack_3")
		local flower = ParticleManager:CreateParticle("particles/zlodemon/diar_combo/flower.vpcf", PATTACH_POINT_FOLLOW, self.target)
		ParticleManager:SetParticleControl(flower, 0, self.target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(flower)
		local flower2 = ParticleManager:CreateParticle("particles/zlodemon/diar_combo/golden_rose.vpcf", PATTACH_POINT_FOLLOW, self.target)
		ParticleManager:SetParticleControl(flower2, 0, self.target:GetAbsOrigin()+ Vector(0,0,150))
		ParticleManager:ReleaseParticleIndex(flower2)

		

	end
	if self.totalTime < 1.05 and self.totalTime / 0.3 > self.soundProckCount then

		self.soundProckCount = self.soundProckCount +1
		self.target:EmitSound("diar_new_combo_attack_"..math.random(1,2))
		local petals = ParticleManager:CreateParticle("particles/zlodemon/diar_combo/petals.vpcf", PATTACH_POINT_FOLLOW, self.target)
		ParticleManager:SetParticleControl(petals, 0, self.target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(petals)
		local targets = FindUnitsInRadius(self.hCaster:GetTeamNumber(), self.hCaster:GetOrigin(), nil, self.radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        for k,v in pairs(targets) do
			local currentStack = v:GetModifierStackCount("modifier_gae_buidhe", self.hAbility)
			local healthDiff = v:GetHealth()
            DoDamage(self.hCaster, v, self.tick_damage, DAMAGE_TYPE_MAGICAL, 0, self.hAbility, false)
			healthDiff = healthDiff - v:GetHealth()
			nStacks = math.ceil(healthDiff/10)
			if v:GetHealth() > 0 and v:IsAlive() and self.hCaster:IsAlive() and nStacks > 1 then
				--target:RemoveModifierByName("modifier_gae_buidhe") 
				v:AddNewModifier(self.hCaster, self.hAbility, "modifier_gae_buidhe", { Stacks = currentStack + nStacks, Duration = 70})
			end
        end
		local knockback = { should_stun = false,
			knockback_duration = 0.2,
			duration = 0.2,
			knockback_distance = 100,
			knockback_height = 0,
			center_x = self.hCaster:GetAbsOrigin().x,
			center_y = self.hCaster:GetAbsOrigin().y,
			center_z = self.hCaster:GetAbsOrigin().z }
			if( not IsKnockbackImmune(self.target)) then
				self.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_knockback", knockback)
			end
			
	end
	if self.totalTime >= 0.4 and not self.bAct1 then 
		self.bAct1 = true
		StartAnimation(self.hCaster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=1.4})
	end
	if self.totalTime >= 0.7 and not self.bAct2  then 
		self.bAct2 = true
		StartAnimation(self.hCaster, {duration=0.4, activity=ACT_DOTA_CAST_EMP, rate=1.5})
	end
	if self.totalTime >= 1.05 and not self.bAct3 then 
		self.bAct3 = true
		StartAnimation(self.hCaster, {duration=0.35, activity=ACT_DOTA_CAST_CHAOS_METEOR, rate=1.1})
	end
	if IsServer() then
		local gaeDeargHandlePosition = self.target:GetAttachmentOrigin(self.target:ScriptLookupAttachment("attach_hitloc")) + self.target:GetForwardVector() * 100
		self.hCaster:SetForwardVector((self.target:GetForwardVector() * -1  + Vector(0,0,-0.45)):Normalized())
		self.hCaster:SetAbsOrigin(gaeDeargHandlePosition)
	end
end
function modifier_diar_combo_sequence_controller:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_diar_combo_sequence_controller:OnDestroy(hTable)
	if IsServer() then
    	FindClearSpaceForUnit(self.hCaster, self.target:GetAbsOrigin(), true)
		self.hCaster:RemoveModifierByName("modifier_diar_model_swap")
		self.hCaster:RemoveModifierByName("pause_sealenabled")
		ParticleManager:DestroyParticle(self.hAbility.dearg_attach_fx, true) 
		ParticleManager:ReleaseParticleIndex(self.hAbility.dearg_attach_fx) 
		self.hCaster:SetForwardVector(self.fw)
	end
end
function modifier_diar_combo_sequence_controller:GetModifierIncomingDamage_Percentage() 
	return -40
end
function modifier_diar_combo_sequence_controller:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,   }

	return funcs
end