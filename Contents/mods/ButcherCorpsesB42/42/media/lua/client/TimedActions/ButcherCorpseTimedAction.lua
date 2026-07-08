require "TimedActions/ISBaseTimedAction"

ButcherCorpseB42Action = ISBaseTimedAction:derive("ButcherCorpseB42Action")
ButcherCorpseB42Action.soundDelay = 1

local function isLiveObject(object)
    return object ~= nil
end

local function getCorpseSquare(corpseBody)
    if not corpseBody or not corpseBody.getSquare then
        return nil
    end
    return corpseBody:getSquare()
end

local function setCorpseJobDelta(corpse, delta)
    if corpse and corpse.setJobDelta then
        corpse:setJobDelta(delta)
    end
end

function ButcherCorpseB42Action:isValid()
    if not isLiveObject(self.character) or not isLiveObject(self.corpseBody) then
        return false
    end
    if not self.corpseBody.getStaticMovingObjectIndex then
        return false
    end
    return self.corpseBody:getStaticMovingObjectIndex() >= 0 and getCorpseSquare(self.corpseBody) ~= nil
end

function ButcherCorpseB42Action:waitToStart()
    if not self:isValid() then
        return false
    end
    self.character:faceThisObject(self.corpseBody)
    return self.character:shouldBeTurning()
end

function ButcherCorpseB42Action:update()
    if not self:isValid() then
        return
    end

    if self.soundTime + ButcherCorpseB42Action.soundDelay < getTimestamp() then
        self.soundTime = getTimestamp()

        self.sound = self.character:getEmitter():playSound("SliceMeat")
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 10)

        local square = getCorpseSquare(self.corpseBody)
        if square then
            addBloodSplat(square, ZombRand(15, 25))
        end
        self.character:splatBlood(2.0, 1.0)
        self.character:addBlood(nil, true, false, false)

        if self.usesWeapon and self.butcherItem and self.butcherItem.getBloodLevel then
            local itemBlood = self.butcherItem:getBloodLevel()
            if itemBlood <= 0.95 then
                self.butcherItem:setBloodLevel(itemBlood + 0.05)
                self.character:resetModel()
            elseif itemBlood <= 1 then
                self.butcherItem:setBloodLevel(1)
                self.character:resetModel()
            end
        end
    end

    setCorpseJobDelta(self.corpse, self:getJobDelta())
    self.character:faceThisObject(self.corpseBody)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function ButcherCorpseB42Action:start()
    if self.corpse and self.corpse.setJobType then
        self.corpse:setJobType(getText("ContextMenu_ButcherCorpsesB42_Butcher_Corpse"))
    end
    setCorpseJobDelta(self.corpse, 0.0)
    if self.character then
        self.character:SetVariable("LootPosition", "Low")
        self:setActionAnim("Loot")
        self.character:reportEvent("EventLootItem")
    end
end

function ButcherCorpseB42Action:stop()
    if self.character and self.sound and self.sound ~= 0 and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end

    ISBaseTimedAction.stop(self)
    setCorpseJobDelta(self.corpse, 0.0)
end

function ButcherCorpseB42Action:perform()
    setCorpseJobDelta(self.corpse, 0.0)

    if not self:isValid() then
        ISBaseTimedAction.perform(self)
        return
    end

    if self.character and self.character:getInventory() then
        self.character:getInventory():setDrawDirty(true)
    end

    local corpseSquare = getCorpseSquare(self.corpseBody)
    if not corpseSquare then
        ISBaseTimedAction.perform(self)
        return
    end

    local args = {
        x = corpseSquare:getX(),
        y = corpseSquare:getY(),
        z = corpseSquare:getZ(),
        corpseIndex = self.corpseBody:getStaticMovingObjectIndex(),
    }

    if isClient() then
        sendClientCommand(self.character, "ButcherCorpsesB42", "ButcherCorpse", args)
    elseif ButcherCorpsesB42Util and ButcherCorpsesB42Util.butcherCorpse then
        ButcherCorpsesB42Util.butcherCorpse(self.character, args)
    end

    local pdata = self.character and getPlayerData(self.character:getPlayerNum()) or nil
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks()
        pdata.lootInventory:refreshBackpacks()
    end

    ISBaseTimedAction.perform(self)
end

function ButcherCorpseB42Action:new(character, corpseBody, butcherItem, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.corpseBody = corpseBody
    o.corpse = corpseBody and corpseBody.getItem and corpseBody:getItem() or corpseBody
    o.butcherItem = butcherItem
    o.usesWeapon = instanceof(o.butcherItem, "HandWeapon")
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.forceProgressBar = true
    o.soundTime = 0
    return o
end
