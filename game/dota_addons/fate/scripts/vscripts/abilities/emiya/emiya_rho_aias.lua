emiya_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias", "abilities/emiya/emiya_rho_aias", LUA_MODIFIER_MOTION_NONE)

local rhoTarget = nil

function emiya_rho_aias:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()
	local shield = self:GetSpecialValueFor("shield_amount")
	if   caster:HasModifier("modifier_shroud_of_martin")   then
		shield = shield  + 1000
	end
	rhoTarget = target 
	target.rhoShieldAmount = shield

	local soundQueue = math.random(1,2)

	if soundQueue == 1 then
		caster:EmitSound("Archer.RhoAias" ) 
	else
		caster:EmitSound("Emiya_Rho_Aias_Alt")
	end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true    then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_d"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")

	target:AddNewModifier(caster, self, "modifier_rho_aias", { duration = self:GetSpecialValueFor("duration") })
end

modifier_rho_aias = class({})


	

	function modifier_rho_aias:OnCreated(args)			
		self.rhoTargetHealth = self:GetParent():GetHealth()
		self.aiasfx = ParticleManager:CreateParticle("particles/emiya/emiya_aias_self.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self:GetParent() )
		ParticleManager:SetParticleControl( self.aiasfx, 1, Vector(1,0,0) )

		self:SetStackCount((self:GetParent().rhoShieldAmount or 0) / 10)
		self:StartIntervalThink(0.033)		
	end
if IsServer() then
	function modifier_rho_aias:OnRefresh(args)
		self:OnDestroy()
		self:OnCreated(args)
	end

	function modifier_rho_aias:OnIntervalThink()
		self.rhoTargetHealth = self:GetParent():GetHealth()
	end
end
	function modifier_rho_aias:OnDestroy()	
		ParticleManager:DestroyParticle(self.aiasfx, true)
		ParticleManager:ReleaseParticleIndex(self.aiasfx)
	end


function modifier_rho_aias:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

 
function modifier_rho_aias:RemoveOnDeath()
	return true 
end

function modifier_rho_aias:GetTexture()
	return "custom/archer_5th_rho_aias"
end