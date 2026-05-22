LinkLuaModifier("modifier_diar_dash_w", "abilities/diarmuid/diarmuid_dash", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_rampant_warrior", "abilities/diarmuid/modifiers/modifier_rampant_warrior", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior_cooldown", "abilities/diarmuid/modifiers/modifier_rampant_warrior_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_double_spearmanship_passive", "abilities/diarmuid/modifiers/modifier_double_spearmanship_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior_window", "abilities/diarmuid/modifiers/modifier_rampant_warrior_window", LUA_MODIFIER_MOTION_NONE)
diarmuid_dash = class({})

function diarmuid_dash:OnUpgrade()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_double_spearmanship_passive", {})
end

function diarmuid_dash:GetAbilityTextureName()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_rampant_warrior_window") then 
		return "custom/diarmuid_rampant_warrior"
	else
		return "custom/diarmuid_double_spearsmanship"
	end
end

function diarmuid_dash:OnSpellStart()
    local caster = self:GetCaster()


	if caster:HasModifier("modifier_rampant_warrior_window") then

		if caster:FindAbilityByName("diarmuid_new_combo"):IsCooldownReady()  then
             
            caster:SwapAbilities("diarmuid_new_combo", "diarmuid_warrior_charge", true, false)
    
            Timers:CreateTimer("diar_combo_window",{
                endTime = 4,
                callback = function()
                local index0ability = caster:GetAbilityByIndex(0):GetName()
                if index0ability == "diarmuid_new_combo"  then
                     caster:SwapAbilities("diarmuid_new_combo", "diarmuid_warrior_charge", false, true)
                end
                 
            end
            })
    
        end
	else
		local point          = self:GetCursorPosition() + RandomVector(1)
		local direction      = (point -caster:GetAbsOrigin()):Normalized()
		direction.z = 0
		caster:FaceTowards(point)
		caster:SetForwardVector(direction)
		caster:AddNewModifier(caster, self, "modifier_diar_dash_w", {})
		LoopOverPlayers(function(player, playerID, playerHero)
			--print("looping through " .. playerHero:GetName())
			if playerHero.gachi == true and playerHero == self:GetCaster() then
				-- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diar_w"})
				--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			end
		end)
        if caster:HasModifier("modifier_hero_selection_skin") then
            caster:EmitSound("lucio_dash_voice")
        else
            caster:EmitSound("diar_w_dash")
        end	   


		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
			if caster:FindAbilityByName("diarmuid_new_combo"):IsCooldownReady()  then
				caster:AddNewModifier(caster, self, "modifier_rampant_warrior_window", { Duration = 4 })
				self:EndCooldown()
				Timers:CreateTimer(4, function()
				if(caster:HasModifier("modifier_rampant_warrior_window")) then
					self:StartCooldown(self:GetCooldown(self:GetLevel()) - 3) 
				end
				
				end)
			end
		end
	end	
end

function diarmuid_dash:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end


function diarmuid_dash:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function diarmuid_dash:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end


modifier_diar_dash_w = class({})
function modifier_diar_dash_w:IsHidden() return true end
function modifier_diar_dash_w:IsDebuff() return false end
function modifier_diar_dash_w:IsPurgable() return false end
function modifier_diar_dash_w:IsPurgeException() return false end
function modifier_diar_dash_w:RemoveOnDeath() return true end
function modifier_diar_dash_w:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_diar_dash_w:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_diar_dash_w:CheckState()
    local state =   { 
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = false,

                    }
    return state
end
function modifier_diar_dash_w:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_diar_dash_w:GetOverrideAnimation()
    return ACT_DOTA_RAZE_1
end
function modifier_diar_dash_w:GetOverrideAnimationRate()
    return 2.5
end
function modifier_diar_dash_w:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
	self.damage = self.ability:GetSpecialValueFor("damage")
	self.HittedTargets = {}
	self.cdreduct = false
    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("dash_speed")
        self.distance       = self.ability:GetSpecialValueFor("distance")

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        self.parent:Stop()
        self.parent:FaceTowards(self.point)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())



        self:AddParticle(self.dash_fx2, false, false, -1, true, false)
        

        self:StartIntervalThink(FrameTime())

    end
end
function modifier_diar_dash_w:OnIntervalThink()
	if IsServer() and IsNotNull(self.parent) then
        local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(), 
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            200, 
                                            self.ability:GetAbilityTargetTeam(), 
                                            self.ability:GetAbilityTargetType(), 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

        for _, enemy in pairs(enemies) do
            if enemy and not enemy:IsNull() then
                if not self.HittedTargets[enemy:entindex()] then
                    self.HittedTargets[enemy:entindex()] = true

                    if self.parent:HasModifier("modifier_hero_selection_skin") then
                        enemy:EmitSound("lucio_dash")
                    else
                        enemy:EmitSound("Hero_PhantomLancer.Attack")
                    end	   


                    DoDamage(self.caster, enemy, self.damage, self.ability:GetAbilityDamageType(), 0, self.ability, false)
					local cd1 = self.parent:FindAbilityByName("diarmuid_warrior_charge"):GetCooldownTimeRemaining()

					if cd1 > self.ability:GetSpecialValueFor("q_cdr") and not self.cdreduct then 
						self.parent:FindAbilityByName("diarmuid_warrior_charge"):EndCooldown()
						self.parent:FindAbilityByName("diarmuid_warrior_charge"):StartCooldown(cd1 - self.ability:GetSpecialValueFor("q_cdr") )
						self.cdreduct = true
					end
					local petals = ParticleManager:CreateParticle("particles/zlodemon/diar_combo/petals_jopa.vpcf", PATTACH_ABSORIGIN, enemy)
					ParticleManager:SetParticleControl(petals, 0, enemy:GetAbsOrigin())
					ParticleManager:ReleaseParticleIndex(petals)

                end
            end
        end
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
	end
end
function modifier_diar_dash_w:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_diar_dash_w:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.parent:IsStunned() then
            return nil
        end

        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()
            local direction = self.direction--self.parent:GetForwardVector()

            local next_pos = parent_pos + direction * units_per_dt
            next_pos = GetGroundPosition(next_pos, self.parent)
            local distance_will = self.distance - units_per_dt

            if distance_will < 0 then
       
            end

            self.parent:SetOrigin(next_pos)


            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_diar_dash_w:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_diar_dash_w:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_diar_dash_w:PlayEffects()

end