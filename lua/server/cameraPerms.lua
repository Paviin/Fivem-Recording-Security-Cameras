RegisterNetEvent('videoRecordingCameras:requestCamerasPermission')
AddEventHandler('videoRecordingCameras:requestCamerasPermission', function()
    local identifiers = {}
    local cameras     = {}
    local source_ = source
    local resourceName = GetCurrentResourceName()
    local files = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))


    local function isCameraAlreadyAdded(cam)
        for _, v in pairs(cameras) do
            if v.cameras.id == cam then
                return true
            end
        end
        return false
    end

    for k,v in pairs(GetPlayerIdentifiers(source_)) do
        local match_
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            match_ = string.match(v, ":(%w+)")
        end

        for k_,v_ in pairs(Config.Cams) do
            for k__,v__ in pairs(v_.permissions.identifiers) do
                local match = string.match(v__.identifier, ":(%w+)")
                if match == match_ then
                    if not isCameraAlreadyAdded(v_.id) then
                        for k___, v___ in pairs(files) do
                            if v___.id == v_.id then
                                table.insert(cameras, {cameras = v___})
                            end
                        end
                    end
                end
            end
        end
    end

    local jobs_count = 0
    local jobs_total = 0

    for k,v in pairs(Config.Cams) do
        jobs_total = jobs_total + #v.permissions.jobs
    end

    for k,v in pairs(Config.Cams) do
        for k_,v_ in pairs(v.permissions.jobs) do
            MySQL.Async.fetchAll(Config.JobsTableQuery, { ["@job"] = v_.name }, function(result)
                for k__,v__ in pairs(result) do
                    local match = string.match(v__.identifier, ":(%w+)")
                    local match_ = false

                    for k___,v___ in pairs(GetPlayerIdentifiers(source_)) do
                        if string.sub(v___, 1, string.len("steam:")) == "steam:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        elseif string.sub(v___, 1, string.len("license:")) == "license:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        elseif string.sub(v___, 1, string.len("xbl:")) == "xbl:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        elseif string.sub(v___, 1, string.len("ip:")) == "ip:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        elseif string.sub(v___, 1, string.len("discord:")) == "discord:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        elseif string.sub(v___, 1, string.len("live:")) == "live:" then
                            if not match_ then
                                match_ = string.match(v___, ":(%w+)") == match
                            end
                        end

                        
                    end
                    if match_ then
                        if not isCameraAlreadyAdded(v.id) then
                            for k_____, v_____ in pairs(files) do
                                if v_____.id == v.id then
                                    table.insert(cameras, {cameras = v_____})
                                end
                            end
                        end
                    end
                end

                jobs_count = jobs_count + 1
                if jobs_count == jobs_total then
                    TriggerClientEvent('videoRecordingCameras:requestCamerasPermission', source_, cameras)
                end
            end)
        end
    end
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