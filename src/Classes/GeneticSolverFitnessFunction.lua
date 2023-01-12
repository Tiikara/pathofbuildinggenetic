local calcs = LoadModule("Modules/Calcs")

local usedNodeCountWeight = 5
local usedNodeCountFactor = .0005
local csvWeightMultiplier = 10

GeneticSolverFitnessFunction = { }

local function CalcCsv(x, weight, target)
    x = math.min(x, target);
    return math.exp(weight * csvWeightMultiplier * x / target) / math.exp(weight * csvWeightMultiplier);
end

function GeneticSolverFitnessFunction.CalculateAndGetFitnessScore(dna,
                                                                  targetNormalNodesCount,
                                                                  targetAscendancyNodesCount)

    local usedNormalNodeCount, usedAscendancyNodeCount = dna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)

    local csvs = 1

    if usedNormalNodeCount > targetNormalNodesCount then
        csvs = csvs * CalcCsv(2 * targetNormalNodesCount - usedNormalNodeCount, usedNodeCountWeight, targetNormalNodesCount)
    elseif (usedNormalNodeCount < targetNormalNodesCount) then
        csvs = csvs * 1 + usedNodeCountFactor * math.log(targetNormalNodesCount + 1 - usedNormalNodeCount);
    end

    if usedAscendancyNodeCount > targetAscendancyNodesCount then
        csvs = csvs * CalcCsv(2 * targetAscendancyNodesCount - usedAscendancyNodeCount, usedNodeCountWeight, targetAscendancyNodesCount)
    elseif (usedAscendancyNodeCount < targetAscendancyNodesCount) then
        csvs = csvs * 1 + usedNodeCountFactor * math.log(targetAscendancyNodesCount + 1 - usedAscendancyNodeCount);
    end

    local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(dna.build, "MAIN")
    calcs.perform(env)

    local stats = env.player.output

    csvs = csvs * CalcCsv(stats.TotalEHP, 1, 79400)
    csvs = csvs * CalcCsv(stats.Life, 1, 3600)
    if stats.SpellSuppressionChance then
        csvs = csvs * CalcCsv(stats.SpellSuppressionChance, 1, 100)
    else
        csvs = csvs * CalcCsv(0, 1, 100)
    end

    if not stats.LifeLeechGainRate then
        stats.LifeLeechGainRate = 0
    end

    if not stats.LifeRegenRecovery then
        stats.LifeRegenRecovery = 0
    end

    if stats.LifeLeechGainRate + stats.LifeRegenRecovery ~= 0 then
        csvs = csvs * CalcCsv(stats.LifeLeechGainRate + stats.LifeRegenRecovery, 1, 1892)
    else
        csvs = csvs * CalcCsv(0, 1, 1892)
    end

    csvs = csvs * CalcCsv((stats.LightningResist + stats.FireResist + stats.ColdResist) / 3.0, 1, 76)

    if stats.ManaUnreserved then
        csvs = csvs * CalcCsv(stats.ManaUnreserved, 1, 97)
    else
        csvs = csvs * CalcCsv(0, 1, 97)
    end

    if not stats.ManaLeechGainRate then
        stats.ManaLeechGainRate = 0
    end

    csvs = csvs * CalcCsv(stats.ManaLeechGainRate, 1, 100)
    csvs = csvs * CalcCsv(stats.PhysicalMaximumHitTaken, 1, 11600)
    csvs = csvs * CalcCsv(stats.LightningMaximumHitTaken, 1, 25000)

    return csvs * stats.CombinedDPS * stats.CombinedDPS
end
