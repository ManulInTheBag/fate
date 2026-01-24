hijikata_duel_recast = class({})

function hijikata_duel_recast:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("hijikata_duel"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("hijikata_duel"):SetLevel(self:GetLevel())
    end

end
function hijikata_duel_recast:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function hijikata_duel_recast:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local total_strikes = self:GetSpecialValueFor("total_strikes")
	local damage = self:GetSpecialValueFor("damage")/3 + self:GetSpecialValueFor("damage_per_attack") * caster:GetAverageTrueAttackDamage(caster)/3
	print(damage)
	local duration = total_strikes * 0.1
	local radius = self:GetSpecialValueFor("radius")
	local active_counter = 0
	local startorigin = caster:GetAbsOrigin()
	caster:EmitSound("hijikata_afterimages")
	Timers:CreateTimer(0, function()
		if active_counter < total_strikes then
			self:CreateOneSlash( target_point + RandomVector(150) ,radius, damage, startorigin)
			self:CreateOneSlash( target_point + RandomVector(150) ,radius, damage, startorigin)
			self:CreateOneSlash( target_point + RandomVector(150) ,radius, damage, startorigin)
			active_counter = active_counter + 1
			return duration / total_strikes
		else
			return
		end
		
	
	end)


end


function hijikata_duel_recast:CreateOneSlash(position, radius, damage, startorigin)
	local caster = self:GetCaster()
	local enemies = FindUnitsInRadius(caster:GetTeam(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	for k,v in pairs(enemies) do
		if v:GetName() ~= "npc_dota_ward_base" then
			if caster.IsHijikataSincerityAcquired then
				caster:PerformAttack(v, true, false, false, false, false, false, true)
			end
			DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			
			v:EmitSound("hijikata_attack_"..math.random(1,3))
		end
	end
	if #enemies > 1 then
		caster:Heal(damage, self)
	end
	local animcount = math.random(1,2)

	if animcount == 1 then
		local particle = ParticleManager:CreateParticle("particles/zlodemon/hijik_afterimage.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 7, startorigin)
		ParticleManager:SetParticleControl(particle, 0, startorigin)
		ParticleManager:SetParticleControl(particle, 1, position)
ParticleManager:SetParticleControl(particle, 2, position)
		ParticleManager:SetParticleShouldCheckFoW(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)

	elseif animcount == 2 then
		local particle = ParticleManager:CreateParticle("particles/zlodemon/hijik_afterimage_2.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 7, startorigin)
		ParticleManager:SetParticleControl(particle, 0, startorigin)
		ParticleManager:SetParticleControl(particle, 1, position)
		ParticleManager:SetParticleControl(particle, 2, position)
		ParticleManager:SetParticleShouldCheckFoW(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)

	end



end