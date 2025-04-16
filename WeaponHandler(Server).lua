-- Servicios
local players = game:GetService("Players")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")
-- Variables
local bat = script.Parent
local propiedades = require(script.Parent.Properties)
local statDebounce = false
-- Tabla para rastrear personajes golpeados
local hitCharacters = {}
local specialMove = script.Parent.specialMove


-- Funciones
local function soundCreator(Id)
	local sonido = Instance.new("Sound")
	sonido.SoundId = Id
	sonido.Parent = bat.Handle
	return sonido
end

local function showHitVfx(humanoidRootPart)
		bat.showVFX:FireAllClients(humanoidRootPart)
	end

local function criticalHitVfx(humanoidRootPart)
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
		bat.CriticalVfx:FireAllClients(humanoidRootPart)
	end
end

local function startCombo(hit, comboNum, character,hitSound,criticalSound,player)
	local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
	local humanoidRootPart = hit.Parent:FindFirstChild("HumanoidRootPart")	
	local rng = math.random()
	
	if humanoid and humanoidRootPart then
		if comboNum == 1 then
			
			if rng <= propiedades.CriticalHitChance then
				humanoid:TakeDamage(propiedades.Damage * propiedades.CriticalHitMultiplier)
				criticalSound:Play()
				criticalHitVfx(humanoidRootPart)
				humanoid:SetAttribute("LastAttacker", player.UserId)
			else
				humanoid:TakeDamage(propiedades.Damage)
				showHitVfx(humanoidRootPart)
				hitSound:Play()
				humanoid:SetAttribute("LastAttacker", player.UserId)
			end
			
		
		elseif comboNum == 2 then
			if rng <= propiedades.CriticalHitChance then
				humanoid:TakeDamage(propiedades.Damage * propiedades.CriticalHitMultiplier)
				criticalSound:Play()
				criticalHitVfx(humanoidRootPart)
				humanoid:SetAttribute("LastAttacker", player.UserId)
			else
				humanoid:TakeDamage(propiedades.Damage)
				showHitVfx(humanoidRootPart)
				hitSound:Play()
				humanoid:SetAttribute("LastAttacker", player.UserId)
			end	
			
		elseif comboNum == 3 then
			if rng <= propiedades.CriticalHitChance then
				humanoid:TakeDamage(propiedades.Damage * propiedades.CriticalHitMultiplier)
				criticalSound:Play()
				criticalHitVfx(humanoidRootPart)
				humanoid:SetAttribute("LastAttacker", player.UserId)
			else
				humanoid:TakeDamage(propiedades.Damage + 10)
				showHitVfx(humanoidRootPart)
				hitSound:Play()
				humanoid:SetAttribute("LastAttacker", player.UserId)
			end	
			
			
			-- Empuje
			local playerRootPart = character:FindFirstChild("HumanoidRootPart")
			
			if not playerRootPart then return end
			
			local direccionEmpuje = (humanoidRootPart.Position - playerRootPart.Position).Unit  -- Dirección del jugador al objetivo
			direccionEmpuje = direccionEmpuje * 50  -- Ajustar la magnitud de la fuerza

			-- Crear BodyVelocity para aplicar la fuerza
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = direccionEmpuje
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Parent = humanoidRootPart

			-- Eliminar BodyVelocity después de un tiempo
			debris:AddItem(bodyVelocity, 0.2)  -- Eliminar después de 0.2 segundos
		end
	end
end

local function getPlayerFromCharacter(character)
	return players:GetPlayerFromCharacter(character)
end

local function onDeath(humanoid)
	if humanoid:GetAttribute("Killed") then return end  -- Evita doble conteo
	humanoid:SetAttribute("Killed", true)  -- Marca al NPC como "muerto"

	local killerId = humanoid:GetAttribute("LastAttacker")  -- Obtener el UserId
	if killerId then
		local killer = players:GetPlayerByUserId(killerId)  -- Convertir UserId en Player
		if killer then
			local leaderstats = killer:FindFirstChild("leaderstats")
			if leaderstats then
				local kills = leaderstats:FindFirstChild("Kills")
				if kills then
					kills.Value = kills.Value + 1  -- Suma solo 1 vez
				end
			end
		end
	end
end

local swingSound = soundCreator(propiedades.SwingSoundID)
-- Manejadores
bat.Swing.OnServerEvent:Connect(function(player, combo)
	local character = player.Character
	local playerHumanoid = character:WaitForChild("Humanoid")
	if not character then return end

	playerHumanoid.WalkSpeed = 7
	
	task.delay(0.5,function()		
		playerHumanoid.WalkSpeed = 16		
	end)
		
	swingSound:Play()
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Crear la hitbox
	if combo == 1 or combo == 2 then
	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(8, 8, 7)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Anchored = true
	hitbox.Color = Color3.new(1, 0, 0)
	hitbox.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, ((hitbox.Size.Z / 2) + 0.5) * -1)
	hitbox.Parent = workspace

	debris:AddItem(hitbox, 0.1)  -- Eliminar la hitbox después de 0.1 segundos

	-- Detectar partes dentro de la hitbox
	local partesDentroDeHitbox = workspace:GetPartsInPart(hitbox)

	for _, parte in pairs(partesDentroDeHitbox) do
		local hitCharacter = parte.Parent
		local humanoid = hitCharacter:FindFirstChildWhichIsA("Humanoid")
		local hitPlayer = getPlayerFromCharacter(hitCharacter)

		-- Verificar si el personaje es válido y no ha sido golpeado ya
		if humanoid and humanoid.Parent ~= character and not hitCharacters[hitCharacter] then
			if hitPlayer == nil then
				local hitSound = soundCreator(propiedades.HitSoundID)
				local criticalSound = soundCreator(propiedades.CriticalSound)
				startCombo(parte, combo,character,hitSound, criticalSound,player)  -- Aplicar el daño
				hitCharacters[hitCharacter] = true -- Marcar el personaje como golpeado
				humanoid.Died:Connect(function()
					onDeath(humanoid)
				end)
			end
		end
	end
	end
	if combo == 3 then
		local hitbox = Instance.new("Part")
		hitbox.Size = Vector3.new(12.5, 7, 12.5)
		hitbox.Transparency = 1
		hitbox.CanCollide = false
		hitbox.Massless = true
		hitbox.Anchored = true
		hitbox.CFrame = humanoidRootPart.CFrame
		hitbox.Parent = workspace
		debris:AddItem(hitbox, 0.1)

		-- SOLUCIÓN CLAVE: Esperar un frame antes de emitir
		specialMove:FireAllClients(humanoidRootPart)
		-- Resto del código de detección...
		debris:AddItem(hitbox, 0.1)

		-- Detectar partes dentro de la hitbox
		local partesDentroDeHitbox = workspace:GetPartsInPart(hitbox)

		for _, parte in pairs(partesDentroDeHitbox) do
			local hitCharacter = parte.Parent
			local humanoid = hitCharacter:FindFirstChildWhichIsA("Humanoid")
			local hitPlayer = getPlayerFromCharacter(hitCharacter)

			-- Verificar si el personaje es válido y no ha sido golpeado ya
			if humanoid and humanoid.Parent ~= character and not hitCharacters[hitCharacter] then
				if hitPlayer == nil then
					local hitSound = soundCreator(propiedades.HitSoundID)
					local criticalSound = soundCreator(propiedades.CriticalSound)
					startCombo(parte, combo,character,hitSound, criticalSound,player)  -- Aplicar el daño
					hitCharacters[hitCharacter] = true -- Marcar el personaje como golpeado
					humanoid.Died:Connect(function()
						onDeath(humanoid)
					end)
				end
			end
		end
	end
	-- Limpiar la tabla después de 0.5 segundos
	task.delay(0.5, function()
		hitCharacters = {}
	end)
end)

