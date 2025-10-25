local stateTimerConstants = {4.0, 2.0}

CreateThread(function()
    while true do
        Wait(100)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not DoesEntityExist(vehicle) then
            Wait(1000)
            goto continue
        end

        local vehicleModel = GetEntityModel(vehicle)
        if not Config.FlatBedModels[vehicleModel] then
            Wait(1000)
            goto continue
        end

        local bedNet = Entity(vehicle).state.bedProp
        if bedNet then
            Wait(1000)
            goto continue
        end
        
        TriggerServerEvent('gs_flatbed:CreateBedEntity', NetworkGetNetworkIdFromEntity(vehicle))
        Wait(1000)

        ::continue::
    end
end)

RegisterNetEvent('gs_flatbed:AttachBedToVehicle')
AddEventHandler('gs_flatbed:AttachBedToVehicle', function(vehicleNetId, bedNetId)
    local startTime = GetGameTimer()
    while (not NetworkDoesNetworkIdExist(bedNetId) and GetGameTimer()-startTime < 1000) do
        Wait(10)
    end

    -- If something went wrong and the entity is not networked, retry.
    if (not NetworkDoesNetworkIdExist(bedNetId)) then
        TriggerServerEvent('gs_flatbed:DeleteBedEntity', vehicleNetId, bedNetId)
        return
    end

    local flatbedVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)

    while (not DoesEntityExist(bedEntity)) do
        Wait(10)
    end

    local stateCoords = GetFlatbedStatePositions(flatbedVehicle)
    
    AttachEntityToEntity(
        bedEntity,
        flatbedVehicle,
        GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
        stateCoords[0].pos[1],
        stateCoords[0].pos[2],
        stateCoords[0].pos[3],
        stateCoords[0].rot[1],
        stateCoords[0].rot[2],
        stateCoords[0].rot[3],
        0,
        0,
        1,
        0,
        0,
        1
    )

    -- If something went wrong and the entity is not attached to the vehicle, retry.
    if (not IsEntityAttachedToEntity(bedEntity, flatbedVehicle)) then
        TriggerServerEvent('gs_flatbed:DeleteBedEntity', vehicleNetId, bedNetId)
    end
end)

RegisterNetEvent('gs_flatbed:LowerFlatbedClient')
AddEventHandler('gs_flatbed:LowerFlatbedClient', function(vehicleNetId)
    local flatbedVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    LowerFlatbed(flatbedVehicle)
end)

RegisterNetEvent('gs_flatbed:RaiseFlatbedClient')
AddEventHandler('gs_flatbed:RaiseFlatbedClient', function(vehicleNetId)
    local flatbedVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    RaiseFlatbed(flatbedVehicle)
end)

RegisterNetEvent('gs_flatbed:AttachVehicleClient')
AddEventHandler('gs_flatbed:AttachVehicleClient', function(vehicleNetId, vehicleToAttachNetId)
    local flatbedVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local vehicleToAttach = NetworkGetEntityFromNetworkId(vehicleToAttachNetId)
    AttachVehicle(flatbedVehicle, vehicleToAttach)
end)

RegisterNetEvent('gs_flatbed:DetachVehicleClient')
AddEventHandler('gs_flatbed:DetachVehicleClient', function(vehicleToAttachNetId)
    local vehicleToAttach = NetworkGetEntityFromNetworkId(vehicleToAttachNetId)
    DetachVehicle(vehicleToAttach)
end)

function LowerFlatbed(flatbedVehicle)
    -- Return if the flatbed does not have a bed or it is moving
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end

    -- Get the positions of the bed states.
    local stateCoords = GetFlatbedStatePositions(flatbedVehicle)

    -- Flatbed is now moving
    Entity(flatbedVehicle).state:set('bedMoving', true, true)
    local bedNet = Entity(flatbedVehicle).state.bedProp
    local bedEntity = NetworkGetEntityFromNetworkId(bedNet)

    -- Start moving
    PlaySoundEffect(flatbedVehicle)
    local LERP_VALUE = 0.0
    local state = 0
    local moveTick = CreateThread(function()
        while true do
            -- If the final state is reached, stop
            if state == 2 then
                Entity(flatbedVehicle).state:set('bedLowered', true, true)
                Entity(flatbedVehicle).state:set('bedMoving', false, true)
                ReleaseSoundEffect()
                return
            end

            -- Calculate the new offset coords
            local offsetPos = {}
            local offsetRot = {}
            for i = 1, 3 do
                offsetPos[i] = lerp(stateCoords[state].pos[i], stateCoords[state + 1].pos[i], LERP_VALUE)
                offsetRot[i] = lerp(stateCoords[state].rot[i], stateCoords[state + 1].rot[i], LERP_VALUE)
            end

            AttachEntityToEntity(
                bedEntity,
                flatbedVehicle,
                GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
                offsetPos[1],
                offsetPos[2],
                offsetPos[3],
                offsetRot[1],
                offsetRot[2],
                offsetRot[3],
                0,
                0,
                1,
                0,
                0,
                1
            )

            -- Calculate the new leap value
            LERP_VALUE = LERP_VALUE + (1.0 * GetFrameTime()) / stateTimerConstants[state + 1]
            if LERP_VALUE >= 1.0 then
                LERP_VALUE = 0.0
                state = state + 1
            end
            
            Wait(0)
        end
    end)
end

function RaiseFlatbed(flatbedVehicle)
    -- Return if the flatbed does not have a bed or it is moving
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end

    -- Get the positions of the bed states.
    local stateCoords = GetFlatbedStatePositions(flatbedVehicle)
    
    -- Flatbed is now moving
    Entity(flatbedVehicle).state:set('bedMoving', true, true)
    local bedNet = Entity(flatbedVehicle).state.bedProp
    local bedEntity = NetworkGetEntityFromNetworkId(bedNet)

    -- Start moving
    PlaySoundEffect(flatbedVehicle)
    local LERP_VALUE = 0.0
    local state = 2
    local moveTick = CreateThread(function()
        while true do
            -- If the final state is reached, stop
            if state == 0 then
                Entity(flatbedVehicle).state:set('bedLowered', false, true)
                Entity(flatbedVehicle).state:set('bedMoving', false, true)
                ReleaseSoundEffect()
                return
            end

            -- Reset the offset coords
            local offsetPos = {}
            local offsetRot = {}

            -- Calculate the new offset coords
            for i = 1, 3 do
                offsetPos[i] = lerp(stateCoords[state].pos[i], stateCoords[state - 1].pos[i], LERP_VALUE)
                offsetRot[i] = lerp(stateCoords[state].rot[i], stateCoords[state - 1].rot[i], LERP_VALUE)
            end

            AttachEntityToEntity(
                bedEntity,
                flatbedVehicle,
                GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
                offsetPos[1],
                offsetPos[2],
                offsetPos[3],
                offsetRot[1],
                offsetRot[2],
                offsetRot[3],
                0,
                0,
                1,
                0,
                0,
                1
            )

            -- Calculate the new leap value
            LERP_VALUE = LERP_VALUE + (1.0 * GetFrameTime()) / stateTimerConstants[state]
            if LERP_VALUE >= 1.0 then
                LERP_VALUE = 0.0
                state = state - 1
            end
            
            Wait(0)
        end
    end)
end

function lerp(start, finish, amount)
    return (1 - amount) * start + amount * finish
end

function AttachVehicle(flatbedVehicle, vehicleToAttach)
    -- Check if vehicleToAttach exists
    if not DoesEntityExist(vehicleToAttach) then return end

    -- Return if the flatbed does not have a bed or it is moving
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end

    -- Get the bed from the flatbed
    local bedNet = Entity(flatbedVehicle).state.bedProp
    local bedToAttachTo = NetworkGetEntityFromNetworkId(bedNet)

    -- Determine the rotations
    local vehicleRotation = GetEntityRotation(vehicleToAttach, 2)
    local bedRotation = GetEntityRotation(bedToAttachTo, 2)

    -- Determine the rotation offset
    local rotationOffsetZ = vehicleRotation.z - bedRotation.z

    -- Determine the positions
    local vehicleCoords = GetEntityCoords(vehicleToAttach)
    local bedOffsetCoords = GetOffsetFromEntityGivenWorldCoords(bedToAttachTo, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)

    -- Attach the vehicle
    AttachEntityToEntity(
        vehicleToAttach,
        bedToAttachTo,
        0,
        bedOffsetCoords.x,
        bedOffsetCoords.y,
        bedOffsetCoords.z + 0.025,
        0.0, -- xRot
        0.0, -- yRot
        rotationOffsetZ, -- zRot
        0, -- p9
        0, -- useSoftPinning
        false, -- collision
        false, -- isPed
        2, -- rotationOrder
        true -- syncRot
    )
end

function DetachVehicle(vehicleToDetach)
    -- Check if vehicleToDetach exists
    if not DoesEntityExist(vehicleToDetach) then return end

    -- Update the flatbed and detach entity
    DetachEntity(vehicleToDetach, false, true)
    SetVehicleOnGroundProperly(vehicleToDetach)
end

function DoesFlatbedHaveBedAndNotMoving(vehicle)
    local hasBed = Entity(vehicle).state.bedProp ~= nil
    local isMoving = Entity(vehicle).state.bedMoving
    return hasBed and not isMoving
end

local soundId = nil
function PlaySoundEffect(entity)
    if soundId ~= nil then
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end

    soundId = GetSoundId()
    local audioName = 'OPENING'
    local audioRef = 'DOOR_GARAGE'
    PlaySoundFromEntity(soundId, audioName, entity, audioRef, false, false);
end

function ReleaseSoundEffect()
    if soundId == nil then
        return
    end

    StopSound(soundId)
    ReleaseSoundId(soundId)
    soundId = nil
end

function GetFlatbedStatePositions(entity)
    if not DoesEntityExist(entity) then return end

    local vehicleModel = GetEntityModel(entity)
    if (not Config.FlatBedModels[vehicleModel]) then return end

    local stateCoords = Config.FlatBedModels[vehicleModel]
    return stateCoords
end