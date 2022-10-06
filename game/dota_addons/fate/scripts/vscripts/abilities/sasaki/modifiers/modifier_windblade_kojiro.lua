modifier_windblade_kojiro = class({})

LinkLuaModifier("modifier_windblade_hit_marker", "abilities/sasaki/modifiers/modifier_windblade_hit_marker", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_windblade_kojiro:OnCreated(args)
		self.WindbladeOrigin = self:GetParent():GetAbsOrigin()

		self.Empowered = args.Empowered

		self.RemainingHits = args.RemainingHits
		self.Radius = args.Radius
		self.StunDuration = args.StunDuration
		self:StartIntervalThink(0.033)

		if args.Empowered == 1 then
			self.State = {  [MODIFIER_STATE_INVULNERABLE] = true,
						    [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
							[MODIFIER_STATE_STUNNED] = true,
							[MODIFIER_STATE_SILENCED] = true,
							[MODIFIER_STATE_NO_UNIT_COLLISION] = true }
		else
			self.State = {	[MODIFIER_STATE_STUNNED] = true,
							[MODIFIER_STATE_SILENCED] = true,
							[MODIFIER_STATE_NO_UNIT_COLLISION] = true }
		end
	end

	function modifier_windblade_kojiro:OnIntervalThink()
		local caster = self:GetParent()
		local target_search = FindUnitsInRadius(caster:GetTeam(), self.WindbladeOrigin, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
		local damage = self:GetAbility():GetSpecialValueFor("base_damage")
		local continue_possible = true
		local current_location = caster:GetAbsOrigin()
		local skip_target = false

		ProjectileManager:ProjectileDodge(caster)

		for i = 1, #target_search do
			skip_target = false
			if target_search[i]:HasModifier("modifier_windblade_hit_marker") or target_search[i]:HasModifier("modifier_wind_protection_passive") then
				local stacks = target_search[i]:GetModifierStackCount("modifier_windblade_hit_marker", caster)
				if stacks >= 6 or target_search[i]:HasModifier("modifier_wind_protection_passive") then 
					skip_target = true 
				end			
			end

			if not skip_target then
				local diff = target_search[i]:GetAbsOrigin() - caster:GetAbsOrigin()
				caster:SetAbsOrigin(target_search[i]:GetAbsOrigin() - diff:Normalized() * 100)
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)				

				caster:PerformAttack(target_search[i], true, true, true, true, false, false, false)
				DoDamage(caster, target_search[i], damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
				self.RemainingHits = self.RemainingHits - 1

				if caster:HasModifier("modifier_sasaki_kappa") then
					target_search[i]:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", { Duration = self.StunDuration })
				end

				CreateSlashFx(caster, current_location, target_search[i]:GetAbsOrigin() + RandomVector(200))
				target_search[i]:AddNewModifier(caster, self:GetAbility(), "modifier_windblade_hit_marker", { Duration = 0.433 })
				break
			elseif skip_target and i == #target_search then
				continue_possible = false
			end
		end

		if self.RemainingHits <= 0 or not continue_possible or #target_search == 0 then
			self:Destroy()
		end
	end

	function modifier_windblade_kojiro:CheckState()
		return self.State
	end
end



function modifier_windblade_kojiro:IsHidden()
	return true 
end

function modifier_windblade_kojiro:RemoveOnDeath()
	return true
end

function modifier_windblade_kojiro:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end