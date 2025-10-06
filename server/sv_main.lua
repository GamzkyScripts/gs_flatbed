AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    -- Check if entity is a vehicle
    if GetEntityType(entity) ~= 2 then return end

    -- Ensure the entity is a flatbed
    if GetEntityModel(entity) ~= Config.FlatbedHash then return end

    -- Make the owner create the bed
    -- local entityOwner = NetworkGetEntityOwner(entity)
    --TriggerClientEvent('gs_flatbed:CreateBedEntity', entityOwner, NetworkGetNetworkIdFromEntity(entity))
    local flatbedNetId = NetworkGetNetworkIdFromEntity(entity)
    TriggerEvent('gs_flatbed:CreateBedEntity', flatbedNetId)
end)

AddEventHandler('entityRemoved', function(entity)
    -- Check if entity is a vehicle
    if GetEntityType(entity) ~= 2 then return end

    -- Ensure the entity is a flatbed
    if GetEntityModel(entity) ~= Config.FlatbedHash then return end

    -- Delete the bed
    local entityBedNetId = Entity(entity).state.bedProp
    local entityBed = NetworkGetEntityFromNetworkId(entityBedNetId)
    DeleteEntity(entityBed)
end)

RegisterNetEvent('gs_flatbed:CreateBedEntity')
AddEventHandler('gs_flatbed:CreateBedEntity', function(flatbedNetId)
    -- Ensure the flatbedVehicle is the correct entity model.
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end
    if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then return end

    -- Ensure the flatbed does not already have a bed prop.
    local bedNetId = Entity(flatbedVehicle).state.bedProp
    if (bedNetId and DoesEntityExist(bedNetId)) then return end

    -- Create the bed flatbedVehicle
    local vehicleCoords = GetEntityCoords(flatbedVehicle)
    local bedEntity = CreateObjectNoOffset(Config.BedModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, true, 0, 1)

    -- Wait for the bed to exist, and attach it to the flatbed
    while not DoesEntityExist(bedEntity) do
        Wait(10)
    end

    bedNetId = NetworkGetNetworkIdFromEntity(bedEntity)

    -- Set all the statebags
    Entity(flatbedVehicle).state.bedProp = bedNetId
    Entity(flatbedVehicle).state.attachedVehicle = -1
    Entity(flatbedVehicle).state.bedLowered = false
    Entity(flatbedVehicle).state.bedMoving = false

    -- Attach the bed to the flatbed on the entity owner.
    TriggerClientEvent('gs_flatbed:AttachBedToVehicle', NetworkGetEntityOwner(flatbedVehicle), flatbedNetId, bedNetId)
end)

RegisterNetEvent('gs_flatbed:RespawnBedEntity')
AddEventHandler('gs_flatbed:RespawnBedEntity', function(flatbedNetId, bedNetId)
    -- Ensure the bedEntity exists
    local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
    if DoesEntityExist(bedEntity) then
        -- Ensure the bedEntity is a flatbed base prop
        if GetEntityModel(bedEntity) ~= GetHashKey(Config.BedModel) then
            return
        end
        DeleteEntity(bedEntity)
    end

    -- Ensure the flatbedVehicle is a flatbed
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if DoesEntityExist(flatbedVehicle) then
        -- Ensure the bedEntity is a flatbed base prop
        if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then
            return
        end

        -- Delete any existing bed prop.
        local bedNetId = Entity(flatbedVehicle).state.bedProp
        local bedEntity = NetworkGetEntityFromNetworkId(bedNetID)
        if (DoesEntityExist(bedEntity)) then DeleteEntity(bedEntity) end
        Entity(flatbedVehicle).state.bedProp = nil
        
        -- Wait a bit to prevent very fast respawning of bed props on server hickups. Then create new bed entity.
        Wait(500)
        TriggerEvent('gs_flatbed:CreateBedEntity', flatbedNetId)
    end
end)

RegisterNetEvent('gs_flatbed:LowerFlatbed')
AddEventHandler('gs_flatbed:LowerFlatbed', function(flatbedNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the flatbedVehicle is a flatbed
    if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then return end

    TriggerClientEvent('gs_flatbed:LowerFlatbedClient', NetworkGetEntityOwner(flatbedVehicle), flatbedNetId)
end)

RegisterNetEvent('gs_flatbed:RaiseFlatbed')
AddEventHandler('gs_flatbed:RaiseFlatbed', function(flatbedNetId)
    -- Ensure the flatbedVehicle exists
    local flatbedVehicle = NetworkGetEntityFromNetworkId(flatbedNetId)
    if not DoesEntityExist(flatbedVehicle) then return end

    -- Ensure the flatbedVehicle is a flatbed
    if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then return end

    TriggerClientEvent('gs_flatbed:RaiseFlatbedClient', NetworkGetEntityOwner(flatbedVehicle), flatbedNetId)
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
    if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then return end

    Entity(flatbedVehicle).state.attachedVehicle = vehicleToAttachNetId -- Update the state server-sided (as Flatbed owner can be a different player)
    TriggerClientEvent('gs_flatbed:AttachVehicleClient', NetworkGetEntityOwner(attachEntity), flatbedNetId, vehicleToAttachNetId)
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
    if GetEntityModel(flatbedVehicle) ~= Config.FlatbedHash then return end

    Entity(flatbedVehicle).state.attachedVehicle = -1
    TriggerClientEvent('gs_flatbed:DetachVehicleClient', NetworkGetEntityOwner(attachEntity), vehicleToAttachNetId)
end)