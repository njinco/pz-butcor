ButcherCorpses = {};

ButcherCorpses.Recipe = getScriptManager():getRecipe("ButCor.ButCor Butcher Corpse")
ButcherCorpses.RecipeTools = {}
if ButcherCorpses.Recipe then
    for i=0, ButcherCorpses.Recipe:getSource():size()-1 do
        local source = ButcherCorpses.Recipe:getSource():get(i);
        if source:isKeep() then
            ButcherCorpses.RecipeTools = source:getItems()
            break
        end
    end
end

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

local function itemMatchesRecipeTool(item, recipeTool)
    if not item or not recipeTool then
        return false
    end
    if recipeTool == item:getFullType() or recipeTool == item:getType() then
        return true
    end
    if recipeTool == "SharpKnife" or recipeTool == "[Recipe.GetItemTypes.SharpKnife]" then
        return itemHasTag(item, "SharpKnife")
    end
    if recipeTool == "Saw" or recipeTool == "[Recipe.GetItemTypes.Saw]" then
        return itemHasTag(item, "Saw")
    end
    return false
end

local function isButcherTool(item)
    if item then
        for i=0, ButcherCorpses.RecipeTools:size()-1 do
            local recipeTool = ButcherCorpses.RecipeTools:get(i)
            if not item:isBroken() and itemMatchesRecipeTool(item, recipeTool) then
                return true
            end
        end
    end
    return false
end

local function hasButcherTool(player)
    local inventory = getSpecificPlayer(player):getInventory()
    return inventory:getFirstEvalRecurse(isButcherTool) ~= nil
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

ButcherCorpses.getButcherTool = function(player)
    local playerInv = player:getInventory();
    -- first check if we have a valid tool equipped
    local handItem = player:getPrimaryHandItem()
    if handItem and isButcherTool(handItem) then
        return handItem
    end
    -- if not, check if there's a valid tool in inventory
    return playerInv:getFirstEvalRecurse(isButcherTool)
end

ButcherCorpses.onButcherCorpse = function(worldobjects, WItem, player)
    if not ButcherCorpses.Recipe then
        return
    end
    local playerObj = getSpecificPlayer(player)
    -- walk to corpse
    if WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare()) then
        -- equip item and start action
        local butcherItem = ButcherCorpses.getButcherTool(playerObj)
        if butcherItem then
            butcherItem = ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), butcherItem, true)
            ISTimedActionQueue.add(ButcherCorpseAction:new(playerObj, WItem,butcherItem, ButcherCorpses.Recipe:getTimeToMake()));
        else
            print("No valid tool found! Likely broken...")
        end
    end
end

ButcherCorpses.onButcherMenu = function(player, context, worldobjects)
    if not ButcherCorpses.Recipe then
        return
    end
    local body = getCorpseFromWorldObjects(worldobjects)
    if body and hasButcherTool(player) then
        context:addOption(getText("ContextMenu_ButCor_Butcher_Corpse"), worldobjects, ButcherCorpses.onButcherCorpse, body, player);
    end
end

Events.OnFillWorldObjectContextMenu.Add(ButcherCorpses.onButcherMenu);
