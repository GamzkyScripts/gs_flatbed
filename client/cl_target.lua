local inAction = false

function IsBedLowered(vehicle)
    return Entity(vehicle).state.bedLowered
end

function IsVehicleAttachedToBed(vehicle)
    return Entity(vehicle).state.attachedVehicle ~= -1
end

function IsBedClearOfVehicle(vehicle)
    return Entity(vehicle).state.attachedVehicle == -1
end

function OriginLowerFlatbed(flatbedVehicle)
    if (IsFlatbedUsingRope(flatbedVehicle)) then return end

    -- Execute lower flatbed on entity owner
    local entityOwner = NetworkGetEntityOwner(flatbedVehicle)
    if PlayerId() == entityOwner then
        LowerFlatbed(flatbedVehicle)
    else
        TriggerServerEvent('gs_flatbed:LowerFlatbed', NetworkGetNetworkIdFromEntity(flatbedVehicle))
    end
end

function OriginRaiseFlatbed(flatbedVehicle)
    if (IsFlatbedUsingRope(flatbedVehicle)) then return end

    -- Execute raise flatbed on entity owner
    local entityOwner = NetworkGetEntityOwner(flatbedVehicle)
    if PlayerId() == entityOwner then
        RaiseFlatbed(flatbedVehicle)
    else
        TriggerServerEvent('gs_flatbed:RaiseFlatbed', NetworkGetNetworkIdFromEntity(flatbedVehicle))
    end
end

function OriginAttachVehicle(flatbedVehicle)
    if (IsFlatbedUsingRope(flatbedVehicle)) then return end

    local bedForOffset = NetToObj(Entity(flatbedVehicle).state.bedProp)
    if not DoesEntityExist(bedForOffset) then return end

    local closestVehicle = Functions.GetClosestEntity({
        coords = GetOffsetFromEntityInWorldCoords(bedForOffset, 0.0, 1.5, 0.5),
        pool = 'CVehicle',
        range = 2,
        test = function(vehicle)
            return vehicle ~= flatbedVehicle
        end,
    })

    if not DoesEntityExist(closestVehicle) then
        Functions.ShowNotification({ message = Config.Locales['no_vehicle_found'] })
        return
    end

    -- Execute attach on entity owner
    local entityOwner = NetworkGetEntityOwner(closestVehicle)
    if PlayerId() == entityOwner then
        AttachVehicle(flatbedVehicle, closestVehicle)
        Entity(flatbedVehicle).state:set('attachedVehicle', VehToNet(closestVehicle), true) -- Update the state locally
    else
        TriggerServerEvent('gs_flatbed:AttachVehicle', NetworkGetNetworkIdFromEntity(flatbedVehicle), NetworkGetNetworkIdFromEntity(closestVehicle))
    end
end

function OriginDetachVehicle(flatbedVehicle)
    if (IsFlatbedUsingRope(flatbedVehicle)) then return end

    local attachedVehicleNet = Entity(flatbedVehicle).state.attachedVehicle
    local attachedVehicle = NetToVeh(attachedVehicleNet)

    -- Execute attach on entity owner
    local entityOwner = NetworkGetEntityOwner(attachedVehicle)
    if PlayerId() == entityOwner then
        DetachVehicle(attachedVehicle)
        Entity(flatbedVehicle).state:set('attachedVehicle', -1, true)
    else
        TriggerServerEvent('gs_flatbed:DetachVehicle', NetworkGetNetworkIdFromEntity(flatbedVehicle), NetworkGetNetworkIdFromEntity(attachedVehicle))
    end
end

-- A function which handles the animation for flatbed operations
function HandleAnimation()
    local ped = PlayerPedId()
        
    -- Load animation dictionary
    local dict = Config.Animation.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    
    -- Load prop model
    local propModel = Config.Animation.prop_model
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end
    
    -- Create and attach prop
    local prop = CreateObject(propModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, Config.Animation.prop_bone), 
        Config.Animation.prop_placement[1], Config.Animation.prop_placement[2], Config.Animation.prop_placement[3], 
        Config.Animation.prop_placement[4], Config.Animation.prop_placement[5], Config.Animation.prop_placement[6], 
        true, true, false, true, 1, true)
    
    -- Play animation
    TaskPlayAnim(ped, dict, Config.Animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Store prop reference for cleanup
    Functions.currentProp = prop
end

-- A function to cancel the current animation
function CancelAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    -- Clean up prop if it exists
    if Functions.currentProp and DoesEntityExist(Functions.currentProp) then
        DeleteEntity(Functions.currentProp)
        Functions.currentProp = nil
    end
end

-- Event handlers for target interactions
RegisterNetEvent('gs_flatbed:LowerFlatbed')
AddEventHandler('gs_flatbed:LowerFlatbed', function(flatbedVehicle)
    if inAction then return end
    inAction = true
    HandleAnimation()
    Wait(Config.Animation.duration)
    CancelAnimation()
    OriginLowerFlatbed(flatbedVehicle)
    inAction = false
end)

RegisterNetEvent('gs_flatbed:RaiseFlatbed')
AddEventHandler('gs_flatbed:RaiseFlatbed', function(flatbedVehicle)
    if inAction then return end
    inAction = true
    HandleAnimation()
    Wait(Config.Animation.duration)
    CancelAnimation()
    OriginRaiseFlatbed(flatbedVehicle)
    inAction = false
end)

RegisterNetEvent('gs_flatbed:AttachVehicle')
AddEventHandler('gs_flatbed:AttachVehicle', function(flatbedVehicle)
    if inAction then return end
    inAction = true
    HandleAnimation()
    Wait(Config.Animation.duration)
    CancelAnimation()
    OriginAttachVehicle(flatbedVehicle)
    inAction = false
end)

RegisterNetEvent('gs_flatbed:DetachVehicle')
AddEventHandler('gs_flatbed:DetachVehicle', function(flatbedVehicle)
    if inAction then return end
    inAction = true
    HandleAnimation()
    Wait(Config.Animation.duration)
    CancelAnimation()
    OriginDetachVehicle(flatbedVehicle)
    inAction = false
end)

-- Initialize target system
CreateThread(function()
    Functions.CreateFlatbedTarget()
end)

function IsFlatbedUsingRope(flatbedVehicle)
    local isRopeInUse = Entity(flatbedVehicle).state.RopeAttachedVehicle ~= nil
    if isRopeInUse then
        Functions.ShowNotification({ message = Config.Locales['rope_in_use'] })
        return true
    end
    return false
end
