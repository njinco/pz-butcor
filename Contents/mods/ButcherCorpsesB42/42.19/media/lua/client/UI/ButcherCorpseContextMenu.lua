ButcherCorpsesB42 = ButcherCorpsesB42 or {};

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

local function itemHasTag(item, tag)
    if not item or not tag then
        return false
    end
    if item.hasTag and item:hasTag(tag) then
        return true
    end
    local tags = item.getTags and item:getTags() or nil
    return tags and tags:contains(tag) or false
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
    if not playerObj then
        return false
    end
    return playerObj:getInventory():getFirstEvalRecurse(isButcherTool) ~= nil
end

local function getCorpseFromSquare(square)
    if not square then
        return nil
    end
    local staticMovingObjects = square:getStaticMovingObjects()
    if staticMovingObjects then
        for i=0, staticMovingObjects:size()-1 do
            local staticMovingObject = staticMovingObjects:get(i)
            if instanceof(staticMovingObject, "IsoDeadBody") then
                return staticMovingObject
            end
        end
    end
    return nil
end

local function getCorpseFromWorldObjects(worldobjects)
    for i=1, #worldobjects do
        local worldObject = worldobjects[i]
        if instanceof(worldObject, "IsoDeadBody") then
            return worldObject
        end
        local square = worldObject and worldObject.getSquare and worldObject:getSquare() or nil
        local corpse = getCorpseFromSquare(square)
        if corpse then
            return corpse
        end
    end
    return nil
end

ButcherCorpsesB42.getButcherTool = function(player)
    local handItem = player:getPrimaryHandItem()
    if handItem and isButcherTool(handItem) then
        return handItem
    end
    return player:getInventory():getFirstEvalRecurse(isButcherTool)
end

ButcherCorpsesB42.onButcherCorpse = function(worldobjects, WItem, player)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then
        return
    end
    if WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare()) then
        local butcherItem = ButcherCorpsesB42.getButcherTool(playerObj)
        if butcherItem then
            butcherItem = ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), butcherItem, true)
            ISTimedActionQueue.add(ButcherCorpseB42Action:new(playerObj, WItem, butcherItem, ButcherCorpsesB42.ActionTime));
        else
            print("No valid tool found! Likely broken...")
        end
    end
end

ButcherCorpsesB42.onButcherMenu = function(player, context, worldobjects)
    local body = getCorpseFromWorldObjects(worldobjects)
    if body and hasButcherTool(player) then
        context:addOption(getText("ContextMenu_ButcherCorpsesB42_Butcher_Corpse"), worldobjects, ButcherCorpsesB42.onButcherCorpse, body, player);
    end
end

Events.OnFillWorldObjectContextMenu.Add(ButcherCorpsesB42.onButcherMenu);
