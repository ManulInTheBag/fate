diarmuid_minds_eye = class({})
LinkLuaModifier("modifier_spellblock_basic", "abilities/zlodemon_nasral/modifier_spellblock_basic", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarmuid_minds_eye", "abilities/diarmuid/modifiers/modifier_diarmuid_minds_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_minds_eye_aura", "abilities/diarmuid/modifiers/modifier_minds_eye_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function diarmuid_minds_eye:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function diarmuid_minds_eye:OnSpellStart()
	local caster = self:GetCaster()
	
	ProjectileManager:ProjectileDodge(caster)
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetSpecialValueFor("active_vision_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _,v in pairs(targets) do
    	if not v:HasModifier("modifier_murderer_mist_in") then
			self.OverheadFx = ParticleManager:CreateParticle( "particles/zlodemon/zlodemon_overhead_eye.vpcf", PATTACH_OVERHEAD_FOLLOW, v )
			ParticleManager:SetParticleControl( self.OverheadFx , 1, Vector( 1,0.1,0.1 ) )
			ParticleManager:SetParticleControl( self.OverheadFx , 2, Vector( 3,0,0 ) )
			ParticleManager:ReleaseParticleIndex(self.OverheadFx)
			v:AddNewModifier(caster, self, "modifier_vision_provider", { duration = 3 })
		end
    end

    LoopOverPlayers(function(player, playerID, playerHero)
			        --print("looping through " .. playerHero:GetName())
			        if playerHero.gachi == true and playerHero == self:GetCaster() then
			            -- apply legion horn vsnd on their client
			            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diar_eye"})
			            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			        end
    			end)

	caster:AddNewModifier(caster, self, "modifier_diarmuid_minds_eye", { Duration = self:GetSpecialValueFor("duration"),
																		 MagicResist = self:GetSpecialValueFor("magic_res"),
																		 Evasion = self:GetSpecialValueFor("evasion")})
	caster:AddNewModifier(caster, self, "modifier_spellblock_basic", { Duration = self:GetSpecialValueFor("duration")})
end

function diarmuid_minds_eye:GetIntrinsicModifierName()
	return "modifier_minds_eye_aura"
end