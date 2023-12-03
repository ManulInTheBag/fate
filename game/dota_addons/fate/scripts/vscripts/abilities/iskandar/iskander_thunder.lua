iskander_thunder = class({})
LinkLuaModifier("iskander_thunder_slow", "abilities/iskandar/iskander_thunder", LUA_MODIFIER_MOTION_NONE)


function iskander_thunder:OnSpellStart()
	local caster = self:GetCaster()

	local range = self:GetSpecialValueFor("range")
	local strikes_amount = self:GetSpecialValueFor("strikes")
	local soundQueue = math.random(1, 4)
	local casterPos = caster:GetAbsOrigin()
	local targetPos = self:GetCursorPosition()
	local vector = -(casterPos - targetPos):Normalized()
	local distanceBetweenStrikes = range/strikes_amount
	caster:EmitSound("Iskander_Skill_" .. soundQueue)
	for i=1, strikes_amount do
		Timers:CreateTimer((i-1)*0.3, function()
			self:ThunderStrike(casterPos + distanceBetweenStrikes*vector*i)
		
		
		end)

	end
    
end

function iskander_thunder:ThunderStrike(position)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	local damage = self:GetSpecialValueFor("damage")
	if caster.IsThundergodAcquired then 
		damage = damage + caster:GetIntellect() * self:GetSpecialValueFor("damage_per_int")
	 end
	local targets = FindUnitsInRadius(caster:GetTeam(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
	    v:AddNewModifier(caster, self, "iskander_thunder_slow", { duration = slow_duration })
	    DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	local lightningfx = ParticleManager:CreateParticle( "particles/iskander/sanya_w.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(lightningfx,2,position+Vector(100,-100,0))
	ParticleManager:SetParticleControl(lightningfx,1,position+Vector(100,-100,0))
	ParticleManager:SetParticleControl(lightningfx,0,position+Vector(100,-100,0))
	ParticleManager:SetParticleControl(lightningfx,15,position+Vector(0,0,2000))
	ParticleManager:SetParticleControl(lightningfx,16,Vector(radius,0,0))
	ParticleManager:SetParticleShouldCheckFoW(lightningfx, false)
	ParticleManager:SetParticleAlwaysSimulate(lightningfx)
	ParticleManager:ReleaseParticleIndex(lightningfx)
	EmitSoundOnLocationWithCaster(position, "Hero_Zuus.LightningBolt", caster)
end

iskander_thunder_slow = class({})

function iskander_thunder_slow:IsDebuff() return true end
function iskander_thunder_slow:IsHidden() return false end
function iskander_thunder_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function iskander_thunder_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow") 
end

