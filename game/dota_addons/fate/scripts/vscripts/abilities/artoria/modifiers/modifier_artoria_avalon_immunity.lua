-----------------------------
--    Modifier: Avalon Immunity    --
-----------------------------

modifier_artoria_avalon_immunity = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_artoria_avalon_immunity:IsHidden()
	return true
end

function modifier_artoria_avalon_immunity:IsDebuff()
	return false
end

function modifier_artoria_avalon_immunity:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_artoria_avalon_immunity:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_artoria_avalon_immunity:OnRefresh( kv )
	if IsServer() then
	end
end

function modifier_artoria_avalon_immunity:OnDestroy( kv )

end
	
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_artoria_avalon_immunity:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}

	return funcs
end

function modifier_artoria_avalon_immunity:GetAbsoluteNoDamagePhysical()
	return 1
end