LinkLuaModifier("modifier_edmon_enfer", "abilities/edmon/edmon_enfer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_enfer_particle", "abilities/edmon/edmon_enfer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_ult", "abilities/edmon/edmon_ult", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_enfer_thinker", "abilities/edmon/edmon_enfer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_enfer_slow", "abilities/edmon/edmon_enfer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_enfer_cooldown", "abilities/edmon/edmon_enfer", LUA_MODIFIER_MOTION_NONE)

edmon_enfer = class({})

function edmon_enfer:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("edmon_enfer1")
	return true
end

function edmon_enfer:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("edmon_enfer1")
end

function edmon_enfer:GetCastRange()
	return self:GetSpecialValueFor("range")
end

function edmon_enfer:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_edmon_enfer", {})
	caster:AddNewModifier(caster, self, "modifier_edmon_enfer_particle", {})

	local abil = caster:FindAbilityByName("edmon_enfer")
	caster:AddNewModifier(caster, self, "modifier_edmon_enfer_cooldown", {duration = abil:GetCooldown(1)})

	local masterCombo = caster.MasterUnit2:FindAbilityByName(abil:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(abil:GetCooldown(1))
end

modifier_edmon_enfer_particle = class({})

function modifier_edmon_enfer_particle:IsHidden() return true end

function modifier_edmon_enfer_particle:OnCreated()
	self.parent = self:GetParent()

	self.fx = ParticleManager:CreateParticle("particles/edmon/edmon_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
	self:AddParticle(self.fx, false, false, -1, false, false)
end

modifier_edmon_enfer = class({})

function modifier_edmon_enfer:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.speed = self.ability:GetSpecialValueFor("speed")
		self.distelapsed = self.ability:GetSpecialValueFor("range")

		self.fx = ParticleManager:CreateParticle("particles/edmon/edmon_dash_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
		self:AddParticle(self.fx, false, false, -1, false, false)

        self.targetpos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*self.ability:GetSpecialValueFor("range")

		self:StartIntervalThink(FrameTime())
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_edmon_enfer:IsHidden() return true end
function modifier_edmon_enfer:IsDebuff() return false end
function modifier_edmon_enfer:RemoveOnDeath() return true end
function modifier_edmon_enfer:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_edmon_enfer:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_edmon_enfer:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_4_END
end
function modifier_edmon_enfer:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    --[MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end
function modifier_edmon_enfer:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_edmon_enfer:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        self.parent:RemoveModifierByName("modifier_edmon_enfer_particle")
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end

        if self.ability.particle_kappa then
            ParticleManager:DestroyParticle(self.ability.particle_kappa, false)
            ParticleManager:ReleaseParticleIndex(self.ability.particle_kappa)
        end
    end
end
function modifier_edmon_enfer:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())
end
function modifier_edmon_enfer:UpdateHorizontalMotion(me, dt)
	self.distelapsed = self.distelapsed - dt*self.speed

    if self.distelapsed <= 0 then
        --self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_edmon_enfer:BOOM(target)
    local position = target:GetAbsOrigin()
    local caster = self:GetParent()

   	local duration = 1.6
	local interval = 0.6
	local count = 0
	local radius = self.ability:GetSpecialValueFor("radius")
	local origin = target:GetAbsOrigin()
	local damage = self.ability:GetSpecialValueFor("hit_damage") + (caster.HellfireAcquired and 25 or 0)
	local last_damage = self.ability:GetSpecialValueFor("last_damage") + (caster.HellfireAcquired and 1500 or 0)
	local burn_damage = self.ability:GetSpecialValueFor("burn_damage") + (caster.HellfireAcquired and 1000 or 0)

	EmitGlobalSound("edmon_enfer2")
	--EmitGlobalSound("edmon_enfer_zuzup")

	caster:AddNewModifier(caster, self, "modifier_edmon_ult", {duration = duration + 3.2})

	Timers:CreateTimer(function()
        if count < duration and caster and caster:IsAlive() then
        	if interval > 0.075 then
            	interval = interval/2
            end
        	origin = target:GetAbsOrigin()
            local angle = RandomInt(0, 360)
            local startLoc = GetRotationPoint(origin,RandomInt(radius, radius),angle)
            local endLoc = GetRotationPoint(origin,RandomInt(radius, radius),angle + RandomInt(120, 240))
            local fxIndex = ParticleManager:CreateParticle( "particles/custom/edmond/edmond_enfer_slash.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl( fxIndex, 0, startLoc)
            ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,50))
            --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance_a.vpcf",PATTACH_ABSORIGIN,caster,2)
            --ParticleManager:SetParticleControl( p, 0, startLoc)
            --ParticleManager:SetParticleControl( p, 2, endLoc + Vector(0,0,50))
            local unitGroup = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
            for i = 1, #unitGroup do
				DoDamage(caster, unitGroup[i], damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                --caster:PerformAttack( unitGroup[i], true, true, true, true, false, false, true )
			end
            FindClearSpaceForUnit(caster,endLoc,true)
            for k,v in pairs(unitGroup) do
                --CauseDamage(caster,unitGroup,damage,damageType,ability3)
                --caster:PerformAttack(v,true,true,true,false,false,false,true)
            end
            --if #unitGroup == 0 then
                caster:EmitSound("arcueid_hit")
            --end
            count = count + interval
            return interval
        elseif caster and caster:IsAlive() then
        	caster:SetAbsOrigin(origin)
        	local dummies = {}
        	local dummy_loc = {}
        	local chTarget = {}
        	local beam = {}
        	local attach = {}
        	for i = 1,10 do
        		dummy_loc[i] = GetRotationPoint(origin,RandomInt(radius + 200, radius - 100),i * 36) + Vector(0,0,RandomInt(200,500))
				chTarget[i] = CreateUnitByName("hrunt_illusion", dummy_loc[i], true, nil, nil, caster:GetTeamNumber())
				chTarget[i]:SetAbsOrigin(dummy_loc[i])
				chTarget[i]:SetModel("models/updated_by_seva_and_hudozhestvenniy_film_spizdili/edmon/edmon.vmdl")
				chTarget[i]:SetModelScale(1.15)
			    chTarget[i]:SetOriginalModel("models/updated_by_seva_and_hudozhestvenniy_film_spizdili/edmon/edmon.vmdl")
			    local unseen = chTarget[i]:FindAbilityByName("dummy_unit_passive")
			    unseen:SetLevel(1)
			    local dir = origin - dummy_loc[i]
			    dir.z = 0

			    chTarget[i]:SetForwardVector(dir:Normalized())

			    StartAnimation(chTarget[i], {duration=2.9, activity=ACT_DOTA_ATTACK_EVENT, rate=1.0})

			    attach[i] = chTarget[i]:GetAttachmentOrigin(chTarget[i]:ScriptLookupAttachment("attach_attack")) + chTarget[i]:GetForwardVector()*100

			    chTarget[i]:AddEffects(EF_NODRAW)

			    local rand = math.random(1, 30)/100
			    Timers:CreateTimer(rand, function()
			    	chTarget[i]:RemoveEffects(EF_NODRAW)
			    	
					dummies[i] = ParticleManager:CreateParticle( "particles/custom/edmond/edmond_dummy.vpcf", PATTACH_WORLDORIGIN, chTarget[i])
					ParticleManager:SetParticleControl(dummies[i], 0, chTarget[i]:GetAbsOrigin() + Vector(0, 0, 100))
					ParticleManager:SetParticleControl(dummies[i], 2, Vector(0, 0, (i * 36) - 90))

					Timers:CreateTimer(2.9-rand, function()
						ParticleManager:DestroyParticle(dummies[i], true)
						ParticleManager:ReleaseParticleIndex(dummies[i])
					end)
				end)

			    Timers:CreateTimer(2.9, function()
					if IsValidEntity(chTarget[i]) and not chTarget[i]:IsNull() then
			            chTarget[i]:ForceKill(false)
			            chTarget[i]:AddEffects(EF_NODRAW)
			    	end
			    end)
			end

			Timers:CreateTimer(0.5, function()
				local sphere = ParticleManager:CreateParticle("particles/edmon/edmon_enfer_sphere.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(sphere, 0, origin + Vector(0, 0, 50))
				ParticleManager:SetParticleControl(sphere, 1, origin + Vector(0, 0, 50))

				Timers:CreateTimer(2.4, function()
					ParticleManager:DestroyParticle(sphere, false)
					ParticleManager:ReleaseParticleIndex(sphere)
				end)

				EmitGlobalSound("edmon_enfer_beam")

				for i = 1,10 do
					beam[i] = ParticleManager:CreateParticle( "particles/edmon/edmon_beam_laser_combo_white.vpcf", PATTACH_WORLDORIGIN, caster)
					ParticleManager:SetParticleControl(beam[i], 0, origin)
					ParticleManager:SetParticleControl(beam[i], 1, origin)
					ParticleManager:SetParticleControl(beam[i], 9, attach[i])
					--EmitSoundOnLocationWithCaster(target_loc, "Ability.static.end", caster)
						
					Timers:CreateTimer(2.4, function()
						ParticleManager:DestroyParticle(beam[i], true)
						ParticleManager:ReleaseParticleIndex(beam[i])
					end)
				end
			end)
			--[[local beam = {}
			for i = 1, 10 do
				beam[i] = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_laser_aghs.vpcf", PATTACH_WORLDORIGIN, caster)
				ParticleManager:SetParticleControl(beam[i], 0, origin)
				ParticleManager:SetParticleControl(beam[i], 1, origin)
				ParticleManager:SetParticleControl(beam[i], 9, chTarget[i]:GetAttachmentOrigin(chTarget[i]:ScriptLookupAttachment("attach_attack")) + chTarget[i]:GetForwardVector()*25)
				--EmitSoundOnLocationWithCaster(target_loc, "Ability.static.end", caster)
			end
			Timers:CreateTimer(1.0, function()
				for k,v in pairs(beam) do 
					ParticleManager:DestroyParticle(v, true)
					ParticleManager:ReleaseParticleIndex(v)
				end
			end)]]
			Timers:CreateTimer(0.5, function()
				EmitGlobalSound("edmon_enfer3")

				ScreenShake(origin, 3, 2.0, 2.4, 2000, 0, true)

				local particle2 = ParticleManager:CreateParticle("particles/edmon/edmon_enfer_magnetic_ring.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(particle2, 0, origin)
				ParticleManager:SetParticleControl(particle2, 1, Vector(radius, radius, radius))

				Timers:CreateTimer(2.4, function()
					ParticleManager:DestroyParticle(particle2, false)
					ParticleManager:ReleaseParticleIndex(particle2)
				end)
				CreateModifierThinker(caster, self.ability, "modifier_edmon_enfer_thinker", { Duration = 2.45,
																			 Damage = burn_damage,
																			 Radius = radius}
																			, origin, caster:GetTeamNumber(), false)
			end)

			Timers:CreateTimer(2.0, function()
				local aotk = ParticleManager:CreateParticle("particles/edmon/edmon_enfer_flash.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(aotk, 0, origin)
				EmitGlobalSound("edmon_enfer_explosion")
			end)

			Timers:CreateTimer(2.9, function()
				EmitGlobalSound("Gawain_Sun_Explode")
				local YellowScreenFx = ParticleManager:CreateParticle("particles/custom/screen_lightblue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
				local enemies = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false )
				for k,v in pairs(enemies)	do
				   	if IsValidEntity(v) and not v:IsNull() and v:IsAlive() then
				        if not v:IsMagicImmune() then 
							DoDamage(caster, v, last_damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
						end
					end
				end
			end)
							
			Timers:CreateTimer(2.9, function()	
				caster:RemoveModifierByName("modifier_edmon_ult")
				if IsInSameRealm(origin, caster:GetAbsOrigin()) then
					caster:SetAbsOrigin(origin)
				else
					caster:SetAbsOrigin(caster:GetAbsOrigin())
				end
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			end)
        end
    end)
end
function modifier_edmon_enfer:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = self.parent:GetForwardVector()--targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    --self.parent:SetForwardVector(direction:Normalized())

    local pepeg = false
    local unitGroup = FindUnitsInRadius(self.parent:GetTeam(), target, nil, 175, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    for i = 1, #unitGroup do
    	if not pepeg then
    		pepeg = true
			self:BOOM(unitGroup[i])
			self:Destroy()
		end
	end
end
--[[function modifier_edmon_enfer:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end]]

modifier_edmon_enfer_thinker = class({})

if IsServer() then
	function modifier_edmon_enfer_thinker:OnCreated(args)
		self.Damage = args.Damage
		self.Radius = args.Radius

		self.ThinkCount = 0

		self:StartIntervalThink(0.1)
	end

	function modifier_edmon_enfer_thinker:OnIntervalThink()
		local location = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local damage = self.Damage

		for i = 1, #targets do
			if self.ThinkCount == 0 then
				giveUnitDataDrivenModifier(caster, targets[i], "locked", 2.4)
			end
			damage = self.Damage

			DoDamage(caster, targets[i], damage/23, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			targets[i]:AddNewModifier(caster, ability, "modifier_edmon_enfer_slow", { Duration = 0.3 })
		end

		self.ThinkCount = self.ThinkCount + 1

		if self.ThinkCount >= 23 then
			self:Destroy()
		end
	end
end

modifier_edmon_enfer_slow = class({})

function modifier_edmon_enfer_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_edmon_enfer_slow:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

function modifier_edmon_enfer_slow:IsHidden()
	return true 
end

modifier_edmon_enfer_cooldown = class({})

function modifier_edmon_enfer_cooldown:GetTexture()
	return "custom/edmon/enfer"
end

function modifier_edmon_enfer_cooldown:IsHidden()
	return false 
end

function modifier_edmon_enfer_cooldown:RemoveOnDeath()
	return false
end

function modifier_edmon_enfer_cooldown:IsDebuff()
	return true 
end

function modifier_edmon_enfer_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end