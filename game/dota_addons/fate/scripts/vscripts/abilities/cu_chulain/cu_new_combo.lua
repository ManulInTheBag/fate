cu_new_combo = class({})

LinkLuaModifier("modifier_self_disarm", "abilities/cu_chulain/modifiers/modifier_self_disarm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_combo_self", "abilities/cu_chulain/cu_new_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_cooldown", "abilities/cu_chulain/modifiers/modifier_wesen_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_3_uncleansable", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_chulain_combo", "abilities/cu_chulain/cu_new_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_chulain_combo_weak", "abilities/cu_chulain/cu_new_combo", LUA_MODIFIER_MOTION_NONE)
function cu_new_combo:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or caster:IsDisarmed() then 
			return UF_FAIL_CUSTOM 		
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function cu_new_combo:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	elseif self:GetCaster():IsDisarmed() then
		return "#Disarmed"
	else
		return "#Cannot_Cast"
	end
end

function cu_new_combo:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local ability = hCaster:FindAbilityByName("cu_chulain_gae_bolg_jump")
		vLookatTarget = -(hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
		vLookatTarget.z = 0
		self.ForwardVector = vLookatTarget
		hCaster:SetForwardVector(self.ForwardVector)
		hCaster:FaceTowards(hTarget:GetAbsOrigin())
	if not hCaster.HeartSeekerImproved and IsSpellBlocked(hTarget) then
		return
	end
	self.combotarget = hTarget
	local soundQueue = math.random(1,4)

	if soundQueue ~= 4 then
		hCaster:EmitSound("Cu_Combo_" .. soundQueue)
		hTarget:EmitSound("Cu_Combo_" .. soundQueue)
	else
		hCaster:EmitSound("Lancer.Heartbreak")
		hTarget:EmitSound("Lancer.Heartbreak")
	end

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ya_trahnu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end) 

	--giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealdisabled", 2.6)

	ability:StartCooldown(ability:GetCooldown(-1)* hCaster:GetCooldownReduction())

	hCaster:AddNewModifier(hCaster, self, "modifier_self_disarm", { Duration = 3 })
	hCaster:AddNewModifier(hCaster, self, "modifier_wesen_cooldown", { Duration = self:GetCooldown(1) })

	local masterCombo = hCaster.MasterUnit2:FindAbilityByName("cu_new_combo")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(masterCombo:GetCooldown(1))


	hCaster:AddNewModifier(hCaster, self, "modifier_cu_combo_self", { Duration = 0.9, target = hTarget })

	

	local vLookatTarget = -(hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
	vLookatTarget.z = 0

	local caster_name =  PlayerResource:GetPlayerName(hCaster:GetPlayerID())
	local target_name =  PlayerResource:GetPlayerName(hTarget:GetPlayerID())


	
	GameRules:SendCustomMessage("<font color='#0083E3'>".. caster_name .." :</font> I shall claim your heart <font color='#FF0000'>".. target_name .."</font>, your heart is mine!", 0, 0)
	self.ForwardVector =vLookatTarget
	hCaster:SetForwardVector(self.ForwardVector)
	hCaster:FaceTowards(hTarget:GetAbsOrigin())
	if hCaster:IsAlive() then
		Timers:CreateTimer(0.9, function() 
		giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 2)
		StartAnimation(hCaster, {duration=0.3, activity=ACT_DOTA_CAST_REFRACTION , rate=1.5})
		
		Timers:CreateTimer(0.25, function() 
			--EndAnimation(hCaster)
			StartAnimation(hCaster, {duration=1.1, activity=ACT_DOTA_CAST_ICE_WALL , rate=1.3})
			Timers:CreateTimer(0.25, function() 
				hCaster:EmitSound("cu_new_combo_1")
			end)

		end)
		vLookatTarget = -(hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
		vLookatTarget.z = 0
		self.ForwardVector = vLookatTarget
		hCaster:SetForwardVector(self.ForwardVector)
		hCaster:FaceTowards(hTarget:GetAbsOrigin())
		local ascendCount = 0
		local descendCount = 0	

		local jump_fx = ParticleManager:CreateParticle("particles/cu_chulain/combo_gb_targetted_jumo.vpcf", PATTACH_ABSORIGIN, hCaster )
		ParticleManager:SetParticleControl( jump_fx, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl( jump_fx, 1, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl( jump_fx, 3, hCaster:GetAbsOrigin())
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( jump_fx, false )
			ParticleManager:ReleaseParticleIndex( jump_fx)
		end)
		Timers:CreateTimer('gb_ascend', {
			endTime = 0,
			callback = function()
			if ascendCount == 15 then 	  
				
				Timers:CreateTimer(0.75, function() 
				
					StartAnimation(hCaster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=0.3})


				end)
				return 
			end
			hCaster:SetAbsOrigin(Vector(hCaster:GetAbsOrigin().x,hCaster:GetAbsOrigin().y,hCaster:GetAbsOrigin().z+40)+ self.ForwardVector * -50) 
			vLookatTarget = -(hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
			vLookatTarget.z = 0
			hCaster:SetForwardVector(self.ForwardVector)
			hCaster:FaceTowards(hTarget:GetAbsOrigin())
			self.ForwardVector = vLookatTarget
			ascendCount = ascendCount + 1;
			return 0.05
		end
		})

		Timers:CreateTimer("gb_descend", {
			endTime = 1.3,
			callback = function()
				if descendCount == 15 then 
					FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true) 	return 
				end
				hCaster:SetAbsOrigin(Vector(hCaster:GetAbsOrigin().x,hCaster:GetAbsOrigin().y,hCaster:GetAbsOrigin().z-40))
				descendCount = descendCount + 1;
				return 0.033
			end
		})
		end)
	end

	Timers:CreateTimer(2.0, function() 
		vLookatTarget = -(hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
		vLookatTarget.z = 0
		self.ForwardVector =vLookatTarget
		hCaster:SetForwardVector(self.ForwardVector)
		hCaster:FaceTowards(hTarget:GetAbsOrigin())
		hCaster:SetBodygroup(0,1)
		if (hCaster.HeartSeekerImproved or hCaster:IsAlive())  then
			self.target = hTarget 
			local tProjectile = {
		        Target = hTarget,
		        Source = hCaster,
		        Ability = self,
		        level = 0,
		        EffectName = "particles/cu_chulain/combo_gb_targetted.vpcf",
		        iMoveSpeed = 5000,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES ,
		        vSourceLoc = hCaster:GetAbsOrigin(),
		        bDodgeable = false,
		        flExpireTime = GameRules:GetGameTime() + 10,
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		    }

		    ProjectileManager:CreateTrackingProjectile(tProjectile)

		end
	end)   

end

function cu_new_combo:OnProjectileThink_ExtraData(vLocation, table)
	local caster = self:GetCaster()

	--vLocation = GetGroundPosition(vLocation, nil)

	--caster:SetAbsOrigin(vLocation)
	--caster:SetForwardVector(self.target:GetAbsOrigin() - caster:GetAbsOrigin())
end

function cu_new_combo:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local damage_aoe = self:GetSpecialValueFor("damage_aoe")
	-- local heartbreak = self:GetSpecialValueFor("heartbreak")	
	-- --hCaster:SetBodygroup(0,0)
	-- if hCaster.HeartSeekerImproved then
	-- 	heartbreak = self:GetSpecialValueFor("attribute_heartbreak")
	-- end

	LoopOverPlayers(function(player, playerID, playerHero)
        	--print("looping through " .. playerHero:GetName())
        		if playerHero.gachi == true then
            	-- apply legion horn vsnd on their client
            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="pomnish_menya"})
            		--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        		end
    		end) 

	--hCaster:RemoveModifierByName("jump_pause")
	hTarget:EmitSound("cu_new_combo_2")
	hTarget:EmitSound("cu_new_combo_3")
	--FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true)
	hCaster:SetForwardVector(self.ForwardVector)
	hCaster:FaceTowards(hTarget:GetAbsOrigin())
	--StartAnimation(hCaster, {duration=1, activity=ACT_DOTA_CAST_GHOST_SHIP , rate=0.6})
	--hTarget:RemoveModifierByName("modifier_heart_of_harmony")
	--hTarget:RemoveModifierByName("modifier_share_damage")
	--hTarget:RemoveModifierByName("modifier_master_intervention")
	ApplyStrongDispel(hTarget)

	Timers:CreateTimer( 1, function()
		EndAnimation(hCaster)
	end)
	 if hTarget:IsAlive() then 
		hTarget:AddNewModifier(hCaster, self, "modifier_heal_reduction_tier_3_uncleansable", {Duration = self:GetSpecialValueFor("target_debuffs_duration_strong")})
		hTarget:AddNewModifier(hCaster, self, "modifier_cu_chulain_combo", {Duration = self:GetSpecialValueFor("target_debuffs_duration_strong")})
		hTarget:AddNewModifier(hCaster, self, "modifier_cu_chulain_combo_weak", {Duration = self:GetSpecialValueFor("target_debuffs_duration_weak")})
		DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
	 end
	local targets = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(hCaster, v, damage_aoe, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(hCaster, v, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
	        --v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback )
	    end
	local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile)
	local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
	local explodeFx1 = ParticleManager:CreateParticle("particles/cu_chulain/combo_gb_targetted_explosion.vpcf", PATTACH_ABSORIGIN, hTarget )
		ParticleManager:SetParticleControl( fire, 0, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl( crack, 0, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, hTarget:GetAbsOrigin())
		ScreenShake(hTarget:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( fire, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
			ParticleManager:ReleaseParticleIndex( explodeFx1 )
			ParticleManager:ReleaseParticleIndex( fire )
			ParticleManager:ReleaseParticleIndex( crack )
		end)

	-- if hTarget:GetHealthPercent() < heartbreak and not (hTarget:IsMagicImmune() or hTarget:HasModifier("modifier_avalon")) then
	-- 	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	-- 	ParticleManager:SetParticleControl( hb, 0, hTarget:GetAbsOrigin())

	-- 	Timers:CreateTimer( 3.0, function()			
	-- 		ParticleManager:DestroyParticle( hb, false )
	-- 	end)
	-- 	giveUnitDataDrivenModifier(hCaster, hTarget, "can_be_executed", 0.033)
	-- 	hTarget:Execute(self, hCaster, { bExecution = true })
	-- end


		hCaster.gbDummy = CreateUnitByName("dummy_unit_ground", hTarget:GetAbsOrigin(), false, nil, nil, hCaster:GetTeamNumber())
		hCaster.gbDummy:FindAbilityByName("dummy_unit_passive_no_fly"):SetLevel(1)

		local tProjectile = {
			Target = hCaster,
			Source = hCaster.gbDummy,
			Ability =hCaster:FindAbilityByName("cu_chulain_gae_bolg_jump"),
			level = 0,
			EffectName = "particles/custom/lancer/soaring/spear.vpcf",
			iMoveSpeed = 3000,
			vSourceLoc = hCaster.gbDummy:GetAbsOrigin(),
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES ,
			bDodgeable = false,
			flExpireTime = GameRules:GetGameTime() + 10,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		}

		hCaster.gbProjectile = ProjectileManager:CreateTrackingProjectile(tProjectile)


	
end




modifier_cu_combo_self = class({})

function modifier_cu_combo_self:OnCreated()
    self:StartIntervalThink(0.033)
    self.caster = self:GetCaster()
	self.target = self:GetAbility().combotarget
	
	self.speed = 100
end

function modifier_cu_combo_self:OnIntervalThink()
    if not IsServer() then return end
	self.speed = (self.target:GetAbsOrigin() - self.caster:GetAbsOrigin()):Length2D() - 100
    self.caster:MoveToTargetToAttack(self.target)
  


end

function modifier_cu_combo_self:DeclareFunctions()
	return {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
				}
end

function modifier_cu_combo_self:GetModifierProvidesFOWVision()
    return 1
end

function modifier_cu_combo_self:GetModifierIncomingDamage_Percentage() 
	return -40
end

function modifier_cu_combo_self:GetModifierMoveSpeed_Absolute()
	return self.speed  --self:GetAbility():GetSpecialValueFor("run_speed")
end
function modifier_cu_combo_self:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 
 


function modifier_cu_combo_self:IsHidden() return false end
function modifier_cu_combo_self:RemoveOnDeath() return true end
function modifier_cu_combo_self:IsDebuff() return true end
 
 
 
function modifier_cu_combo_self:CheckState()
	local state =   { 
						
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = false,
		[MODIFIER_STATE_STUNNED] = false,
	}
    return state
    
end


modifier_cu_chulain_combo = class({})

function modifier_cu_chulain_combo:OnCreated()
	self.speedEffect = self:GetAbility():GetSpecialValueFor("slow_powerful")

	self:StartIntervalThink(FrameTime())
end

function modifier_cu_chulain_combo:OnIntervalThink()
	if not IsServer() then return end

	ApplyStrongDispel(self:GetParent())
end


function modifier_cu_chulain_combo:DeclareFunctions()
	return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
				}
end



function modifier_cu_chulain_combo:GetModifierMoveSpeedBonus_Percentage()
	return -self.speedEffect 
end


function modifier_cu_chulain_combo:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 
 
function modifier_cu_chulain_combo:GetStatusEffectName()
    return "particles/cu_chulain/cu_combo_status.vpcf"
end

 

function modifier_cu_chulain_combo:IsHidden() return false end
function modifier_cu_chulain_combo:RemoveOnDeath() return true end
function modifier_cu_chulain_combo:IsDebuff() return true end
 
 
modifier_cu_chulain_combo_weak = class({})

function modifier_cu_chulain_combo_weak:OnCreated()
	self.speedEffect = self:GetAbility():GetSpecialValueFor("slow_weak")
end


function modifier_cu_chulain_combo_weak:DeclareFunctions()
	return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
				}
end

function modifier_cu_chulain_combo_weak:GetModifierProvidesFOWVision()
    return 1
end

function modifier_cu_chulain_combo_weak:GetModifierMoveSpeedBonus_Percentage()
	return -self.speedEffect 
end


function modifier_cu_chulain_combo_weak:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 

function modifier_cu_chulain_combo_weak:IsHidden() return false end
function modifier_cu_chulain_combo_weak:RemoveOnDeath() return true end
function modifier_cu_chulain_combo_weak:IsDebuff() return true end
 
 
