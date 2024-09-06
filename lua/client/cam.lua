
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

    return {
        type = 'ped',
        pedId = PedToNet(ped),
        coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z },
        heading = GetEntityHeading(ped),
        weapon = weapon,
        isInVehicle = IsPedInAnyVehicle(ped, false),
        currentAnimation = GetEntityAnimCurrentTime(ped),
        isAiming = IsPedAimingFromCover(ped) or IsPedShooting(ped),
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

local function collectVehicleData(vehicle)
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)

    local numberOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicleEntity))
    local pedsInVehicle = {}
    local driverSeat = -1
    local lastSeat = driverSeat + numberOfSeats - 1

    for seat=driverSeat, lastSeat, 1 do
        local pedInVehicleSeat = GetPedInVehicleSeat(vehicleEntity, seat)
        table.insert(pedsInVehicle, {
            ped  = pedInVehicleSeat,
            seat = seat
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
        pedInsideVeh = GetPedInVehicleSeat(vehicle, -1),
        pedsInsideVehicle = pedsInVehicle,
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

                table.insert(recordedData, collectVehicleData(vehicle))
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
                        Citizen.Wait(875)
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

local function createVehicle(data)
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
    
    local ped = CreatePedInsideVehicle(vehicle, 4, GetHashKey("a_m_y_stbla_01"), -1, false, false)
    
    SetPedFleeAttributes(ped, 2, false)  
    SetPedCombatAttributes(ped, 46, true)
    TaskSetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false) 
    SetPedCombatAttributes(ped, 46, true) 

    TaskSetBlockingOfNonTemporaryEvents(ped, true)

    SetPedCanBeDraggedOut(ped, false)

    SetEntityInvincible(vehicle, true)
    
    TaskVehicleDriveWander(ped, vehicle, 20.0, 443)  

    SetPedKeepTask(ped, true)
    
    
    SetVehicleLights(vehicle, 2)
    SetDriverAbility(ped, 1.0)
    SetDriverAggressiveness(ped, 0.0)

    spawnedVehicles[data.plate] = vehicle
    return vehicle
end


local function handlePedPlayback(ped, data)
    RequestAnimDict("move_m@brave")
    while not HasAnimDictLoaded("move_m@brave") do
        Citizen.Wait(0)
    end

    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, "move_m@brave", "walk", 8.0, -8.0, -1, 1, 0, false, false, false)
    SetEntityHeading(ped, data.heading)

    if data.isRunning then
        TaskGoStraightToCoord(ped, data.coords.x, data.coords.y, data.coords.z, 10.0, -1, 100.0, 0.0)
    elseif data.isWalking then
        TaskPlayAnim(ped, "move_m@walk", "walk", 8.0, -8.0, -1, 1, 0, false, false, false)
    elseif data.isAiming then
        TaskAimGunScripted(ped, GetHashKey("SCRIPTED_GUN_TASK"), true, true)
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

    for k, v in pairs(pedsInVehicle) do
        SetPedCoordsKeepVehicle(v.ped, data.coords.x, data.coords.y, data.coords.z)
        TaskWarpPedIntoVehicle(v.ped, vehicle, v.seat)

        SetPedCombatAttributes(v.ped, 46, true) 
        TaskVehicleDriveWander(v.ped, vehicle, 20.0, 443)
    end
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
                local vehicle = spawnedVehicles[data.plate] or createVehicle(data)
                handleVehiclePlayback(vehicle, data)
            end
            index = index + 1
            local adjustedWaitTime = 1000 / (#file / 15) 
            Citizen.Wait(math.max(adjustedWaitTime, 100))
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
local Character   = {}

function ApplySkin(ped, skin)

    SetPedHeadBlendData(ped, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, true)
    SetPedHairColor(ped, skin.hair_color_1, skin.hair_color_2)
    SetPedComponentVariation(ped, 2, skin.hair_1, skin.hair_2, 2)

    SetPedComponentVariation(ped, 2, skin.hair_1 or 0, skin.hair_2 or 0, 2) -- Haare
    SetPedComponentVariation(ped, 8, skin['tshirt_1'] or 0, skin['tshirt_2'] or 0, 2) -- T-Shirt
    SetPedComponentVariation(ped, 11, skin['torso_1'] or 0, skin['torso_2'] or 0, 2) -- Oberkörper
    SetPedComponentVariation(ped, 4, skin['pants_1'] or 0, skin['pants_2'] or 0, 2) -- Hose
    
end