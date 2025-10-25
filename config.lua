Config = {}

-- The used vehicle models on which the flatbed will spawn.
Config.FlatBedModels = {
    [`flatbed`] = {
        [0] = { pos = {0.0, -3.6, 0.22}, rot = {0.0, 0.0, 0.0} }, -- This is the position of the bed with respect to the flatbed vehicle, after spawning in (so the bed is raised).
        [1] = { pos = {0.0, -7.6, 0.22}, rot = {0.0, 0.0, 0.0} }, -- This is the position of the bed after translating backwards, when retracting the bed.
        [2] = { pos = {0.0, -7.8, -0.7}, rot = {14.0, 0.0, 0.0} }, -- This is the position of the bed after rotating downwards, which allows vehicles to drive onto the bed.
    },
}

-- The bed model
Config.BedModel = 'inm_flatbed_base'

-- Animation configuration.
Config.Animation = {
    dict = 'amb@world_human_tourist_map@male@base',
    anim = 'base',
    prop_model = 'xm_prop_x17_tem_control_01',
    prop_bone = 28422,
    prop_placement = { -0.01, 0, 0, -20.0, 364.0, 0.0 },
    duration = 1500, -- Animation duration in milliseconds
}

-- Job configuration, set `Config.Jobs = nil` to disable.
Config.Jobs = { ['mechanic'] = 0, ['police'] = 0 }

-- Localization configuration.
Config.Locales = {
    ['lower_bed'] = 'Lower Bed',
    ['raise_bed'] = 'Raise Bed', 
    ['attach_vehicle'] = 'Attach Vehicle',
    ['detach_vehicle'] = 'Detach Vehicle',
    ['no_vehicle_found'] = 'No vehicle found.',
}