hijikata_demon = class({})

LinkLuaModifier("modifier_demon_buff_hijikata", "abilities/hijikata/hijikata_demon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_attack_sound","abilities/hijikata/hijikata_demon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_slow", "abilities/hijikata/hijikata_demon", LUA_MODIFIER_MOTION_NONE)

function hijikata_demon:GetIntrinsicModifierName()
	return "modifier_hijikata_attack_sound"
end

modifier_hijikata_attack_sound = class({})

function modifier_hijikata_attack_sound:OnCreated()
	self.sound = "hijikata_attack_"..math.random(1,3)
end

function modifier_hijikata_attack_sound:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "hijikata_attack_"..math.random(1,3)

end

function modifier_hijikata_attack_sound:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_hijikata_attack_sound:DeclareFunctions()
	local func = {
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

				}
	return func
end

function modifier_hijikata_attack_sound:GetAttackSound()
	return self.sound
end
 
function modifier_hijikata_attack_sound:IsHidden() return true end
function modifier_hijikata_attack_sound:RemoveOnDeath() return false end



function hijikata_demon:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end



function hijikata_demon:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end -- Linken effect checker

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	if((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("radius")) then
		self:EndCooldown()
		return
	end
	caster:EmitSound("hijikata_serya")
	caster:EmitSound("hijikata_demon_sfx")
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	--StartAnimation(caster, {duration=0.35, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=2})
	
	local damage = self:GetSpecialValueFor("damage") 
	if caster.IsHijikataTacticsAcquired then
		damage = damage + self:GetSpecialValueFor("bonus_damage")
	end
	--local duration = self:GetSpecialValueFor("duration")


	--target:AddNewModifier(caster, v, "modifier_rooted", {Duration = duration})
	--target:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})
	--giveUnitDataDrivenModifier(caster, target, "locked", duration)
	caster:PerformAttack(target, true, true, true, true, false, false, false)

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	if caster.IsHijikataTacticsAcquired then
		target:AddNewModifier(caster, self, "modifier_hijikata_slow", { duration = self:GetSpecialValueFor("slow_duration")})
																				
	end
	caster:AddNewModifier(caster, self, "modifier_demon_buff_hijikata", { duration = self:GetSpecialValueFor("buff_duration"),
                                                                            as_value = self:GetSpecialValueFor("as_value"),
                                                                            percentage = self:GetSpecialValueFor("hp_percentage_diff_to_damage") })

	--particle
	--caster:EmitSound("Hero_Huskar.Life_Break")
	local particle = ParticleManager:CreateParticle("particles/hijikata/hijikata_demon_pierce.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)
end

modifier_demon_buff_hijikata = class({})

function modifier_demon_buff_hijikata:OnCreated(args)
	if IsServer() then 
        self.as_value = args.as_value
        self.percentage = args.percentage
        self.caster = self:GetParent()
    end
end

function modifier_demon_buff_hijikata:GetModifierAttackSpeedBonus_Constant()
	return self.as_value
end

function modifier_demon_buff_hijikata:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_demon_buff_hijikata:IsHidden() 
	return false 
end

function modifier_demon_buff_hijikata:IsDebuff() 
	return false 
end


function modifier_demon_buff_hijikata:OnAttackLanded(args) 
	if args.attacker ~= self.caster then return end
    if args.target:GetTeamNumber() == self.caster:GetTeamNumber() then return end
    if not self.caster:IsAlive() then return end
    local caster_health = self.caster:GetHealth()
    local target_health = args.target:GetHealth()
    local damage = (target_health - caster_health)/100 * self.percentage
    if damage <= 0 then return end
    DoDamage(self.caster, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
end

 
modifier_hijikata_slow = class({})

function modifier_hijikata_slow:IsDebuff() return true end
function modifier_hijikata_slow:IsHidden() return false end
function modifier_hijikata_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_hijikata_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_amount")
end
