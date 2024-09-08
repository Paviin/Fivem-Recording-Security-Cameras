
local recordedData = {}
local entitiesInZone = {}
local playbackRecording = false


local function calculateZoneCorners(camCoords, camHorizontalHeading, fov, length)
    local radHorizontalHeading = math.rad(camHorizontalHeading + 90)
    local halfFov = fov / 2.0
    return {
        frontLeft = camCoords + vector3(
            math.cos(radHorizontalHeading - math.rad(halfFov)) * length,
            math.sin(radHorizontalHeading - math.rad(halfFov)) * length,
            0.0
        ),
        frontRight = camCoords + vector3(
            math.cos(radHorizontalHeading + math.rad(halfFov)) * length,
            math.sin(radHorizontalHeading + math.rad(halfFov)) * length,
            0.0
        ),
        backLeft = camCoords + vector3(
            math.cos(radHorizontalHeading - 1),
            math.sin(radHorizontalHeading),
            0.0
        ),
        backRight = camCoords + vector3(
            math.cos(radHorizontalHeading - 1),
            math.sin(radHorizontalHeading),
            0.0
        )
    }
end

local function createCamZone(id, title, description, camCoords, camHeading, minFov, maxFov, length, minCamHeightFov, maxCamHeightFov, obj)
    local corners = calculateZoneCorners(camCoords, camHeading, maxFov, length)
    local polyZone = PolyZone:Create({
        vector2(corners.backLeft.x, corners.backLeft.y),
        vector2(corners.frontLeft.x, corners.frontLeft.y),
        vector2(corners.frontRight.x, corners.frontRight.y),
        vector2(corners.backRight.x, corners.backRight.y)
    }, {
        name = "camera_zone_" .. id,
        minZ = camCoords.z - minCamHeightFov,
        maxZ = camCoords.z + maxCamHeightFov,
        debugPoly = Config.Debug
    })

    return {
        id = id,
        title = title,
        description = description,
        obj = obj,
        minFov = minFov,
        maxFov = maxFov,
        coords = vector3(corners.backLeft.x, corners.backLeft.y, camCoords.z),
        zone = polyZone,
        heading = camHeading,
    }
end

local camZones = {}

Citizen.CreateThread(function()
    for k,v in pairs(Config.Cams) do
        local camZone = createCamZone(
            v.id, v.title, v.description, v.camCoords, 
            v.camHeading, v.minFov, v.maxFov, v.length, 
            v.minCamHeightFov, v.maxCamHeightFov, v.obj
        )
        table.insert(camZones, camZone)
    end
end)

local function isEntityVisibleToCamera(camCoords, entity)
    local entityCoords = GetEntityCoords(entity)
    local success, screenX, screenY = GetScreenCoordFromWorldCoord(entityCoords.x, entityCoords.y, entityCoords.z)
    if not success then
        return false
    end

    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, entityCoords.x, entityCoords.y, entityCoords.z, 17, PlayerPedId(), 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    return hit and (entityHit == entity or entityHit == 0)
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x, 
        (math.pi / 180) * rotation.y, 
        (math.pi / 180) * rotation.z
    )

    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        math.sin(adjustedRotation.x)
    )

    return direction
end

function GetPointInDirection(camCoords, direction, distance)
    return vector3(
        camCoords.x + direction.x * distance,
        camCoords.y + direction.y * distance,
        camCoords.z + direction.z * distance
    )
end

function GetAimCoords(ped)
    local weaponBone = 0xDEAD

    local weaponPos = GetPedBoneCoords(ped, 0xDEAD, 0.0, 0.0, 0.0)

    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    local direction = RotationToDirection(camRot)
    local targetCoords = GetPointInDirection(camCoords, direction, 1000)

    local rayHandle = StartShapeTestRay(weaponPos.x, weaponPos.y, weaponPos.z, targetCoords.x, targetCoords.y, targetCoords.z, 17, playerPed, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)

    return {weaponPos = weaponPos, hitCoords = hitCoords}
end

local function collectPedData(ped, camId)
    local pedCoords = GetEntityCoords(ped)
    local weapon = GetSelectedPedWeapon(ped)
    local playerServerId = -1

    -- Um das Outfit des Spielers zu bekommen
    if IsPedAPlayer(ped) and camId then
        TriggerEvent('skinchanger:getSkin', function(outfit)
            TriggerServerEvent('GetPlayerOutfit', camId, outfit)
        end)

        playerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    end

    local isPlayer = IsPedAPlayer(ped)
    local isAiming = false

    if isPlayer then
        isAiming = IsPlayerFreeAiming(PlayerId()) or IsPedShooting(ped)
    else
        isAiming = IsPedAimingFromCover(ped) or IsPedShooting(ped)
    end

    return {
        type = 'ped',
        pedId = PedToNet(ped),
        coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z },
        heading = GetEntityHeading(ped),
        weapon = weapon,
        isInVehicle = IsPedInAnyVehicle(ped, false),
        currentAnimation = GetEntityAnimCurrentTime(ped),
        isAiming = isAiming,
        pedWeapon = GetSelectedPedWeapon(ped),
        aimCoords = GetAimCoords(ped),
        isRunning = IsPedRunning(ped),
        isWalking = IsPedWalking(ped),
        isInCover = IsPedInCover(ped, false),
        isInMeleeCombat = IsPedInMeleeCombat(ped),
        isDucking = IsPedDucking(ped),
        isReloading = IsPedReloading(ped),
        isRagdoll = IsPedRagdoll(ped),
        playerServerId = playerServerId
    }
end


local function collectVehicleData(vehicle, camId)
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)

    local numberOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local pedsInVehicle = {}
    local driverSeat = -1
    local lastSeat = driverSeat + numberOfSeats - 1

    for seat=driverSeat, lastSeat, 1 do
        local pedInVehicleSeat = GetPedInVehicleSeat(vehicle, seat)
        local serverId = -1

        if IsPedAPlayer(pedInVehicleSeat) then
            serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(pedInVehicleSeat))
            TriggerEvent('skinchanger:getSkin', function(outfit)
                TriggerServerEvent('GetPlayerOutfit', camId, outfit)
            end)
    
            playerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(pedInVehicleSeat))
        end

        table.insert(pedsInVehicle, {
            ped  = pedInVehicleSeat,
            seat = seat,
            serverId = serverId
        })
    end

    return {
        type = 'vehicle',
        coords = { x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z },
        heading = GetEntityHeading(vehicle),
        model = GetEntityModel(vehicle),
        colorPrimary = colorPrimary,
        colorSecondary = colorSecondary,
        plate = GetVehicleNumberPlateText(vehicle),
        isEngineRunning = GetIsVehicleEngineRunning(vehicle),
        pedsInVehicle = pedsInVehicle,
        speed = vehicleSpeed,
        doorsOpen = {
            frontLeft = IsVehicleDoorDamaged(vehicle, 0),
            frontRight = IsVehicleDoorDamaged(vehicle, 1),
            backLeft = IsVehicleDoorDamaged(vehicle, 2),
            backRight = IsVehicleDoorDamaged(vehicle, 3),
            hood = IsVehicleDoorDamaged(vehicle, 4),
            trunk = IsVehicleDoorDamaged(vehicle, 5)
        },
        occupants = GetVehicleNumberOfPassengers(vehicle),
    }
end

local function collectDataInZone()
    local peds = GetGamePool('CPed')
    local vehicles = GetGamePool('CVehicle')

    for k, cam in pairs(camZones) do
        for entity, _ in pairs(entitiesInZone) do
            if DoesEntityExist(entity) and not cam.zone:isPointInside(GetEntityCoords(entity)) then
                if IsEntityAPed(entity) then
                    table.insert(recordedData, collectPedData(entity))
                elseif IsEntityAVehicle(entity) then
                    table.insert(recordedData, collectVehicleData(entity))
                end
                entitiesInZone[entity] = nil
            end
        end

        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) and cam.zone:isPointInside(GetEntityCoords(ped)) and isEntityVisibleToCamera(cam.coords, ped) and GetVehiclePedIsIn(ped, false) == 0 then
                entitiesInZone[ped] = true

                table.insert(recordedData, collectPedData(ped, cam.id))
            end
        end

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) and cam.zone:isPointInside(GetEntityCoords(vehicle)) and isEntityVisibleToCamera(cam.coords, vehicle) then
                entitiesInZone[vehicle] = true

                table.insert(recordedData, collectVehicleData(vehicle, cam.id))
            end
        end
    end
end

local isPlayerInZone = false
local spawnedPeds = {}
local spawnedVehicles = {}

Citizen.CreateThread(function()
    for k, cam in pairs(camZones) do
        cam.zone:onPlayerInOut(function(isPointInside, point, entity)
            if isPointInside then
                recordedData = {}

                if cam.recordingThread and cam.recordingThreadActive then
                    cam.recordingThreadActive = false
                end

                cam.recordingThreadActive = true
                cam.recordingThread = Citizen.CreateThread(function()
                    while cam.recordingThreadActive do

                        --[[if not isEntityVisibleToCamera(cam.coords, PlayerPedId()) then
                            print("Entität nicht sichtbar, Aufnahme wird gestoppt und gespeichert")
                            cam.recordingThreadActive = false
                            break
                        end]]

                        if #recordedData >= 500 then
                            TriggerServerEvent('videoRecordingCameras:createCacheFile', json.encode(recordedData), cam.id, cam.zone.center, cam.coords, cam.heading, cam.title, cam.description, cam.minFov, cam.maxFov)
                            recordedData = {}
                        else
                            collectDataInZone()
                        end
                        Citizen.Wait(500)
                    end
                    
                    if not cam.recordingThreadActive and #recordedData > 5 then
                        TriggerServerEvent('videoRecordingCameras:createCacheFile', json.encode(recordedData), cam.id, cam.zone.center, cam.coords, cam.heading, cam.title, cam.description, cam.minFov, cam.maxFov)
                        recordedData = {}
                    end
                end)
            else
                if cam.recordingThreadActive then
                    cam.recordingThreadActive = false
                end
                if #recordedData > 1 then
                    TriggerServerEvent('videoRecordingCameras:createCacheFile', json.encode(recordedData), cam.id, cam.zone.center, cam.coords, cam.heading, cam.title, cam.description, cam.minFov, cam.maxFov)
                end
                recordedData = {}
            end
        end)
    end
end)

local function requestModels(models)
    for _, model in ipairs(models) do
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
    end
end

RegisterCommand('aufnahme', function()
    watchVideo(recordedData)
end)

local function createPed(data, infoFile, fileName)
    local model = GetHashKey("mp_m_freemode_01")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    local ped = CreatePed(4, GetHashKey("mp_m_freemode_01"), data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)

    for k,v in pairs(infoFile.skins) do
        if v[fileName] then
            for k_,v_ in pairs(v[fileName]) do 
                if data.playerServerId == v_.id then
                    ApplySkin(ped, v_.skin)
                end
            end
        end
    end
    spawnedPeds[data.pedId] = ped
    return ped
end

local function createVehicle(data, infoFile, fileName)
    RequestModel(data.model)
    while not HasModelLoaded(data.model) do
        Citizen.Wait(50)
    end
    local vehicle = CreateVehicle(data.model, data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
    local zCoord = GetGroundZFor_3dCoord(data.coords.x, data.coords.y, data.coords.z, true)
    if math.abs( zCoord - data.coords.z ) < 1.5 then
        SetVehicleOnGroundProperly(vehicle)
    end
    SetVehicleColours(vehicle, data.colorPrimary, data.colorSecondary)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleEngineOn(vehicle, data.isEngineRunning, true, false)
    SetVehicleCurrentRpm(vehicle, data.rpm)
    SetVehicleFuelLevel(vehicle, data.fuelLevel)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleLights(vehicle, 2)
    SetEntityInvincible(vehicle, true)

    for k, v in pairs(data.pedsInVehicle) do
        if v.serverId ~= -1 then
            for k_, v_ in pairs(infoFile.skins) do
                if v_[fileName] then
                    for k__, v__ in pairs(v_[fileName]) do
                        if v.serverId == v__.id then

                            local model = GetHashKey("mp_m_freemode_01")
                            if v__.skin.sex == 1 then
                                model = GetHashKey("mp_f_freemode_01")
                            end

                            RequestModel(model)
                            while not HasModelLoaded(model) do
                                Wait(100)
                            end
                    
                            local ped = CreatePedInsideVehicle(vehicle, 4, model, v.seat, false, false)
                    
                            KeepPedInVehicle(ped, vehicle)
                    
                            SetDriverAbility(ped, 1.0)  
                            SetDriverAggressiveness(ped, 0.0)  
                            ApplySkin(ped, v__.skin)

                        end
                    end
                end
            end
        end
    end

    spawnedVehicles[data.plate] = vehicle
    return vehicle
end

-- Funktion, um sicherzustellen, dass das Ped im Fahrzeug bleibt
function KeepPedInVehicle(ped, vehicle)
    -- Setze Ped-Attribute, um zu verhindern, dass es aussteigt
    SetPedKeepTask(ped, true)
    SetPedFleeAttributes(ped, 0, false)  -- Keine Flucht
    SetPedCombatAttributes(ped, 46, true)  -- Unempfindlich gegen Schock
    SetPedCanBeDraggedOut(ped, false)  -- Ped kann nicht herausgezogen werden
    SetPedStayInVehicleWhenJacked(ped, true)  -- Ped bleibt im Fahrzeug
    TaskSetBlockingOfNonTemporaryEvents(ped, true)  -- Blockiere unnötige Events
    
    -- Sicherstellen, dass das Ped keine Angst hat, das Fahrzeug zu fahren
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Sicherstellen, dass es aktiv fährt
    TaskVehicleDriveWander(ped, vehicle, 20.0, 786603)  -- Sicherer Fahralgorithmus
    
    -- Immer wieder prüfen, ob das Ped noch im Fahrzeug ist
    Citizen.CreateThread(function()
        while true do
            -- Wenn das Ped versucht, auszusteigen
            if not IsPedInVehicle(ped, vehicle, false) then
                -- Erzwinge das Einsteigen
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
            end
            -- Warte ein wenig, bevor erneut geprüft wird
            Citizen.Wait(1000)
        end
    end)
end

local function handlePedPlayback(ped, data)
    RequestAnimDict("move_m@brave")
    while not HasAnimDictLoaded("move_m@brave") do
        Citizen.Wait(0)
    end
    
    TaskPlayAnim(ped, "move_m@brave", "walk", 8.0, -8.0, -1, 1, 0, false, false, false)
    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
    FreezeEntityPosition(ped, true)
    SetEntityHeading(ped, data.heading)

    if data.isAiming then
        GiveWeaponToPed(ped, data.pedWeapon, 100, false, true)
        TaskAimGunAtCoord(ped, data.aimCoords.hitCoords.x, data.aimCoords.hitCoords.y, data.aimCoords.hitCoords.z, -1)
    end
end

local function handleVehiclePlayback(vehicle, data)
    local numberOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local pedsInVehicle = {}
    local driverSeat = -1
    local lastSeat = driverSeat + numberOfSeats - 1

    for seat = driverSeat, lastSeat, 1 do
        local pedInVehicleSeat = GetPedInVehicleSeat(vehicle, seat)
        table.insert(pedsInVehicle, {
            ped  = pedInVehicleSeat,
            seat = seat
        })
    end

    SetEntityCoords(vehicle, data.coords.x, data.coords.y, data.coords.z)
    FreezeEntityPosition(vehicle, true)
    SetEntityHeading(vehicle, data.heading)
    SetVehicleOnGroundProperly(vehicle)

end

local deletedVehicles = {}

RegisterNetEvent('clientDeleteVehicle')
AddEventHandler('clientDeleteVehicle', function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetEntityAlpha(vehicle, 0)
        SetEntityVisible(vehicle, false, false)
        
        for _, spawnedVehicle in pairs(spawnedVehicles) do
            SetEntityNoCollisionEntity(vehicle, spawnedVehicle, true)
        end

        table.insert(deletedVehicles, vehicle)
    end
end)

local function removeNonRecordedEntities()
    Citizen.CreateThread(function()
        while playbackRecording do
            local allVehicles = GetGamePool('CVehicle')
            local allPeds = GetGamePool('CPed')

            for _, cam in pairs(camZones) do
                for _, vehicle in ipairs(allVehicles) do
                    local vehicleShouldBeVisible = false

                    for _, spawnedVehicle in pairs(spawnedVehicles) do
                        if vehicle == spawnedVehicle then
                            vehicleShouldBeVisible = true
                            break
                        end
                    end

                    if not vehicleShouldBeVisible and DoesEntityExist(vehicle) and cam.zone:isPointInside(GetEntityCoords(vehicle)) then
                        local vehicleNetId = VehToNet(vehicle)
                        TriggerServerEvent('deleteVehicleForPlayer', vehicleNetId)
                    end
                end

                --[[ 
                for _, ped in ipairs(allPeds) do
                    local pedShouldBeVisible = false

                    for _, spawnedPed in pairs(spawnedPeds) do
                        if ped == spawnedPed then
                            pedShouldBeVisible = true
                            break
                        end
                    end

                    if not pedShouldBeVisible and DoesEntityExist(ped) and cam.zone:isPointInside(GetEntityCoords(ped)) then
                        SetEntityVisible(ped, false, false)
                        SetEntityNoCollisionEntity(ped, PlayerPedId(), false) 
                    end
                end]]
                
            end

            Citizen.Wait(1000)
        end
    end)
end

function watchVideo(file, infoFile, fileName)
    playbackRecording = true
    SetNuiFocus(false, false)

    removeNonRecordedEntities()
    if #file == 0 then
        print("No recorded data available.")
        return
    end

    local ped = PlayerPedId()
    local oldCoords = GetEntityCoords(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, infoFile.coords.x, infoFile.coords.y, infoFile.coords.z, 0.0, 0.0, 0.0, false)
    SetEntityAlpha(ped, 0.0, -1)

    local modelsToRequest = { "a_m_y_stbla_01", "a_m_y_beach_02" }
    requestModels(modelsToRequest)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetTimecycleModifier("CAMERA_secuirity_FUZZ")
    SetTimecycleModifierStrength(0.8)
    SetCamCoord(cam, infoFile.coords.x, infoFile.coords.y, infoFile.coords.z - 0.25)
    local fov = infoFile.maxFov / 2.1
    SetCamFov(cam, fov)
    SetCamRot(cam, -7.5, 0.0, infoFile.heading, 2)
    RenderScriptCams(true, false, 0, true, true)
    DisplayHud(false)
    DisplayRadar(false)

    local horizontal, vertical = 0, -7.5
    local minFov, maxFov = infoFile.minFov, infoFile.maxFov

    Citizen.CreateThread(function()
        local index = 1

        while playbackRecording and index <= #file do
            local data = file[index]
            if data.type == 'ped' then
                local ped = spawnedPeds[data.pedId] or createPed(data, infoFile, fileName)
                handlePedPlayback(ped, data)
            elseif data.type == 'vehicle' then
                local vehicle = spawnedVehicles[data.plate] or createVehicle(data, infoFile, fileName)
                handleVehiclePlayback(vehicle, data)
            end
            index = index + 1
            local adjustedWaitTime = 1000 / (#file / 30)
            Citizen.Wait(adjustedWaitTime)
        end

        RenderScriptCams(false, false, 0, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityCoords(ped, oldCoords)
        SetEntityAlpha(ped, 255, false)
        SetTimecycleModifierStrength(0.0)
        DisplayHud(true)
        DisplayRadar(true)
        SetTimecycleModifier("None")
        menuOpen = false
        playbackRecording = false

        for _, spawnedVehicle in pairs(spawnedVehicles) do
            local numberOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(spawnedVehicle))
            local pedsInVehicle = {}
            local driverSeat = -1
            local lastSeat = driverSeat + numberOfSeats - 1
        
            for seat=driverSeat, lastSeat, 1 do
                local pedInVehicleSeat = GetPedInVehicleSeat(spawnedVehicle, seat)
                SetEntityAsMissionEntity(pedInVehicleSeat)
                DeleteEntity(pedInVehicleSeat)
            end

            SetEntityAsMissionEntity(spawnedVehicle)
            DeleteEntity(spawnedVehicle)
        end

        for _, spawnedPed in pairs(spawnedPeds) do
            SetEntityAsMissionEntity(spawnedPed)
            DeleteEntity(spawnedPed)
        end

        for _, deletedVehicle in pairs(deletedVehicles) do
            SetEntityAlpha(deletedVehicle, 255, true)
            SetEntityVisible(deletedVehicle, true, true)
            
            for _, spawnedVehicle in pairs(spawnedVehicles) do
                SetEntityNoCollisionEntity(deletedVehicle, spawnedVehicle, true)
            end
        end

        spawnedPeds = {}
        spawnedVehicles = {}
    end)


    Citizen.CreateThread(function()
        while playbackRecording do
            if IsControlPressed(0, 34) then -- links
                horizontal = math.min(35.0, horizontal + fov / 100)
            elseif IsControlPressed(0, 9) then -- rechts
                horizontal = math.max(-35.0, horizontal - fov / 100)
            end

            if IsControlPressed(0, 32) then -- nach oben
                vertical = math.min(10.0, vertical + fov / 100)
            elseif IsControlPressed(0, 8) then -- nach unten
                vertical = math.max(-50.0, vertical - fov / 100)
            end

            if IsControlPressed(0, 17) then
                fov = math.max(minFov, fov - 5)
            elseif IsControlPressed(0, 16) then
                fov = math.min(maxFov, fov + 5)
            end

            SetCamRot(cam, vertical, 0.0, infoFile.heading + horizontal)
            SetCamFov(cam, fov)

            Citizen.Wait(0)
        end
    end)
end

local LastSex     = -1
local LoadSkin    = nil
local LoadClothes = nil

function ApplySkin(ped, skin)

    local playerPed = ped
    SetPedHeadBlendData     (playerPed, skin['face'], skin['face'], skin['face'], skin['skin'], skin['skin'], skin['skin'], 1.0, 1.0, 1.0, true)

  SetPedHairColor         (playerPed,       skin['hair_color_1'],   skin['hair_color_2'])           -- Hair Color
  SetPedHeadOverlay       (playerPed, 3,    skin['age_1'],         (skin['age_2'] / 10) + 0.0)      -- Age + opacity
  SetPedHeadOverlay       (playerPed, 1,    skin['beard_1'],       (skin['beard_2'] / 10) + 0.0)    -- Beard + opacity
  SetPedHeadOverlay       (playerPed, 2,    skin['eyebrows_1'],    (skin['eyebrows_2'] / 10) + 0.0) -- Eyebrows + opacity
  SetPedHeadOverlay       (playerPed, 4,    skin['makeup_1'],      (skin['makeup_2'] / 10) + 0.0)   -- Makeup + opacity
  SetPedHeadOverlay       (playerPed, 8,    skin['lipstick_1'],    (skin['lipstick_2'] / 10) + 0.0) -- Lipstick + opacity
  SetPedComponentVariation(playerPed, 2,    skin['hair_1'],         skin['hair_2'], 2)              -- Hair
  SetPedHeadOverlayColor  (playerPed, 1, 1, skin['beard_3'],        skin['beard_4'])                -- Beard Color
  SetPedHeadOverlayColor  (playerPed, 2, 1, skin['eyebrows_3'],     skin['eyebrows_4'])             -- Eyebrows Color
  SetPedHeadOverlayColor  (playerPed, 4, 1, skin['makeup_3'],       skin['makeup_4'])               -- Makeup Color
  SetPedHeadOverlayColor  (playerPed, 8, 1, skin['lipstick_3'],     skin['lipstick_4'])             -- Lipstick Color

  if skin['ears_1'] == -1 then
    ClearPedProp(playerPed, 2)
  else
    SetPedPropIndex(playerPed, 2, skin['ears_1'], skin['ears_2'], 2)  -- Ears Accessories
  end

  SetPedComponentVariation(playerPed, 8,  skin['tshirt_1'],  skin['tshirt_2'], 2)     -- Tshirt
  SetPedComponentVariation(playerPed, 11, skin['torso_1'],   skin['torso_2'], 2)      -- torso parts
  SetPedComponentVariation(playerPed, 3,  skin['arms'], 0, 2)                              -- torso
  SetPedComponentVariation(playerPed, 10, skin['decals_1'],  skin['decals_2'], 2)     -- decals
  SetPedComponentVariation(playerPed, 4,  skin['pants_1'],   skin['pants_2'], 2)      -- pants
  SetPedComponentVariation(playerPed, 6,  skin['shoes_1'],   skin['shoes_2'], 2)      -- shoes
  SetPedComponentVariation(playerPed, 1,  skin['mask_1'],    skin['mask_2'], 2)       -- mask
  SetPedComponentVariation(playerPed, 9,  skin['bproof_1'],  skin['bproof_2'], 2)     -- bulletproof
  SetPedComponentVariation(playerPed, 7,  skin['chain_1'],   skin['chain_2'], 2)      -- chain
  SetPedComponentVariation(playerPed, 5,  skin['bags_1'],    skin['bags_2'], 2)       -- Bag

  if skin['helmet_1'] == -1 then
    ClearPedProp(playerPed, 0)
  else
    SetPedPropIndex(playerPed, 0, skin['helmet_1'], skin['helmet_2'], 2)  -- Helmet
  end

  SetPedPropIndex(playerPed, 1, skin['glasses_1'], skin['glasses_2'], 2)  -- Glasses

    SetPedHeadBlendData(ped, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, true)
    SetPedHairColor(ped, skin.hair_color_1, skin.hair_color_2)
    SetPedComponentVariation(ped, 2, skin.hair_1, skin.hair_2, 2)

    SetPedComponentVariation(ped, 2, skin.hair_1 or 0, skin.hair_2 or 0, 2) -- Haare
    SetPedComponentVariation(ped, 8, skin['tshirt_1'] or 0, skin['tshirt_2'] or 0, 2) -- T-Shirt
    SetPedComponentVariation(ped, 11, skin['torso_1'] or 0, skin['torso_2'] or 0, 2) -- Oberkörper
    SetPedComponentVariation(ped, 4, skin['pants_1'] or 0, skin['pants_2'] or 0, 2) -- Hose
    
end