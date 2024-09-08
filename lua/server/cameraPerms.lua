RegisterNetEvent('videoRecordingCameras:requestCamerasPermission')
AddEventHandler('videoRecordingCameras:requestCamerasPermission', function()
    local cameras = {}
    local source_ = source
    local resourceName = GetCurrentResourceName()
    local files = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))

    local playerIdentifiers = GetPlayerIdentifiers(source_)
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
        local jobs_count = 0
        local jobs_total = 0

        for _, cam in ipairs(Config.Cams) do
            jobs_total = jobs_total + #cam.permissions.jobs
        end

        local function processJobResult(camId, result)
            local valid = false
            for _, job in ipairs(result) do
                local match = string.match(job.identifier, ":(%w+)")
                for _, id in ipairs(playerIdentifiers) do
                    local playerMatch = string.match(id, ":(%w+)")
                    if playerMatch == match then
                        valid = true
                        break
                    end
                end
                if valid then break end
            end

            if valid then
                validJobs[camId] = true
            end

            jobs_count = jobs_count + 1
            if jobs_count == jobs_total then
                for _, cam in ipairs(Config.Cams) do
                    local emptyPermissions = true
                    for _, perm in ipairs(cam.permissions.jobs) do
                        if perm.name ~= "" then
                            emptyPermissions = false
                            break
                        end
                    end
                    for _, perm in ipairs(cam.permissions.identifiers) do
                        if perm.identifier ~= "" then
                            emptyPermissions = false
                            break
                        end
                    end

                    if not emptyPermissions and (validIdentifiers[cam.id] or validJobs[cam.id]) then
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
        end

        for _, cam in ipairs(Config.Cams) do
            for _, job in ipairs(cam.permissions.jobs) do
                MySQL.Async.fetchAll(Config.JobsTableQuery, { ["@job"] = job.name }, function(result)
                    processJobResult(cam.id, result)
                end)
            end
        end
    end

    checkIdentifiers()
    checkJobs()
end)


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
