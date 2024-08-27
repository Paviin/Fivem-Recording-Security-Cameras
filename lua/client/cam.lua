local camCoords = vector3(-388.9052, -2764.9802, 10.0004)
local camHorizontalHeading = 307.4732
local fov = 40.0
local length = 200.0
local camHeightFov = 50.0
local recordedData = {}
local entitiesInZone = {}
local playbackRecording = false

local halfFov = fov / 2.0
local radHorizontalHeading = math.rad(camHorizontalHeading + 90)

local function calculateZoneCorners()
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

local function createCamZone()
    local corners = calculateZoneCorners()
    return PolyZone:Create({
        vector2(corners.backLeft.x, corners.backLeft.y),
        vector2(corners.frontLeft.x, corners.frontLeft.y),
        vector2(corners.frontRight.x, corners.frontRight.y),
        vector2(corners.backRight.x, corners.backRight.y)
    }, {
        name = "camera_zone",
        minZ = camCoords.z - camHeightFov,
        maxZ = camCoords.z + camHeightFov,
        debugPoly = Config.Debug
    })
end

local camZone = createCamZone()

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

local function collectPedData(ped)
    local pedCoords = GetEntityCoords(ped)
    local weapon = GetSelectedPedWeapon(ped)

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
        isRagdoll = IsPedRagdoll(ped)
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
        print(seat, pedInVehicleSeat)
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

    for entity, _ in pairs(entitiesInZone) do
        if DoesEntityExist(entity) and not camZone:isPointInside(GetEntityCoords(entity)) then
            if IsEntityAPed(entity) then
                table.insert(recordedData, collectPedData(entity))
            elseif IsEntityAVehicle(entity) then
                table.insert(recordedData, collectVehicleData(entity))
            end
            entitiesInZone[entity] = nil
        end
    end

    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and camZone:isPointInside(GetEntityCoords(ped)) and isEntityVisibleToCamera(camCoords, ped) and GetVehiclePedIsIn(ped, false) == 0 then
            entitiesInZone[ped] = true
            table.insert(recordedData, collectPedData(ped))
        end
    end

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and camZone:isPointInside(GetEntityCoords(vehicle)) and isEntityVisibleToCamera(camCoords, vehicle) then
            entitiesInZone[vehicle] = true
            table.insert(recordedData, collectVehicleData(vehicle))
        end
    end
end

local isPlayerInZone = false
local spawnedPeds = {}
local spawnedVehicles = {}

camZone:onPlayerInOut(function(isPointInside, point, entity)
    isPlayerInZone = isPointInside

    if isPlayerInZone then
        print("Spieler oder Ped erkannt")
        TriggerServerEvent('createFile')
        Citizen.CreateThread(function()
            while isPlayerInZone do
                collectDataInZone()
                Citizen.Wait(875)
            end
        end)
    else
        TriggerServerEvent('videoRecordingCameras:createCacheFile', recordedData)
        print("Spieler oder Ped hat Sichtweite verlassen und Daten wurden gespeichert")
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

local function createPed(data)
    local ped = CreatePed(4, GetHashKey("a_m_y_stbla_01"), data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
    spawnedPeds[data.pedId] = ped
    return ped
end

local function createVehicle(data)
    local vehicle = CreateVehicle(data.model, data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleColours(vehicle, data.colorPrimary, data.colorSecondary)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleEngineOn(vehicle, data.isEngineRunning, true, false)
    SetVehicleCurrentRpm(vehicle, data.rpm)
    SetVehicleFuelLevel(vehicle, data.fuelLevel)
    local ped = CreatePedInsideVehicle(vehicle, 4, GetHashKey("a_m_y_stbla_01"), -1, true, false)
    TaskVehicleDriveWander(ped, vehicle, 20.0, 443)
    SetVehicleLights(vehicle, 2)

    spawnedVehicles[data.plate] = vehicle
    return vehicle
end

local function handlePedPlayback(ped, data)
    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z)
    SetEntityHeading(ped, data.heading)

    if data.isRunning then
        TaskGoStraightToCoord(ped, data.coords.x, data.coords.y, data.coords.z, 10, -1, 100.0)
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

    for seat=driverSeat, lastSeat, 1 do
        local pedInVehicleSeat = GetPedInVehicleSeat(vehicle, seat)
        table.insert(pedsInVehicle, {
            ped  = pedInVehicleSeat,
            seat = seat
        })
    end

    SetEntityCoords(vehicle, data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0, false)

    for k,v in pairs(pedsInVehicle) do
        print(v.ped)
        TaskVehicleDriveWander(v.ped, vehicle, 20.0, 443)
        SetPedCoordsKeepVehicle(v.ped, data.coords.x, data.coords.y, data.coords.z)
        SetPedIntoVehicle(v.ped, vehicle, v.seat)
    end
    SetPedIntoVehicle(GetPedInVehicleSeat(vehicle, -1), vehicle, -1)


    SetEntityHeading(vehicle, data.heading)
    SetVehicleOnGroundProperly(vehicle)
end

local function removeNonRecordedEntities()
    Citizen.CreateThread(function()
        while playbackRecording do
            local allPeds = GetGamePool('CPed')
            local allVehicles = GetGamePool('CVehicle')
        
            for _, ped in ipairs(allPeds) do
                if DoesEntityExist(ped) and camZone:isPointInside(GetEntityCoords(ped)) then
                    --DeletePed(ped)
                end
            end
        
            for _, vehicle in ipairs(allVehicles) do
                for _, spawnedVehicle in pairs (spawnedVehicles) do
                    print(vehicle,spawnedVehicle)
                    if vehicle ~= spawnedVehicle then
                        if DoesEntityExist(vehicle) and camZone:isPointInside(GetEntityCoords(vehicle)) then
                            --SetEntityAsMissionEntity(vehicle, true, true)
                            --DeleteVehicle(vehicle)
                            --SetVehicleAsNoLongerNeeded(vehicle)
                        end
                    end
                end
            end
            Citizen.Wait(1000)
        end
    end)
end

function watchVideo(file)
    playbackRecording = true

    removeNonRecordedEntities()
    if #file == 0 then
        print("No recorded data available.")
        return
    end

    local modelsToRequest = { "a_m_y_stbla_01", "a_m_y_beach_02" }
    requestModels(modelsToRequest)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamFov(cam, fov - 20)
    RenderScriptCams(true, false, 0, true, true)
    SetCamRot(cam, 0.0, 0.0, camHorizontalHeading, 2) 
    DisplayHud(false)
    DisplayRadar(false)

    Citizen.CreateThread(function()
        local index = 1

        while playbackRecording and index <= #file do
            local data = file[index]
            if data.type == 'ped' then
                local ped = spawnedPeds[data.pedId] or createPed(data)
                handlePedPlayback(ped, data)
            elseif data.type == 'vehicle' then
                local vehicle = spawnedVehicles[data.plate] or createVehicle(data)
                handleVehiclePlayback(vehicle, data)
            end
            index = index + 1
            local adjustedWaitTime = 1000 / (#file / 20) 
            Citizen.Wait(math.max(adjustedWaitTime, 100))
        end

        RenderScriptCams(false, false, 0, true, true)
        DisplayHud(true)
        DisplayRadar(true)
        playbackRecording = false
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(#file * 875 + 1000)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        DisplayHud(true)
        DisplayRadar(true)
        print("Playback finished and camera reset.")
    end)
end
