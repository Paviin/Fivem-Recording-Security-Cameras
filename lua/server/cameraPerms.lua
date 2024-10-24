if Config.Framework == "ESX" then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
elseif Config.Framework == "QB" then
    QBCore = exports['qb-core']:GetCoreObject()
end

RegisterNetEvent('videoRecordingCameras:requestCamerasPermission')
AddEventHandler('videoRecordingCameras:requestCamerasPermission', function()
    local cameras = {}
    local source_ = source
    local resourceName = GetCurrentResourceName()
    local files = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))

    if Config.Framework == "ESX" or Config.Framework == "QB" then
        local function isCameraAlreadyAdded(cam)
            for _, v in ipairs(cameras) do
                if v.cameras.id == cam then
                    return true
                end
            end
            return false
        end

        local function addCameraIfPermitted(jobName)
            for _, cam in ipairs(Config.Cams) do
                for _, job in ipairs(cam.permissions.jobs) do
                    if job.name == jobName then
                        if not isCameraAlreadyAdded(cam.id) then
                            for _, file in ipairs(files) do
                                if file.id == cam.id then
                                    table.insert(cameras, {cameras = file})
                                end
                            end
                        end
                    end
                end
            end
        end

        local function addCameraIfPermittedLicense(license)
            for _, cam in ipairs(Config.Cams) do
                for _, identifiers in ipairs(cam.permissions.identifiers) do
                    print(identifiers.identifier , license)
                    if identifiers.identifier == license then
                        if not isCameraAlreadyAdded(cam.id) then
                            for _, file in ipairs(files) do
                                if file.id == cam.id then
                                    table.insert(cameras, {cameras = file})
                                end
                            end
                        end
                    end
                end
            end
        end

        -- ESX Job Check
        if Config.Framework == "ESX" then
            local xPlayer = ESX.GetPlayerFromId(source_)
            if xPlayer then
                local jobName = xPlayer.getJob().name
                addCameraIfPermitted(jobName)
                addCameraIfPermittedLicense(xPlayer.identifier)
            end

        -- QB Job Check
        elseif Config.Framework == "QB" then
            local Player = QBCore.Functions.GetPlayer(source_)
            if Player then
                local jobName = Player.PlayerData.job.name
                addCameraIfPermitted(jobName)
                addCameraIfPermittedLicense(Player.PlayerData.license)
            end
        end

        TriggerClientEvent('videoRecordingCameras:requestCamerasPermission', source_, cameras)

    else
        local validIdentifiers = {}
        local validJobs = {}

        local function isCameraAlreadyAdded(cam)
            for _, v in ipairs(cameras) do
                if v.cameras.id == cam then
                    return true
                end
            end
            return false
        end

        local function checkIdentifiers()
            for _, id in ipairs(playerIdentifiers) do
                local match_
                if string.sub(id, 1, string.len("steam:")) == "steam:" then
                    match_ = string.match(id, ":(%w+)")
                elseif string.sub(id, 1, string.len("license:")) == "license:" then
                    match_ = string.match(id, ":(%w+)")
                elseif string.sub(id, 1, string.len("xbl:")) == "xbl:" then
                    match_ = string.match(id, ":(%w+)")
                elseif string.sub(id, 1, string.len("ip:")) == "ip:" then
                    match_ = string.match(id, ":(%w+)")
                elseif string.sub(id, 1, string.len("discord:")) == "discord:" then
                    match_ = string.match(id, ":(%w+)")
                elseif string.sub(id, 1, string.len("live:")) == "live:" then
                    match_ = string.match(id, ":(%w+)")
                end

                if match_ then
                    for _, cam in ipairs(Config.Cams) do
                        for _, perm in ipairs(cam.permissions.identifiers) do
                            local identifier = perm.identifier or ""
                            if identifier ~= "" then
                                local permMatch = string.match(identifier, ":(%w+)")
                                if permMatch == match_ then
                                    validIdentifiers[cam.id] = true
                                end
                            end
                        end
                    end
                end
            end
        end

        local function checkJobs()
            for _, cam in ipairs(Config.Cams) do
                for _, job in ipairs(cam.permissions.jobs) do
                    MySQL.Async.fetchAll(Config.JobsTableQuery, { ["@job"] = job.name }, function(result)
                        tprint(result)
                        if result[1] then
                            validJobs[cam.id] = true
                        end
                    end)
                end
            end
        end

        local function processPermissions()
            for _, cam in ipairs(Config.Cams) do
                if validIdentifiers[cam.id] or validJobs[cam.id] then
                    if not isCameraAlreadyAdded(cam.id) then
                        for _, file in ipairs(files) do
                            if file.id == cam.id then
                                table.insert(cameras, {cameras = file})
                            end
                        end
                    end
                end
            end

            TriggerClientEvent('videoRecordingCameras:requestCamerasPermission', source_, cameras)
        end

        checkIdentifiers()
        checkJobs()
        processPermissions()
    end
end)

-- Debug-Funktion
function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end
