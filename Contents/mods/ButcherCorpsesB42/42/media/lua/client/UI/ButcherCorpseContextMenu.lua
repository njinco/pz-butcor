require "TimedActions/ButcherCorpseTimedAction"

ButcherCorpsesB42 = ButcherCorpsesB42 or {}

ButcherCorpsesB42.ActionTime = 240
ButcherCorpsesB42.ToolTypes = {
    MeatCleaver = true,
    HandAxe = true,
    Axe = true,
    WoodAxe = true,
}
ButcherCorpsesB42.ToolTags = {
    SharpKnife = true,
    Saw = true,
}

local function listContains(list, value)
    if not list or not value then
        return false
    end
    if list.contains then
        return list:contains(value)
    end
    if list.size and list.get then
        for i=0, list:size()-1 do
            if list:get(i) == value then
                return true
            end
        end
    end
    return false
end

local function itemHasTag(item, tag)
    if not item or not tag then
        return false
    end
    if item.hasTag and item:hasTag(tag) then
        return true
    end
    if item.getTags then
        return listContains(item:getTags(), tag)
    end
    return false
end

local function isButcherTool(item)
    if not item or item:isBroken() then
        return false
    end
    if ButcherCorpsesB42.ToolTypes[item:getType()] or ButcherCorpsesB42.ToolTypes[item:getFullType()] then
        return true
    end
    for tag in pairs(ButcherCorpsesB42.ToolTags) do
        if itemHasTag(item, tag) then
            return true
        end
    end
    return false
end

local function hasButcherTool(player)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not playerObj:getInventory() then
        return false
    end
    return playerObj:getInventory():getFirstEvalRecurse(isButcherTool) ~= nil
end

local function isCorpseObject(object)
    return object and instanceof(object, "IsoDeadBody")
end

local function getCorpseFromSquare(square)
    if not square then
        return nil
    end

    if square.getDeadBody then
        local body = square:getDeadBody()
        if body then
            return body
        end
    end

    local staticMovingObjects = square.getStaticMovingObjects and square:getStaticMovingObjects() or nil
    if staticMovingObjects then
        for i=0, staticMovingObjects:size()-1 do
            local staticMovingObject = staticMovingObjects:get(i)
            if isCorpseObject(staticMovingObject) then
                return staticMovingObject
            end
        end
    end

    local movingObjects = square.getMovingObjects and square:getMovingObjects() or nil
    if movingObjects then
        for i=0, movingObjects:size()-1 do
            local movingObject = movingObjects:get(i)
            if isCorpseObject(movingObject) then
                return movingObject
            end
        end
    end

    return nil
end

local function getWorldObjectSquare(worldObject)
    if not worldObject then
        return nil
    end
    if worldObject.getSquare then
        return worldObject:getSquare()
    end
    return nil
end

local function getCorpseFromWorldObjects(worldobjects)
    if not worldobjects then
        return nil
    end
    for i=1, #worldobjects do
        local worldObject = worldobjects[i]
        if isCorpseObject(worldObject) then
            return worldObject
        end
        local corpse = getCorpseFromSquare(getWorldObjectSquare(worldObject))
        if corpse then
            return corpse
        end
    end
    return nil
end

ButcherCorpsesB42.getButcherTool = function(player)
    if not player then
        return nil
    end
    local handItem = player:getPrimaryHandItem()
    if handItem and isButcherTool(handItem) then
        return handItem
    end
    return player:getInventory():getFirstEvalRecurse(isButcherTool)
end

ButcherCorpsesB42.onButcherCorpse = function(worldobjects, body, player)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not body or not body.getSquare then
        return
    end

    local square = body:getSquare()
    if square and luautils.walkAdj(playerObj, square) then
        local butcherItem = ButcherCorpsesB42.getButcherTool(playerObj)
        if butcherItem then
            butcherItem = ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), butcherItem, true)
            ISTimedActionQueue.add(ButcherCorpseB42Action:new(playerObj, body, butcherItem, ButcherCorpsesB42.ActionTime))
        else
            print("No valid tool found! Likely broken...")
        end
    end
end

ButcherCorpsesB42.onButcherMenu = function(player, context, worldobjects)
    if not context or not worldobjects then
        return
    end
    local body = getCorpseFromWorldObjects(worldobjects)
    if body and hasButcherTool(player) then
        context:addOption(getText("ContextMenu_ButcherCorpsesB42_Butcher_Corpse"), worldobjects, ButcherCorpsesB42.onButcherCorpse, body, player)
    end
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then
        return
    end
    local ok, err = pcall(ButcherCorpsesB42.onButcherMenu, player, context, worldobjects)
    if not ok then
        print("ButcherCorpsesB42 context menu error: " .. tostring(err))
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
