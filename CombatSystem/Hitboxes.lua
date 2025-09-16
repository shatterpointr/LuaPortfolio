local hitboxmodule = {}

local Debris = game:GetService('Debris')

hitboxmodule.CreateStatic = function(Character, CF, Size, Time, Bound)
	local box = Instance.new("Part")
	box.CFrame = CF
	box.Size = Size
	box.Parent = game.Workspace:WaitForChild("Hitboxes")
	box.Anchored = false
	box.Massless = true
	box.CanCollide = false
	box.Transparency = 0.5
	
	Debris:AddItem(box, Time)
	
	if Bound then
		local WC = Instance.new("WeldConstraint")
		WC.Parent = box
		WC.Part1 = Character.HumanoidRootPart
		WC.Part0 = box
	end
	
	local parts = workspace:GetPartsInPart(box)
	local characters = {}
	for i,v in pairs(parts) do
		local Humanoid = v.Parent:FindFirstChild('Humanoid') or v.Parent.Parent:FindFirstChild('Humanoid')
		if Humanoid then
			if not table.find(characters, Humanoid.Parent) and Humanoid.Parent ~= Character then
				table.insert(characters, Humanoid.Parent)
			end
		end
	end
	return characters
end


return hitboxmodule
