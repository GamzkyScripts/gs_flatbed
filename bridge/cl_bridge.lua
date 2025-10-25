ESX = nil
QBCore = nil

if (GetResourceState('es_extended') == 'started') then
    ESX = exports['es_extended']:getSharedObject()
elseif (GetResourceState('qb-core') == 'started') then
    QBCore = exports['qb-core']:GetCoreObject()
end

Functions = {}


-- A function to get the closest entity
Functions.GetClosestEntity = function(params)
    local coords = params.coords
    local pool = params.pool
    local range = params.range or 5.0
    local test = params.test or function() return true end
    
    local closestEntity = nil
    local closestDistance = range
    
    local entities = GetGamePool(pool)
    for i = 1, #entities do
        local entity = entities[i]
        if DoesEntityExist(entity) and test(entity) then
            local entityCoords = GetEntityCoords(entity)
            local distance = #(coords - entityCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestEntity = entity
            end
        end
    end
    
    return closestEntity
end

-- A function to show notification
Functions.ShowNotification = function(params)
    if ESX then
        ESX.ShowNotification(params.message, 'info', 5000)
    elseif QBCore then
        QBCore.Functions.Notify(params.message, 'primary', 5000)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(params.message)
        DrawNotification(false, false)
    end
end

-- A function to create flatbed target interactions
Functions.CreateFlatbedTarget = function()
    local flatbedModels = {}
    for k, v in pairs(Config.FlatBedModels) do
        table.insert(flatbedModels, k)
    end

    if (next(flatbedModels) == nil) then
        print("[ERROR] No flatbed vehicle models are configured in config.lua under FlatBedModels.")
        return
    end

    if (GetResourceState('ox_target') == 'started') then
        exports.ox_target:addModel(flatbedModels, {
            {
                label = Config.Locales['lower_bed'],
                icon = 'fa-solid fa-arrows-down-to-line',
                distance = 3.0,
                groups = Config.Jobs,
                onSelect = function(data)
                    TriggerEvent('gs_flatbed:LowerFlatbed', data.entity)
                end,
                canInteract = function(entity)
                    return Functions.CanInteractWithFlatbed(entity, 'lower')
                end,
            },
            {
                label = Config.Locales['raise_bed'],
                icon = 'fa-solid fa-arrows-up-to-line',
                distance = 3.0,
                groups = Config.Jobs,
                onSelect = function(data)
                    TriggerEvent('gs_flatbed:RaiseFlatbed', data.entity)
                end,
                canInteract = function(entity)
                    return Functions.CanInteractWithFlatbed(entity, 'raise')
                end,
            },
            {
                label = Config.Locales['attach_vehicle'],
                icon = 'fa-solid fa-link',
                distance = 3.0,
                groups = Config.Jobs,
                onSelect = function(data)
                    TriggerEvent('gs_flatbed:AttachVehicle', data.entity)
                end,
                canInteract = function(entity)
                    return Functions.CanInteractWithFlatbed(entity, 'attach')
                end,
            },
            {
                label = Config.Locales['detach_vehicle'],
                icon = 'fa-solid fa-link-slash',
                distance = 3.0,
                groups = Config.Jobs,
                onSelect = function(data)
                    TriggerEvent('gs_flatbed:DetachVehicle', data.entity)
                end,
                canInteract = function(entity)
                    return Functions.CanInteractWithFlatbed(entity, 'detach')
                end,
            },
        })
    elseif (GetResourceState('qb-target') == 'started') then
        exports['qb-target']:AddTargetModel(flatbedModels, {
            options = {
                {
                    label = Config.Locales['lower_bed'],
                    icon = 'fa-solid fa-arrows-down-to-line',
                    job = Config.Jobs,
                    action = function(entity)
                        TriggerEvent('gs_flatbed:LowerFlatbed', entity)
                    end,
                    canInteract = function(entity)
                        return Functions.CanInteractWithFlatbed(entity, 'lower')
                    end,
                },
                {
                    label = Config.Locales['raise_bed'],
                    icon = 'fa-solid fa-arrows-up-to-line',
                    job = Config.Jobs,
                    action = function(entity)
                        TriggerEvent('gs_flatbed:RaiseFlatbed', entity)
                    end,
                    canInteract = function(entity)
                        return Functions.CanInteractWithFlatbed(entity, 'raise')
                    end,
                },
                {
                    label = Config.Locales['attach_vehicle'],
                    icon = 'fa-solid fa-link',
                    job = Config.Jobs,
                    action = function(entity)
                        TriggerEvent('gs_flatbed:AttachVehicle', entity)
                    end,
                    canInteract = function(entity)
                        return Functions.CanInteractWithFlatbed(entity, 'attach')
                    end,
                },
                {
                    label = Config.Locales['detach_vehicle'],
                    icon = 'fa-solid fa-link-slash',
                    job = Config.Jobs,
                    action = function(entity)
                        TriggerEvent('gs_flatbed:DetachVehicle', entity)
                    end,
                    canInteract = function(entity)
                        return Functions.CanInteractWithFlatbed(entity, 'detach')
                    end,
                },
            },
            distance = 3.0,
        })
    end
end

-- A function to check if player can interact with flatbed
Functions.CanInteractWithFlatbed = function(entity, action)
    local ped = PlayerPedId()
    local isPedInVehicle = IsPedInAnyVehicle(ped, false)
    local isPedDead = IsPedDeadOrDying(ped, true)

    if (isPedInVehicle or isPedDead) then
        return false
    end

    local hasBed = Entity(entity).state.bedProp ~= nil
    local isMoving = Entity(entity).state.bedMoving
    local bedLowered = Entity(entity).state.bedLowered
    local attachedVehicle = Entity(entity).state.attachedVehicle

    if not hasBed or isMoving then
        return false
    end

    if action == 'lower' then
        return not bedLowered
    elseif action == 'raise' then
        return bedLowered
    elseif action == 'attach' then
        return bedLowered and attachedVehicle == -1
    elseif action == 'detach' then
        return bedLowered and attachedVehicle ~= -1
    end

    return false
end
