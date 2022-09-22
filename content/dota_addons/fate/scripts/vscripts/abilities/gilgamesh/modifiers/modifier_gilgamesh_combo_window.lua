modifier_gilgamesh_combo_window = class({})

if IsServer() then 
	function modifier_gilgamesh_combo_window:OnCreated(args)
		local caster = self:GetParent()
		print("buff created")
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", true, false)
	end

	function modifier_gilgamesh_combo_window:OnDestroy()
		local caster = self:GetParent()
		print("buff removed")
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", false, true)
	end
end


function modifier_gilgamesh_combo_window:IsHidden()
	return true
end

function modifier_gilgamesh_combo_window:RemoveOnDeath()
	return true 
end