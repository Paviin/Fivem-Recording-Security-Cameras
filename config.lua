
Config = {}

Config.Debug = false

Config.Distance = 20.0

Config.JobsTableQuery = 'SELECT identifier FROM users WHERE job = @job'

Config.Marker = {
    enabled = true,
    settings = {
        type = 22,
        scale = 1.0,
        bobUpAndDown = true,
        faceCamera = true,
        color = {
            r = 0,
            g = 255,
            b = 100,
            a = 100
        }
    }
}

Config.Cams = {
    {
        id  = 1,
        title = "Police Cam",
        description = "Police Cam 1",
        controlPoint = vector3(189.6041, 301.7457, 105.477),
        camCoords = vector3(226.0677, 381.9196, 110.4175), 
        camHeading = 90.0, 
        fov = 50.0, 
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 2,
        maxCamHeightFov = 2,

        permissions = {
            jobs = {
                {
                    name = ""
                }
            },
            identifiers = {
                {
                    identifier = "license:d6a4657db0b45d37b70d43840f04b204711be1c6"
                }
            }
        }
    },
    {
        id = 2,
        title = "Police Cam",
        description = "Police Cam 2",
        controlPoint = vector3(-393.0705, -2764.1851, 6.0004),
        camCoords = vector3(193.5627, 334.4494, 109.4351), 
        camHeading = 185.5589, 
        fov = 50.0, 
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 5,
        maxCamHeightFov = 1,

        permissions = {
            jobs = {
                {
                    name = "unemployed"
                }
            },
            identifiers = {
                {
                    identifier = "steam:123456789abcdef"
                }
            }
        }
    },
}