local effects = {}
local Debris = game:GetService("Debris")
local Animations = script.Animations
local FX = script.FX

-- note from current aidan: if I had to redo this, I would definitely just use custom attributes on the characters instead of these values.
effects.Punched = function(Character, Dmg, Hitstun)
	local Data = Character:FindFirstChild("CharacterData")
	if not Data then return end
	
	local Humanoid = Character:FindFirstChild('Humanoid')
	Humanoid.WalkSpeed = 4
	Humanoid:TakeDamage(Dmg)
	
	local Stunned = Instance.new("IntValue", Character.CharacterData)
	Stunned.Name = 'Stunned'
	Debris:AddItem(Stunned, Hitstun)
	
	local PunchFX = FX.Punch:Clone()
	PunchFX.Parent = Character.HumanoidRootPart
	for i,v in pairs(PunchFX:GetChildren()) do
		v.Parent = Character.HumanoidRootPart	
		Debris:AddItem(v, 1)
	end
	for i,v in pairs(Character.HumanoidRootPart:GetDescendants()) do
		if v.ClassName == 'ParticleEmitter' then
			v:Emit(tonumber(v.Name))
		end
	end
	Debris:AddItem(PunchFX,1)
	
	local HitTrack = Humanoid:LoadAnimation(Animations.Punched)
	HitTrack.Priority = Enum.AnimationPriority.Action
	HitTrack:Play()
	
	HitTrack.Ended:Connect(function()
		if not Data:FindFirstChild('Stunned') then
			Humanoid.WalkSpeed = 16
		end
	end)
end

effects.Knockback = function(Character, Direction)
	local HumanoidRootPart = Character:FindFirstChild('HumanoidRootPart')
	if not HumanoidRootPart then return end
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = HumanoidRootPart
	Debris:AddItem(attachment, 0.1)
	
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.VectorVelocity = Direction
	linearVelocity.MaxForce = 999999 
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = HumanoidRootPart
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	
	Debris:AddItem(linearVelocity, 0.1)
end

effects.Blocked = function(Character, Dmg)
	local Humanoid = Character:FindFirstChild('Humanoid')
	Humanoid:TakeDamage(Dmg * 0.10)
	
	local BlockFX = FX.Blocked.Attachment:Clone()
	BlockFX.Parent = Character.HumanoidRootPart
	BlockFX['1']:Emit(1)
	
	Debris:AddItem(BlockFX,0.5)
end

effects.GuardBreak = function(Character, Dmg)
	local Data = Character:FindFirstChild("CharacterData")
	local Humanoid = Character:FindFirstChild('Humanoid')
	Humanoid:TakeDamage(Dmg)
	Humanoid.WalkSpeed = 2
	
	local BreakFX = FX.Break:Clone()
	Debris:AddItem(BreakFX,1)
	for i,v in pairs(BreakFX:GetDescendants()) do
		v.Parent = Character.HumanoidRootPart
	end
	for i,v in pairs(Character.HumanoidRootPart:GetDescendants()) do
		if v.ClassName == 'ParticleEmitter' then
			v:Emit(tonumber(v.Name))
			Debris:AddItem(v, 0.5)
		end
	end
	
	local Guarding = Data:FindFirstChild('Guarding')
	if Guarding then
		Guarding:Destroy()
	end
	
	local Stunned = Instance.new("IntValue", Data)
	Stunned.Name = 'Stunned'
	Stunned.Destroying:Connect(function()
		Humanoid.WalkSpeed = 16
	end)
	Debris:AddItem(Stunned, 2.5)
	
	local HitTrack = Humanoid:LoadAnimation(Animations.Punched)
	HitTrack.Priority = Enum.AnimationPriority.Action
	HitTrack:Play()
end

return effects
