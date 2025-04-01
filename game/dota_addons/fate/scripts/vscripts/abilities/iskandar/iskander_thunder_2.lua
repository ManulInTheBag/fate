iskander_thunder_2 = class({})
LinkLuaModifier("iskander_thunder_slow_2", "abilities/iskandar/iskander_thunder_2", LUA_MODIFIER_MOTION_NONE)


function iskander_thunder_2:OnSpellStart()
	local caster = self:GetCaster()

	local range = self:GetSpecialValueFor("radius")
	local soundQueue = math.random(1, 4)
	local casterPos = caster:GetAbsOrigin()
	local targetPos = self:GetCursorPosition()
	local vector = -(casterPos - targetPos):Normalized()
	local distanceBetweenStrikes = range/3
	caster:EmitSound("Iskander_Skill_" .. soundQueue)
	for i = 0, 5 do 

		for j=1,3  do
			Timers:CreateTimer((j-1)*0.3, function()
				local thunder_pos = PointOnCircle(GetGroundPosition(caster:GetAbsOrigin(), caster), distanceBetweenStrikes * j, i * 45)
				self:ThunderStrike(thunder_pos)
			
			
			end)

		end

	end
    
end

function iskander_thunder_2:ThunderStrike(position)
	local caster = self:GetCaster()
	local radius = 250
	local slow_duration = 1
	local damage = self:GetSpecialValueFor("damage")

	local targets = FindUnitsInRadius(caster:GetTeam(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
	    v:AddNewModifier(caster, self, "iskander_thunder_slow_2", { duration = slow_duration })
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



iskander_thunder_slow_2 = class({})

function iskander_thunder_slow_2:IsDebuff() return true end
function iskander_thunder_slow_2:IsHidden() return false end
function iskander_thunder_slow_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function iskander_thunder_slow_2:GetModifierMoveSpeedBonus_Percentage()
	return -60
end

