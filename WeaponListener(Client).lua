-- Servicios
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local debris = game:GetService("Debris")
-- Variables
local bate = script.Parent
local cooldown = false
local combo = 1
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator") :: Animator
local propiedades = require(script.Parent.Properties)
local lastCooldown = false
local Swing = script.Parent.Swing
local specialMove = script.Parent.specialMove
local lastAttack = 0
local resetCombo = 1.5
local AnimIdle = Instance.new("Animation")
AnimIdle.AnimationId = propiedades.EquipAnimation

local bateIdle = animator:LoadAnimation(AnimIdle)

-- Funciones

local function animationTracker(Id)
	local animation = Instance.new("Animation")
	animation.AnimationId = Id
	return animation
end

-- SWINGS
local swing1 = animator:LoadAnimation(animationTracker(propiedades.SwingAnimation1))
local swing2 = animator:LoadAnimation(animationTracker(propiedades.SwingAnimation2))
local swing3 = animator:LoadAnimation(animationTracker(propiedades.SwingAnimation3))
-- HITS
swing1:GetMarkerReachedSignal("hit"):Connect(function()
	Swing:FireServer(1)
end)
swing2:GetMarkerReachedSignal("hit2"):Connect(function()
	Swing:FireServer(2)
end)
swing3:GetMarkerReachedSignal("hit3"):Connect(function()
	Swing:FireServer(3)
end)

-- Manejadores

bate.Equipped:Connect(function()
	-- equipar animación idle
	bateIdle:Play()
end)

bate.Unequipped:Connect(function()
	-- desequipar animación idle
	bateIdle:Stop()
end)

bate.Activated:Connect(function()
	-- Verificación de cooldowns
	if cooldown or lastCooldown then return end

	local currentTime = tick()

	-- Manejo de cooldown básico
	cooldown = true
	task.delay(propiedades.SwingCooldown, function()
		cooldown = false
	end)

	-- Reset de combo si ha pasado mucho tiempo
	if currentTime - lastAttack > resetCombo then
		combo = 1
	end

	-- Ejecución del combo
	if combo == 1 then
		swing1:Play()
		combo = 2
	elseif combo == 2 then
		swing2:Play()
		combo = 3
	elseif combo == 3 then
		swing3:Play()

		-- Cooldown especial después del tercer golpe
		lastCooldown = true
		task.delay(1.5, function()
			lastCooldown = false
		end)

		combo = 1
	end

	-- Actualizar el último tiempo de ataque
	lastAttack = currentTime
end)

bate.showVFX.OnClientEvent:Connect(function(humanoidRootPart)
	if humanoidRootPart then
		local hitVfx = replicatedStorage.VFX.Hit
		local cloneVfx = hitVfx:Clone()

		cloneVfx.Parent = humanoidRootPart
		cloneVfx.Position = humanoidRootPart.Position
		for _, v in pairs(cloneVfx:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount") or 15)
			end
		end
		debris:AddItem(cloneVfx, 0.1)
	end
end)

bate.CriticalVfx.OnClientEvent:Connect(function(humanoidRootPart)
	if humanoidRootPart then
		local hitVfx = replicatedStorage.VFX["Critical hit"]
		local cloneVfx = hitVfx:Clone()

		cloneVfx.Parent = humanoidRootPart
		cloneVfx.Position = humanoidRootPart.Position
		for _, v in pairs(cloneVfx:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount") or 15)
			end
		end
		debris:AddItem(cloneVfx, 0.1)
	end
end)

specialMove.OnClientEvent:Connect(function(humanoidRootPart)
	local impactoVFX = replicatedStorage.VFX.Slash:Clone()
	impactoVFX.Parent = humanoidRootPart

	impactoVFX.Position = humanoidRootPart.Position
	
	impactoVFX.Anchored = true
		-- Activación forzada de partículas
		for _, emitter in impactoVFX:GetDescendants() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = true
				task.wait() -- Pequeña pausa entre emisores
				emitter:Emit(emitter:GetAttribute("EmitCount") or 30)
			end
		end
	
	game.Debris:AddItem(impactoVFX,1)
end)