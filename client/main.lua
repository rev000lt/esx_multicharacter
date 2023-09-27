local mp_m_freemode_01 = `mp_m_freemode_01`
local mp_f_freemode_01 = `mp_f_freemode_01`

local SpawnCoords = Config.Spawn[math.random(#Config.Spawn)]

if ESX.GetConfig().Multichar then
	CreateThread(function()
		while not ESX.PlayerLoaded do
			Wait(100)

			if NetworkIsPlayerActive(PlayerId()) then
				exports.spawnmanager:setAutoSpawn(false)
				DoScreenFadeOut(0)
				TriggerEvent("esx_multicharacter:SetupCharacters")
				break
			end
		end
	end)

	local canRelog, cam, spawned = true, nil, nil
	local Characters = {}

	RegisterNetEvent('esx_multicharacter:SetupCharacters')
	AddEventHandler('esx_multicharacter:SetupCharacters', function()
		ESX.PlayerLoaded = false
		ESX.PlayerData = {}
		spawned = false
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
		local playerPed = PlayerPedId()
		SetEntityCoords(playerPed, SpawnCoords.x, SpawnCoords.y, SpawnCoords.z, true, false, false, false)
		SetEntityHeading(playerPed, SpawnCoords.w)
		local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0, 1.7, 0.4)
		DoScreenFadeOut(0)
		SetCamActive(cam, true)
		RenderScriptCams(true, false, 1, true, true)
		SetCamCoord(cam, offset.x, offset.y, offset.z)
		PointCamAtCoord(cam, SpawnCoords.x, SpawnCoords.y, SpawnCoords.z + 1.3)
		StartLoop()
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		TriggerEvent('esx:loadingScreenOff')
		Wait(200)
		TriggerServerEvent("esx_multicharacter:SetupCharacters")
	end)

	StartLoop = function()
		hidePlayers = true
		MumbleSetVolumeOverride(PlayerId(), 0.0)
		CreateThread(function()
			local keys = { 18, 27, 172, 173, 174, 175, 176, 177, 187, 188, 191, 201, 108, 109, 209, 19 }
			while hidePlayers do
				DisableAllControlActions(0)
				for i = 1, #keys do
					EnableControlAction(0, keys[i], true)
				end
				SetEntityVisible(PlayerPedId(), 0, 0)
				SetLocalPlayerVisibleLocally(1)
				SetPlayerInvincible(PlayerId(), 1)
				ThefeedHideThisFrame()
				HideHudComponentThisFrame(11)
				HideHudComponentThisFrame(12)
				HideHudComponentThisFrame(21)
				HideHudAndRadarThisFrame()
				Wait(0)
				local vehicles = GetGamePool('CVehicle')
				for i = 1, #vehicles do
					SetEntityLocallyInvisible(vehicles[i])
				end
			end
			local playerId, playerPed = PlayerId(), PlayerPedId()
			MumbleSetVolumeOverride(playerId, -1.0)
			SetEntityVisible(playerPed, 1, 0)
			SetPlayerInvincible(playerId, 0)
			FreezeEntityPosition(playerPed, false)
			Wait(10000)
			canRelog = true
		end)
		CreateThread(function()
			local playerPool = {}
			while hidePlayers do
				local players = GetActivePlayers()
				for i = 1, #players do
					local player = players[i]
					if player ~= PlayerId() and not playerPool[player] then
						playerPool[player] = true
						NetworkConcealPlayer(player, true, true)
					end
				end
				Wait(500)
			end
			for k in pairs(playerPool) do
				NetworkConcealPlayer(k, false, false)
			end
		end)
	end

	SetupCharacter = function(index)
		if not spawned then
			exports.spawnmanager:spawnPlayer({
				x = SpawnCoords.x,
				y = SpawnCoords.y,
				z = SpawnCoords.z,
				heading = SpawnCoords.w,
				model = Characters[index].model or mp_m_freemode_01,
				skipFade = true
			}, function()
				canRelog = false
				if Characters[index] then
					local skin = Characters[index].skin or Config.Default
					if not Characters[index].model then
						if Characters[index].sex == TranslateCap('female') then skin.sex = 1 else skin.sex = 0 end
					end
					TriggerEvent('skinchanger:loadSkin', skin)
				end
				DoScreenFadeIn(600)
			end)
			repeat Wait(200) until not IsScreenFadedOut()
		elseif Characters[index] and Characters[index].skin then
			if Characters[spawned] and Characters[spawned].model then
				RequestModel(Characters[index].model)
				while not HasModelLoaded(Characters[index].model) do
					RequestModel(Characters[index].model)
					Wait(0)
				end
				SetPlayerModel(PlayerId(), Characters[index].model)
				SetModelAsNoLongerNeeded(Characters[index].model)
			end
			TriggerEvent('skinchanger:loadSkin', Characters[index].skin)
		end
		spawned = index
		local playerPed = PlayerPedId()
		FreezeEntityPosition(PlayerPedId(), true)
		SetPedAoBlobRendering(playerPed, true)
		SetEntityAlpha(playerPed, 255)
	end

	function CharacterDeleteConfirmation(Characters, slots, SelectedCharacter)
		local option = {
			{
				title = TranslateCap('char_delete'),
				icon = "xmark",
				description = TranslateCap('char_delete_yes_description'),
				onSelect = function(_)
					local alert = lib.alertDialog({
						header = TranslateCap('char_delete_alert_dialog_title'),
						content = TranslateCap('char_delete_yes_description'),
						centered = true,
						cancel = true
					})

					if alert == 'confirm' then
						TriggerServerEvent('esx_multicharacter:DeleteCharacter', SelectedCharacter)
						spawned = false
					elseif alert == 'cancel' then
						Wait(100)
						SelectCharacterMenu(Characters, slots)
					end
				end,
			},
			{
				title = TranslateCap('return'),
				icon = "arrow-left",
				description = TranslateCap('char_delete_no_description'),
				onSelect = function(_)
					Wait(100)
					SelectCharacterMenu(Characters, slots)
				end,
			}
		}

		lib.registerContext({
			id = 'ox_deletechar',
			title = TranslateCap('char_delete_confirmation'),
			options = option,
			canClose = false
		})
		lib.showContext('ox_deletechar')
	end

	function CharacterOptions(Characters, slots, SelectedCharacter)
		local option = {}

		option[#option + 1] = {
			title = TranslateCap('return'),
			description = TranslateCap('return_description'),
			icon = 'arrow-left',
			onSelect = function(_)
				Wait(100)
				SelectCharacterMenu(Characters, slots)
			end,
		}
		if not Characters[SelectedCharacter].disabled then
			option[#option + 1] = {
				title = TranslateCap('char_play'),
				description = TranslateCap('char_play_description'),
				icon = "play",
				onSelect = function(_)
					SendNUIMessage({
						action = "closeui"
					})
					TriggerServerEvent('esx_multicharacter:CharacterChosen', SelectedCharacter, false)
				end,
			}
		else
			option[#option + 1] = {
				title = TranslateCap('char_disabled'),
				description = TranslateCap('char_disabled_description'),
				icon = "xmark",
				disabled = true,
				onSelect = function(_)
					SendNUIMessage({
						action = "closeui"
					})
					TriggerServerEvent('esx_multicharacter:CharacterChosen', SelectedCharacter, false)
				end,
			}
		end
		if Config.CanDelete then 
			option[#option + 1] = {
				title = TranslateCap('char_delete'),
				icon = "xmark",
				description = TranslateCap('char_delete_description'),
				onSelect = function(_)
					CharacterDeleteConfirmation(Characters, slots, SelectedCharacter, SelectedCharacter)
				end,
			}
		end
		lib.registerContext({
			id = 'ox_options',
			title = TranslateCap('character', Characters[SelectedCharacter].firstname .. " " .. Characters[SelectedCharacter].lastname),
			options = option,
			canClose = false
		})
		lib.showContext('ox_options')
	end

	function SelectCharacterMenu(Characters, slots)
		local Character = next(Characters)
		local option = {}
		for k, v in pairs(Characters) do
			if not v.model and v.skin then
				if v.skin.model then v.model = v.skin.model elseif v.skin.sex == 1 then v.model = mp_f_freemode_01 else v.model = mp_m_freemode_01 end
			end
			if not spawned then SetupCharacter(Character) end
			local label = v.firstname .. ' ' .. v.lastname
			if Characters[k].disabled then
				option[#option + 1] = {
					title = label,
					icon = 'user',
					onSelect = function(_, SelectedCharacter)
						SelectedCharacter = v.id
						CharacterOptions(Characters, slots, SelectedCharacter)
						SetupCharacter(SelectedCharacter)
						local playerPed = PlayerPedId()
						SetPedAoBlobRendering(playerPed, true)
						ResetEntityAlpha(playerPed)
					end,
					
				}
			else
				option[#option + 1] = {
					title = label,
					icon = 'user',
					arrow = true,
					metadata = {
						{label = 'Name', value = v.firstname .. ' ' .. v.lastname},
						{label = 'Job', value = v.job .. ' -> ' ..v.job_grade},
						{label = 'Date of birth', value = v.dateofbirth},
						{label = 'Cash', value = v.money},
						{label = 'Bank', value = v.bank},
						{label = 'Gender', value = v.sex == 'm' and TranslateCap('male') or TranslateCap('female')}
					  },
					onSelect = function(_, SelectedCharacter)
						SelectedCharacter = v.id
						CharacterOptions(Characters, slots, SelectedCharacter)
						SetupCharacter(SelectedCharacter)
						lib.requestAnimDict('friends@frj@ig_1')
						TaskPlayAnim(PlayerPedId(), 'friends@frj@ig_1', 'wave_b', 2.0, 1.0, 6500, 16)
						TaskPlayAnim(closest, 'friends@frj@ig_1', 'wave_b', 2.0, 1.0, 5500, 16)
						local playerPed = PlayerPedId()
						SetPedAoBlobRendering(playerPed, true)
						ResetEntityAlpha(playerPed)
					end,
				}
			end
		end

		if #option < slots then
			option[#option + 1] = {
				title = TranslateCap('create_char'),
				icon = 'plus',
				onSelect = function(_, SelectedCharacter)
					local GetSlot = function()
						for i = 1, slots do
							if not Characters[i] then
								return i
							end
						end
					end
					local slot = GetSlot()
					TriggerServerEvent('esx_multicharacter:CharacterChosen', slot, true)
					TriggerEvent('esx_identity:showRegisterIdentity')
					local playerPed = PlayerPedId()
					SetPedAoBlobRendering(playerPed, false)
					SetEntityAlpha(playerPed, 0)
					SendNUIMessage({
						action = "closeui"
					})
					
				end,
			}
		end

		lib.registerContext({
			id = 'ox_relog',
			title = TranslateCap('select_char'),
			canClose = false,
			options = option
		})
		lib.showContext('ox_relog')
	end

	RegisterNetEvent('esx_multicharacter:SetupUI')
	AddEventHandler('esx_multicharacter:SetupUI', function(data, slots)
		DoScreenFadeOut(0)
		Characters = data
		slots = slots
		local Character = next(Characters)
		exports.spawnmanager:forceRespawn()

		if not Character then
			SendNUIMessage({
				action = "closeui"
			})
			exports.spawnmanager:spawnPlayer({
				x = SpawnCoords.x,
				y = SpawnCoords.y,
				z = SpawnCoords.z,
				heading = SpawnCoords.w,
				model = mp_m_freemode_01,
				skipFade = true
			}, function()
				canRelog = false
				DoScreenFadeIn(400)
				Wait(400)
				local playerPed = PlayerPedId()
				SetPedAoBlobRendering(playerPed, false)
				SetEntityAlpha(playerPed, 0)
				TriggerServerEvent('esx_multicharacter:CharacterChosen', 1, true)
				TriggerEvent('esx_identity:showRegisterIdentity')
			end)
		else
			SelectCharacterMenu(Characters, slots)
		end
	end)

	RegisterNetEvent('esx:playerLoaded')
	AddEventHandler('esx:playerLoaded', function(playerData, isNew, skin)
		local spawn = playerData.coords or Config.Spawn
		if isNew or not skin or #skin == 1 then
			local finished = false
			skin = Config.Default[playerData.sex]
			skin.sex = playerData.sex == "m" and 0 or 1
			local model = skin.sex == 0 and mp_m_freemode_01 or mp_f_freemode_01
			RequestModel(model)
			while not HasModelLoaded(model) do
				RequestModel(model)
				Wait(0)
			end
			SetPlayerModel(PlayerId(), model)
			SetModelAsNoLongerNeeded(model)
			TriggerEvent('skinchanger:loadSkin', skin, function()
				local playerPed = PlayerPedId()
				SetPedAoBlobRendering(playerPed, true)
				ResetEntityAlpha(playerPed)
				TriggerEvent('esx_skin:openSaveableMenu', function()
					finished = true
				end, function()
					finished = true
				end)
			end)
			repeat Wait(200) until finished
		end
		DoScreenFadeOut(100)

		SetCamActive(cam, false)
		RenderScriptCams(false, false, 0, true, true)
		cam = nil
		local playerPed = PlayerPedId()
		FreezeEntityPosition(playerPed, true)
		SetEntityCoordsNoOffset(playerPed, spawn.x, spawn.y, spawn.z, false, false, false, true)
		SetEntityHeading(playerPed, spawn.heading)
		if not isNew then TriggerEvent('skinchanger:loadSkin', skin or Characters[spawned].skin) end
		DoScreenFadeOut(2)
		Citizen.Wait(400)
		if playerData.coords and not isNew then
			Wait(300)
			doCamera(spawn.x, spawn.y, spawn.z)
		end
		repeat Citizen.Wait(200) until not IsScreenFadedOut()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		TriggerEvent('playerSpawned')
		TriggerEvent('esx:restoreLoadout')
		Characters, hidePlayers = {}, false
	end)

	RegisterNetEvent('esx:onPlayerLogout')
	AddEventHandler('esx:onPlayerLogout', function()
		DoScreenFadeOut(500)
		Wait(1000)
		spawned = false
		TriggerEvent("esx_multicharacter:SetupCharacters")
		TriggerEvent('esx_skin:resetFirstSpawn')
	end)

	if Config.Relog then
		RegisterCommand('relog', function()
			if canRelog then
				canRelog = false
				TriggerServerEvent('esx_multicharacter:relog')
				ESX.SetTimeout(10000, function()
					canRelog = true
				end)
			end
		end)
	end
end
camera = nil
function doCamera(x, y, z)
	camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
	i = 3200
	SetFocusArea(x, y, z, 0.0, 0.0, 0.0)
	SetCamActive(camera, true)
	RenderScriptCams(true, false, 0, true, true)
	DoScreenFadeIn(1500)
	local camAngle = -90.0
	local startTime = GetGameTimer()
	local timer = GetGameTimer()
	local running = true
	while running do
		Wait(0)
		local curTime = GetGameTimer()
		if curTime - startTime > 10000 then
			running = false
		end

		DoScreenFadeIn(1000)

		local delta = curTime - timer
		local totalTime = curTime - startTime
		timer = curTime
		i = i - ((2.5 * (i / 3200)) * delta)
		if i < 1 then i = 1 end

		SetCamCoord(camera, x, y, z + i)

		if i < 90.0 then
			camAngle = math.min(i * -1, -5.0)
		end
		SetCamRot(camera, camAngle, 0.0, 0.0)
	end
	SetCamActive(camera, false)
	RenderScriptCams(false, false, 0, true, true)
	DestroyCam(camera, false)
	RenderScriptCams(false)
	DestroyAllCams(true)
	camera = nil
	SetFocusEntity(PlayerPedId())
end
