ButcherCorpsesB42Util = ButcherCorpsesB42Util or {}

ButcherCorpsesB42Util.onCreate_getFreshResult = function(items, result, player)
    if result and result.setAge then
        result:setAge(0)
    end
end

ButcherCorpsesB42Util.OnEat_CorpseFlesh = function(food, player, percent)
    local effectOnEat = SandboxVars.ButcherCorpsesB42 and SandboxVars.ButcherCorpsesB42.EffectOnEat or 3
    ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect(effectOnEat, percent * food:getActualWeight(), player)
end

ButcherCorpsesB42Util.OnEat_CookedCorpseFlesh = function(food, player, percent)
    local effectOnEatCooked = SandboxVars.ButcherCorpsesB42 and SandboxVars.ButcherCorpsesB42.EffectOnEatCooked or 1
    ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect(effectOnEatCooked, percent * food:getActualWeight(), player)
end

-- setting 1 = no effect | 2 = food sick | 3 = infection | 4 = both
ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect = function(setting, amount, player)
    if not player then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if setting == 2 or setting == 4 then
        local sickness = bodyDamage:getFoodSicknessLevel() + amount * 100
        bodyDamage:setFoodSicknessLevel(sickness)
    end

    if setting == 3 or setting == 4 then
        bodyDamage:setInfected(true)
    end
end
