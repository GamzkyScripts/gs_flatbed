AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    -- Check if entity is a vehicle
    if GetEntityType(entity) ~= 2 then return end

    -- Ensure the entity is a flatbed
    local vehicleModel = GetEntityModel(entity)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Ensure the flatbed does not already have a bed prop.
    local entityBedNetId = Entity(entity).state.bedProp
    if (entityBedNetId and DoesEntityExist(NetworkGetEntityFromNetworkId(entityBedNetId))) then return end
    Entity(entity).state.bedProp = nil

    -- Make the owner create the bed
    local flatbedNetId = NetworkGetNetworkIdFromEntity(entity)
    TriggerEvent('gs_flatbed:CreateBedEntity', flatbedNetId)
end)

AddEventHandler('entityRemoved', function(entity)
    -- Check if entity is a vehicle
    if GetEntityType(entity) ~= 2 then return end

    -- Ensure the entity is a flatbed
    local vehicleModel = GetEntityModel(entity)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Check if bed net is set
    local entityBedNetId = Entity(entity).state.bedProp
    if not entityBedNetId then return end

    -- Delete the bed if it exists.
    local entityBed = NetworkGetEntityFromNetworkId(entityBedNetId)
    if not DoesEntityExist(entityBed) then return end
    DeleteEntity(entityBed)
end)

RegisterNetEvent('gs_flatbed:CreateBedEntity')
AddEventHandler('gs_flatbed:CreateBedEntity', function(flatbedNetId)
    -- Ensure the flatbedVehicle is an existing entity.
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the entity is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Ensure the flatbed does not already have a bed prop.
    local bedNetId = Entity(flatbedVehicle).state.bedProp
    if bedNetId then
        local existingBedEntity = NetworkGetEntityFromNetworkId(bedNetId)
        if DoesEntityExist(existingBedEntity) then return end
    end

    -- Create the bed flatbedVehicle, we spawn it under the flatbed to avoid floating flatbeds in case something goes wrong.
    local vehicleCoords = GetEntityCoords(flatbedVehicle)
    local vehicleRotation = GetEntityRotation(flatbedVehicle)
    local bedEntity = CreateObjectNoOffset(Config.BedModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z - 3.0, true, 0, 1)

    -- Wait for the bed to exist, and attach it to the flatbed
    while not DoesEntityExist(bedEntity) do
        Wait(10)
    end
    SetEntityRotation(bedEntity, vehicleRotation)

    -- Get the entity owner of both entities.
    local flatbedVehicleEntityOwner = NetworkGetEntityOwner(flatbedVehicle)
    local bedEntityOwner = NetworkGetEntityOwner(bedEntity)

    -- Wait for a maximum of 500 ms to give time for entity ownership to settle.
    local startTime = GetGameTimer()
    while (flatbedVehicleEntityOwner ~= bedEntityOwner and GetGameTimer() - startTime < 500) do
        Wait(100)
    end

    -- If the entity owners still do not match and if the server is not the owner, we abort this spawn attempt. The client will retry in 1 second.
    if flatbedVehicleEntityOwner ~= bedEntityOwner and bedEntityOwner ~= -1 then
        DeleteEntity(bedEntity)
        return
    end

    bedNetId = NetworkGetNetworkIdFromEntity(bedEntity)

    -- Re-validate both entities before setting statebags (race condition protection).
    if not DoesEntityExist(flatbedVehicle) then
        DeleteEntity(bedEntity)
        return
    end
    if not DoesEntityExist(bedEntity) then
        return
    end

    -- Set all the statebags
    Entity(flatbedVehicle).state.bedProp = bedNetId
    Entity(flatbedVehicle).state.attachedVehicle = -1
    Entity(flatbedVehicle).state.bedLowered = false
    Entity(flatbedVehicle).state.bedMoving = false

    -- Attach the bed to the flatbed on the entity owner.
    local flatbedOwner = NetworkGetEntityOwner(flatbedVehicle)
    if flatbedOwner ~= -1 then
        TriggerClientEvent('gs_flatbed:AttachBedToVehicle', flatbedOwner, flatbedNetId, bedNetId)
    end
end)

RegisterNetEvent('gs_flatbed:DeleteBedEntity')
AddEventHandler('gs_flatbed:DeleteBedEntity', function(flatbedNetId, bedNetId)
    -- Ensure the bedEntity exists
    local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
    if DoesEntityExist(bedEntity) then
        -- Ensure the bedEntity is a flatbed base prop
        if GetEntityModel(bedEntity) ~= GetHashKey(Config.BedModel) then return end
        DeleteEntity(bedEntity)
    end

    -- Ensure the flatbedVehicle is a flatbed
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the entity is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Delete any existing bed prop.
    local bedNetId = Entity(flatbedVehicle).state.bedProp
    if bedNetId then
        local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
        if DoesEntityExist(bedEntity) then
            DeleteEntity(bedEntity)
        end
    end
    Entity(flatbedVehicle).state.bedProp = nil
end)

RegisterNetEvent('gs_flatbed:LowerFlatbed')
AddEventHandler('gs_flatbed:LowerFlatbed', function(flatbedNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the flatbedVehicle is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Re-validate entity before getting owner
    if not DoesEntityExist(flatbedVehicle) then return end
    local flatbedOwner = NetworkGetEntityOwner(flatbedVehicle)
    if flatbedOwner ~= -1 then
        TriggerClientEvent('gs_flatbed:LowerFlatbedClient', flatbedOwner, flatbedNetId)
    end
end)

RegisterNetEvent('gs_flatbed:RaiseFlatbed')
AddEventHandler('gs_flatbed:RaiseFlatbed', function(flatbedNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the flatbedVehicle is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    -- Re-validate entity before getting owner
    if not DoesEntityExist(flatbedVehicle) then return end
    local flatbedOwner = NetworkGetEntityOwner(flatbedVehicle)
    if flatbedOwner ~= -1 then
        TriggerClientEvent('gs_flatbed:RaiseFlatbedClient', flatbedOwner, flatbedNetId)
    end
end)

RegisterNetEvent('gs_flatbed:AttachVehicle')
AddEventHandler('gs_flatbed:AttachVehicle', function(flatbedNetId, vehicleToAttachNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the other flatbedVehicle exists as well
    local attachEntity = NetworkGetEntityFromNetworkId(vehicleToAttachNetId)
    if not DoesEntityExist(attachEntity) then return end

    -- Ensure the flatbedVehicle is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    Entity(flatbedVehicle).state.attachedVehicle = vehicleToAttachNetId -- Update the state server-sided (as Flatbed owner can be a different player)
    local attachOwner = NetworkGetEntityOwner(attachEntity)
    if attachOwner ~= -1 then
        TriggerClientEvent('gs_flatbed:AttachVehicleClient', attachOwner, flatbedNetId, vehicleToAttachNetId)
    end
end)

RegisterNetEvent('gs_flatbed:DetachVehicle')
AddEventHandler('gs_flatbed:DetachVehicle', function(flatbedNetId, vehicleToAttachNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the other flatbedVehicle exists as well
    local attachEntity = NetworkGetEntityFromNetworkId(vehicleToAttachNetId)
    if not DoesEntityExist(attachEntity) then return end

    -- Ensure the flatbedVehicle is a flatbed
    local vehicleModel = GetEntityModel(flatbedVehicle)
    if not Config.FlatBedModels[vehicleModel] then return end

    Entity(flatbedVehicle).state.attachedVehicle = -1
    local attachOwner = NetworkGetEntityOwner(attachEntity)
    if attachOwner ~= -1 then
        TriggerClientEvent('gs_flatbed:DetachVehicleClient', attachOwner, vehicleToAttachNetId)
    end
end)