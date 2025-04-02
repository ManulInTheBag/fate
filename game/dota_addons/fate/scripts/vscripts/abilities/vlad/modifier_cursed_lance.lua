modifier_cursed_lance = class({})


-- if not IsServer() then
-- 	return
-- end


function cl_wrapper(modifier)
	function modifier:GetAttributes()
	  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
	end

	if  IsServer() then

		function modifier:VFX0_Counter(parent)
			local dmg_counter = math.floor(((self.CL_MAX_SHIELD - (self.fBarrierBlock or 0))/self.CL_MAX_SHIELD)*(self.CL_MAX_DMG))
			--print("PAINTER VALUES ARE : "..dmg_counter.."    "..self.fBarrierBlock.."     ".. self.CL_MAX_SHIELD.."     ".. self.CL_MAX_DMG)
			local digit = 0
			if dmg_counter > 999 then
				digit = 4
			elseif dmg_counter > 99 then
				digit = 3
			elseif dmg_counter > 9 then
				digit = 2
			else
				digit = 1
				if dmg_counter == 0 then
					dmg_counter = 5200 --hacky and clean way (i guess?) to draw 0 ONCE without making code spaghetti ---- dont use dmg_counter for anything else if this is enabled
				end
			end
			FxDestroyer(self.PI0, true)
			self.PI0 = ParticleManager:CreateParticleForPlayer( "particles/custom/vlad/vlad_cl_popup.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent, parent:GetPlayerOwner() )
			ParticleManager:SetParticleControlEnt( self.PI0, 0, parent,  PATTACH_CUSTOMORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), false )
			ParticleManager:SetParticleControl( self.PI0, 1, Vector( 0, dmg_counter, 0 ) )  -- 0,counter,0
			ParticleManager:SetParticleControl( self.PI0, 2, Vector( 10, digit, 0 ) ) --duration, count of digits to draw, 0
			ParticleManager:SetParticleControl( self.PI0, 3, Vector( 252, 75, 75 ) )--color
			ParticleManager:SetParticleControl( self.PI0, 4, Vector( 30,0,0) ) --size/radius, 0 ,0
		end
		function modifier:VFX1_Shield(parent)
			self.PI1 = FxCreator("particles/custom/vlad/vlad_cl_shield.vpcf",PATTACH_ABSORIGIN_FOLLOW,parent,0,nil)
			self.PI2 = FxCreator("particles/custom/vlad/vlad_cl_shield2.vpcf",PATTACH_ABSORIGIN_FOLLOW,parent,0,nil)
		end
		function modifier:VFX2_PreExplosion(parent)
			self.PI3 = FxCreator("particles/custom/vlad/vlad_cl_preexplosion.vpcf",PATTACH_ABSORIGIN_FOLLOW,parent,0,nil)
			ParticleManager:SetParticleControlEnt( self.PI3, 1, parent,  PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), false )
		end
		function modifier:VFX3_Explosion(parent)
			self.PI4 = FxCreator("particles/custom/vlad/vlad_cl_explosion.vpcf",PATTACH_ABSORIGIN_FOLLOW,parent,0,nil)
			ParticleManager:SetParticleControlEnt( self.PI4, 1, parent,  PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), false )
			ParticleManager:SetParticleControlEnt( self.PI4, 3, parent,  PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), false )
		end
		function modifier:VFX4_AOEIndicator(parent)
			self.PI5 = ParticleManager:CreateParticleForTeam( "particles/custom/vlad/vlad_cl_indicator.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent, parent:GetTeamNumber())
			ParticleManager:SetParticleControlEnt( self.PI5, 0, parent,  PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), false )
			ParticleManager:SetParticleControl( self.PI5, 1, Vector( self:GetAbility():GetSpecialValueFor("aoe")+50, 0, 0 ) )
		end
		function modifier:VFX5_ExpiringIndicator()
			if self.PI6 == nil and  self:GetRemainingTime() < 3  and self.CL_MAX_SHIELD ~= self.fBarrierBlock then --self.CL_SHIELDLEFT ~= self.CL_MAX_SHIELD and
				local parent = self:GetParent()
				self.PI6 = FxCreator("particles/custom/vlad/vlad_cl_expiring.vpcf",PATTACH_POINT_FOLLOW,parent,3,"attach_hitloc")
				Timers:CreateTimer(function()
					if not self:IsNull() then
						self.timer_tick = self.timer_tick+1
						local cp_adjust = (9+self.timer_tick-self:GetRemainingTime())/7
						local cp_vector = Vector(cp_adjust, cp_adjust/1.1, 1 )
						ParticleManager:SetParticleControl( self.PI6, 4,  cp_vector)
						return 0.1
					else
						return nil
					end
				end)
			end
		end
	end

	function modifier:OnDestroy()
		--print("ondestroy")
		--print("no explosion, destroy all particles")
		self:StartIntervalThink(-1)
			if  IsServer() then
				FxDestroyer(self.PI0, true)
				FxDestroyer(self.PI1, false)
				FxDestroyer(self.PI2, false)
				FxDestroyer(self.PI5, true)
				FxDestroyer(self.PI6, false)
			end
			Timers:CreateTimer(1, function()
				FxDestroyer(self.PI3, false)
				FxDestroyer(self.PI4, false)
			end)
		local caster = self:GetCaster()
		if caster.InstantSwapTimer then
			--print("TimerCheck")
			Timers:RemoveTimer(caster.InstantSwapTimer)
			caster.InstantSwapTimer = nil
			caster:SwapAbilities("vlad_cursed_lance", "vlad_instant_curse", true, false)
		end
	end

	function modifier:UpdateModVars(shield,dmg)
		local ability = self:GetAbility()
		self.CL_MAX_DMG = dmg or ability:GetSpecialValueFor("max_dmg")
		self.CL_MAX_SHIELD = shield or ability:GetSpecialValueFor("max_shield")
		self.__cl_prev_amount = 7052 --its needed to put smh in this var after all
	end

	function modifier:OnCreated()
		local parent = self:GetParent()
		self:UpdateModVars()
		self:ApplyAttrBonuses(parent) --attribute stuff
		self.timer_tick = 0
		self.isICAcquired = false
		self.isICAcquired = parent.InstantCurseAcquired
		--print("set fbarrier")
		self.fBarrierBlock = self.CL_MAX_SHIELD
		--print(self.fBarrierBlock)
		self:SetStackCount(self.fBarrierBlock)
		self:StartIntervalThink(0.1)
		if  IsServer() then
			self:VFX1_Shield(parent)
			parent:EmitSound("hero_bloodseeker.rupture.cast")
		end
		
	end
	function modifier:OnRefresh()
		--print("onrefresh PROCKED WTF")
		self:OnDestroy()
		self:OnCreated()
	end

	function modifier:ApplyAttrBonuses(parent)
		local parent = self:GetParent()
		local dmg_base = self.CL_MAX_DMG
		local shield_base = self.CL_MAX_SHIELD
		--apply bonus for global bleeds
		if parent.InstantCurseAcquired then
			local bleedcounter = parent:GetGlobalBleeds()
			local master2 = parent.MasterUnit2
			local attribute_ability = master2:FindAbilityByName("vlad_attribute_instant_curse")
			self.CL_MAX_DMG = self.CL_MAX_DMG+(bleedcounter*attribute_ability:GetSpecialValueFor("cl_bonus_dmg_per_stack"))
			self.CL_MAX_SHIELD = self.CL_MAX_SHIELD+(bleedcounter*attribute_ability:GetSpecialValueFor("cl_bonus_shield_per_stack"))
		end
		--print("after instant curse :                  ", self.CL_MAX_SHIELD,"     ", self.CL_MAX_DMG)
		--apply bonus for bloodpower stacks
		if parent.BloodletterAcquired then
			if not parent:HasModifier("modifier_transfusion_self") then
				parent:ResetImpaleSwapTimer()
				local modifier = parent:FindModifierByName("modifier_transfusion_bloodpower")
		 		local bloodpower = modifier and modifier:GetStackCount() or 0
		 		local bloodpowerduration = modifier and modifier:GetRemainingTime() or 0
				local attribute_ability = parent.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter")
				local bonus_dmg_per_bloodpower = attribute_ability:GetSpecialValueFor("cl_bonus_dmg_per_stack")
				local bonus_shield_per_bloodpower = attribute_ability:GetSpecialValueFor("cl_bonus_shield_per_stack")
				local bloodpowercap = attribute_ability:GetSpecialValueFor("bloodpower_cap")
				self.CL_MAX_DMG = self.CL_MAX_DMG+ math.min(self.CL_MAX_DMG*bloodpower*bonus_dmg_per_bloodpower, self.CL_MAX_DMG*bloodpowercap*bonus_dmg_per_bloodpower)
				self.CL_MAX_SHIELD = self.CL_MAX_SHIELD+ math.min(self.CL_MAX_SHIELD*bloodpower*bonus_shield_per_bloodpower, self.CL_MAX_SHIELD*bloodpowercap*bonus_shield_per_bloodpower)
				if bloodpower > 30 then 
					parent:RemoveModifierByName("modifier_transfusion_bloodpower")
					parent:AddNewModifier(parent, self, "modifier_transfusion_bloodpower", {duration = bloodpowerduration})
					parent:SetModifierStackCount("modifier_transfusion_bloodpower", caster, bloodpower - bloodpowercap)
				else parent:RemoveModifierByName("modifier_transfusion_bloodpower")
				end
			end
		end
		--cap bonuses
		--self.CL_MAX_DMG = math.min(self.CL_MAX_DMG, dmg_base + bonus_cap)
		--self.CL_MAX_SHIELD = math.min(self.CL_MAX_SHIELD, shield_base + bonus_cap)
	end

	--shieldstuff

	function modifier:DeclareFunctions()
		local hFunc = 	{	
							--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
							MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
						}
		return hFunc
	end

	function modifier:GetModifierIncomingDamageConstant(keys)
		if self:GetStackCount() <= 0 then return end
		if IsServer() then
			if keys.damage > 0 then
				local block_now   = self:GetStackCount()
				local block_check = block_now - keys.damage
				local blocked = 0
				if block_check > 0 then
					--print("blocked")
					blocked = keys.damage
					--print(keys.damage)
					self:SetStackCount(block_check)
					self.fBarrierBlock = block_check
					--print("barrier now")
					--print(self.fBarrierBlock)
				else
					blocked = keys.damage--block_now
					local damage = keys.damage - block_now

					if damage > 0 then
						local dmgtable = {
							attacker = keys.attacker,
							victim = keys.target,
							damage = damage,
							damage_type = keys.damage_type,
							damage_flags = keys.damage_flags,
							ability = keys.inflictor
						}
						--print("destroying")
						--print("status acquired")
						--print(self.isICAcquired)
						self.fBarrierBlock = 0
						if not self.isICAcquired  then
							--print("destroying barrier in block")
							self:Destroy()
						else
							--print("seting count to 0")
							self:SetStackCount(0)
						end
						--print("applying damage")
						--print(dmgtable)
						for index, data in ipairs(dmgtable) do
							--print(index)
						
							for key, value in pairs(data) do
								--print('\t', key, value)
							end
						end
						ApplyDamage(dmgtable)
					end
				end
				--print("return")
				return -1*blocked
			end
		else
			return self:GetStackCount()
		end
	end
	
	

	--explosion
	function modifier:OnRemoved()
		--print("OnRemoved")
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local aoe = ability:GetSpecialValueFor("aoe")
		local dmg = ((self.CL_MAX_SHIELD - math.max(self.fBarrierBlock or 0,0))/self.CL_MAX_SHIELD)*(self.CL_MAX_DMG)

		if dmg > 0 then
			--print("dmg>0")
			if  IsServer() then
				self:VFX2_PreExplosion(parent)
			end
			Timers:CreateTimer(0.3, function()
				if  IsServer() then
					self:VFX3_Explosion(parent)
					parent:EmitSound("Hero_Abaddon.AphoticShield.Destroy")
					parent:EmitSound("Hero_Abaddon.AphoticShield.Destroy")
				end
				Timers:CreateTimer(0.15, function()
					--print("dmg:")
					--print(dmg)
					--print("max dmg:")
					--print(self.CL_MAX_DMG)
					local targets = FindUnitsInRadius(parent:GetTeam(), parent:GetOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
					for k,v in pairs(targets) do
						DoDamage(parent, v, dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
						if dmg >= self.CL_MAX_DMG and parent.InstantCurseAcquired then
							giveUnitDataDrivenModifier(parent, v, "silenced", 0.75)
						end
					end
				end)
			end)
			
		end
	end
	--counter and other particles
	if  IsServer() then
		function modifier:OnIntervalThink()
			if self.__cl_prev_amount ~= self.fBarrierBlock  then
				local parent = self:GetParent()
				self:VFX0_Counter(parent)
				self.__cl_prev_amount = self.fBarrierBlock
				if self.PI5 == nil and self.fBarrierBlock == 0 then --if shield is depleted
					FxDestroyer(self.PI2,false) --destroy half of shield
					self:VFX4_AOEIndicator(parent)
				end
			end
			self:VFX5_ExpiringIndicator()
		end
	end

	function modifier:IsHidden()
	  return false
	end

	function modifier:IsDebuff()
	  return false
	end

	function modifier:RemoveOnDeath()
	  return true
	end
end

cl_wrapper(modifier_cursed_lance)

