local punch = {}
local Hitboxes = require(script.Parent.Parent.Hitboxes)
local Effects = require(script.Parent.Parent.Effects.EffectsModule)

punch.Data = {
	HitboxSize = 4,
	Damage = 15,
	Hitstun = 0.5
}

punch.Execute = function(Character, Count, CF)
	local CharacterData = Character:WaitForChild("CharacterData")
	
	local Data = punch.Data
	
	local PunchObj = Instance.new("IntValue", Character.CharacterData)
	PunchObj.Name = 'Punching'
	local String = 'Punch'..tostring(Count)
	
	local PunchTrack = Character.Humanoid:LoadAnimation(script:FindFirstChild(String))
	PunchTrack.Priority = Enum.AnimationPriority.Action2
	PunchTrack:Play()
	PunchTrack:AdjustSpeed(1.3)
	
	local Size = Vector3.new(Data.HitboxSize,Data.HitboxSize,Data.HitboxSize)
	local Time = 0.20
	
	task.wait(0.2)
	
	local Hitstun = CharacterData:FindFirstChild("Stunned")
	if Hitstun then 
		for i,v in pairs(Character.CharacterData:GetChildren()) do
			if v.Name == 'Punching' then
				v:Destroy()
			end
		end
		return 
	end
	
	local HitCharacters = Hitboxes.CreateStatic(Character, CF, Size, Time, true)
	for i,v in pairs(HitCharacters) do
		local Guarding = v.CharacterData:FindFirstChild('Guarding')
		if not Guarding then
			Effects.Punched(v, Data.Damage, Data.Hitstun)
			if Count == 4 then
				local Dir = (v.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Unit
				local DirF = Dir * 60
				local KBD = Vector3.new(DirF.X, 40, DirF.Z)
				Effects.Knockback(v, KBD)
			end
		else
			if Count == 4 then
				Effects.GuardBreak(v, Data.Damage)
			else
				Effects.Blocked(v, Data.Damage)
			end
		end
		
	end
	
	while PunchTrack.IsPlaying do
		Character.Humanoid.WalkSpeed = 10
		wait()
	end
	
	PunchTrack.Ended:Connect(function()
		Character.Humanoid.WalkSpeed = 16
		for i,v in pairs(Character.CharacterData:GetChildren()) do
			if v.Name == 'Punching' then
				v:Destroy()
			end
		end
	end)
end

return punch
