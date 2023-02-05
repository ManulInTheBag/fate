LinkLuaModifier("modifier_nero_spectaculi_initium", "abilities/nero/nero_spectaculi_initium", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_spectaculi_delay", "abilities/nero/nero_spectaculi_initium", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_spectaculi_initium_window", "abilities/nero/nero_spectaculi_initium", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_spectaculi_shield", "abilities/nero/nero_spectaculi_initium", LUA_MODIFIER_MOTION_NONE)


nero_spectaculi_initium = class({})

function nero_spectaculi_initium:GetBehavior()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nero_performance") then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AUTOCAST
	end
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST
end

function nero_spectaculi_initium:GetCastAnimation()
    if self:GetCaster():HasModifier("modifier_nero_performance") then
        return ACT_DOTA_CAST_ABILITY_5
    end
    return ACT_DOTA_CAST_ABILITY_1_END
end

function nero_spectaculi_initium:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function nero_spectaculi_initium:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_spectaculi_buffed"):SetLevel(self:GetLevel())
end

function nero_spectaculi_initium:GetManaCost()
    if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") then
        return 0
    end
    return 200
end

function nero_spectaculi_initium:OnSpellStart()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_nero_performance") then
		--caster:RemoveModifierByName("modifier_nero_spectaculi_initium")
		local point = self:GetCursorPosition()
		local ori = caster:GetAbsOrigin()
		local cast_range = self:GetSpecialValueFor("cast_range")
		if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
			local modifier = caster:FindModifierByName("modifier_aestus_domus_aurea_nero")
			local theatre_center = Vector(modifier.TheatreCenterX, modifier.TheatreCenterY, modifier.TheatreCenterZ)
			local theatre_size = modifier.TheatreSize
			print(theatre_center)
			print(theatre_size)
			print((theatre_center - point):Length2D())
			if (theatre_center - point):Length2D() > theatre_size then
				local dir = (point - theatre_center):Normalized()
				point = theatre_center + theatre_size*dir
			end
		else
			local diff = (ori - point):Length2D()
			if diff > cast_range then
				local dir = (point - ori):Normalized()
				point = ori + cast_range*dir
			end
		end

		local duration = self:GetSpecialValueFor("invul_duration")

		caster:AddEffects(EF_NODRAW)
		giveUnitDataDrivenModifier(caster, caster, "jump_pause", duration)
		caster:AddNewModifier(caster, self, "modifier_nero_spectaculi_delay", {duration = duration})

		local trail_fx = ParticleManager:CreateParticle("particles/nero/nero_trail.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(trail_fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(trail_fx, 1, Vector(point.x, point.y, ori.z))

		Timers:CreateTimer(0.5, function()
			ParticleManager:DestroyParticle(trail_fx, false)
			ParticleManager:ReleaseParticleIndex(trail_fx)
		end)

		caster:SetAbsOrigin(Vector(point.x, point.y, ori.z))
		EmitSoundOn("jtr_slash", caster)

		Timers:CreateTimer(duration - 0.1, function()
			EmitSoundOn("nero_swoosh_"..math.random(1,2), caster)
		end)

		Timers:CreateTimer(duration, function()
			if caster then
				StartAnimation(caster, {duration = 1.0, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1})
				caster:RemoveEffects(EF_NODRAW)
				local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			    ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
			    ParticleManager:SetParticleControl(slash_fx, 5, Vector(300, 1, 1))
			    ParticleManager:SetParticleControl(slash_fx, 10, Vector(RandomInt(-10, 10), 0, 0))

			    Timers:CreateTimer(0.4, function()
			    	ParticleManager:DestroyParticle(slash_fx, false)
			    	ParticleManager:ReleaseParticleIndex(slash_fx)
			    end)

			    if caster.IsISAcquired then
					HardCleanse(caster)
				end

			    local FirstEnemy = false
			    local damage = self:GetSpecialValueFor("damage") + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)

			    local enemies = FindUnitsInRadius(caster:GetTeam(), point, nil, self:GetSpecialValueFor("second_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		        for _,enemy in pairs(enemies) do
		            if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
		                if not enemy:IsMagicImmune() then
		                	if not FirstEnemy then
		                		FirstEnemy = true
		                		local heat_abil = caster:FindAbilityByName("nero_heat")
		    					heat_abil:IncreaseHeat(caster)
		    					if not caster:HasModifier("modifier_nero_spectaculi_initium_window") then
							        caster:AddNewModifier(caster, self, "modifier_nero_spectaculi_initium_window", {duration = self:GetSpecialValueFor("window_duration")})
							    else
							        caster:RemoveModifierByName("modifier_nero_spectaculi_initium_window")
							    end
		                	end
		                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		                end
		            end
		        end
			end
		end)
		caster:FindAbilityByName("nero_heat"):PausePerformance(duration)
	else
		local point = self:GetCursorPosition()
		caster:AddNewModifier(caster, self, "modifier_nero_spectaculi_initium", {duration = self:GetSpecialValueFor("delay") + FrameTime()})

		caster:FindAbilityByName("nero_heat"):StartPerformance(2000, 4000/1.5)

		self:ShieldCharge(self:GetSpecialValueFor("shield_amount"))
	end
end

function nero_spectaculi_initium:ShieldCharge(amount, duration)
	local caster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()
	local ShieldAmount = amount

	caster:AddNewModifier(caster, self, "modifier_nero_spectaculi_shield", {duration = self:GetSpecialValueFor("shield_duration")})
	
	if caster.argosShieldAmount == nil then 
		caster.argosShieldAmount = ShieldAmount
	else
		caster.argosShieldAmount = caster.argosShieldAmount + ShieldAmount
	end
	
	-- Create particle
	if caster.argosDurabilityParticleIndex == nil then
		local prev_amount = 0.0
		Timers:CreateTimer( function()
				-- Check if shield still valid
				if caster.argosShieldAmount > 0 and caster:HasModifier( "modifier_nero_spectaculi_shield" ) then
					-- Check if it should update
					if prev_amount ~= caster.argosShieldAmount then
						-- Change particle
						local digit = 0
						if caster.argosShieldAmount > 999 then
							digit = 4
						elseif caster.argosShieldAmount > 99 then
							digit = 3
						elseif caster.argosShieldAmount > 9 then
							digit = 2
						else
							digit = 1
						end
						if caster.argosDurabilityParticleIndex ~= nil then
							-- Destroy previous
							ParticleManager:DestroyParticle( caster.argosDurabilityParticleIndex, true )
							ParticleManager:ReleaseParticleIndex( caster.argosDurabilityParticleIndex )
						end
						-- Create new one
						caster.argosDurabilityParticleIndex = ParticleManager:CreateParticle( "particles/custom/caster/caster_argos_durability.vpcf", PATTACH_CUSTOMORIGIN, caster )
						ParticleManager:SetParticleControlEnt( caster.argosDurabilityParticleIndex, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 1, Vector( 0, math.floor( caster.argosShieldAmount ), 0 ) )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 2, Vector( 1, digit, 0 ) )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 3, Vector( 100, 100, 255 ) )
						
						prev_amount = caster.argosShieldAmount	
					end
					
					return 0.1
				else
					if caster.argosDurabilityParticleIndex ~= nil then
						ParticleManager:DestroyParticle( caster.argosDurabilityParticleIndex, true )
						ParticleManager:ReleaseParticleIndex( caster.argosDurabilityParticleIndex )
						caster.argosDurabilityParticleIndex = nil
					end
					return nil
				end
			end
		)
	end
end

modifier_nero_spectaculi_shield = class({})

function modifier_nero_spectaculi_shield:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE,
			 }
end

function modifier_nero_spectaculi_shield:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
	local caster = self:GetParent() 
	local currentHealth = caster:GetHealth() 

	caster.argosShieldAmount = caster.argosShieldAmount - args.damage
	if caster.argosShieldAmount <= 0 then
		if currentHealth + caster.argosShieldAmount <= 0 then
			print("lethal")
		else
			print("argos broken, but not lethal")
			caster:RemoveModifierByName("modifier_mordred_shield")
			caster:SetHealth(currentHealth + args.damage + caster.argosShieldAmount)
			caster.argosShieldAmount = 0
		end
	else
		print("argos not broken, remaining shield : " .. caster.argosShieldAmount)
		caster:SetHealth(currentHealth + args.damage)
	end
end

function modifier_nero_spectaculi_shield:OnDestroy()
	self:GetParent().argosShieldAmount = 0
end

modifier_nero_spectaculi_initium_window = class({})

function modifier_nero_spectaculi_initium_window:IsHidden() return false end
function modifier_nero_spectaculi_initium_window:IsDebuff() return false end
function modifier_nero_spectaculi_initium_window:IsPurgable() return false end
function modifier_nero_spectaculi_initium_window:IsPurgeException() return false end
function modifier_nero_spectaculi_initium_window:RemoveOnDeath() return true end

function modifier_nero_spectaculi_initium_window:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
	end
end

function modifier_nero_spectaculi_initium_window:OnDestroy()
	if IsServer() then
		self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
	end
end

modifier_nero_spectaculi_initium = class({})

function modifier_nero_spectaculi_initium:IsHidden() return false end
function modifier_nero_spectaculi_initium:IsDebuff() return false end
function modifier_nero_spectaculi_initium:IsPurgable() return false end
function modifier_nero_spectaculi_initium:IsPurgeException() return false end
function modifier_nero_spectaculi_initium:RemoveOnDeath() return true end

function modifier_nero_spectaculi_initium:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end

        self.stored_damage = self.stored_damage + args.damage
    end
end

function modifier_nero_spectaculi_initium:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self:StartIntervalThink(self.ability:GetSpecialValueFor("delay"))
		self.stored_damage = 0
	end
end

function modifier_nero_spectaculi_initium:OnIntervalThink()
	if IsServer() then
		local caster = self:GetParent()
		local point = caster:GetAbsOrigin()
		local damage = self.ability:GetSpecialValueFor("damage") + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self.ability:GetSpecialValueFor("damage_scale")/100 or 0)

		if caster.IsISAcquired then
			caster:Heal(self.stored_damage, self.ability)
		end
		HardCleanse(caster)
		caster:EmitSound("nero_pup")

    	local slash_fx = ParticleManager:CreateParticle("particles/nero/nero_spectaculi_warp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControl(slash_fx, 0, point)
	    --ParticleManager:SetParticleControl(slash_fx, 1, Vector(self.ability:GetSpecialValueFor("radius"), 0, 0))
	    ParticleManager:SetParticleControl(slash_fx, 2, Vector(80, 0, 0))

	    Timers:CreateTimer(0.4, function()
	    	ParticleManager:DestroyParticle(slash_fx, false)
	    	ParticleManager:ReleaseParticleIndex(slash_fx)
	    end)

	    local slash_fx_1 = ParticleManager:CreateParticle("particles/nero/nero_spectaculi_test.vpcf", PATTACH_ABSORIGIN, caster)
	    ParticleManager:SetParticleControl(slash_fx_1, 0, GetGroundPosition(point, caster))
	    ParticleManager:SetParticleControl(slash_fx_1, 1, Vector(self.ability:GetSpecialValueFor("radius"), 0, 0))
	    --ParticleManager:SetParticleControl(slash_fx_1, 2, Vector(80, 0, 0))

	    Timers:CreateTimer(1.0, function()
	    	ParticleManager:DestroyParticle(slash_fx, false)
	    	ParticleManager:ReleaseParticleIndex(slash_fx)
	    	ParticleManager:DestroyParticle(slash_fx_1, false)
	    	ParticleManager:ReleaseParticleIndex(slash_fx_1)
	    end)

	    local FirstEnemy = false

	    local enemies = FindUnitsInRadius(caster:GetTeam(), point, nil, self.ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
        for _,enemy in pairs(enemies) do
            if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
                if not enemy:IsMagicImmune() then
                	if not FirstEnemy then
                		FirstEnemy = true
                		local heat_abil = caster:FindAbilityByName("nero_heat")
    					heat_abil:IncreaseHeat(caster)
    					if not caster:HasModifier("modifier_nero_spectaculi_initium_window") then
					        caster:AddNewModifier(caster, self.ability, "modifier_nero_spectaculi_initium_window", {duration = self.ability:GetSpecialValueFor("window_duration")})
					    else
					        caster:RemoveModifierByName("modifier_nero_spectaculi_initium_window")
					    end
                	end
                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                    local knockback = { should_stun = false,
	                                knockback_duration = 0.25,
	                                duration = 0.25,
	                                knockback_distance = 500,
	                                knockback_height = 150,
	                                center_x = point.x,
	                                center_y = point.y,
	                                center_z = point.z }
	                if self:GetAbility():GetAutoCastState() == true then
	    				enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)
	    			end
                end
            end
        end
	end
end

modifier_nero_spectaculi_delay = class({})

function modifier_nero_spectaculi_delay:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true }
end

function modifier_nero_spectaculi_delay:IsHidden() return true end