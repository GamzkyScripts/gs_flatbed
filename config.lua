Config = {}

-- The used vehicle and bed model.
Config.FlatbedHash = GetHashKey('flatbed')
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