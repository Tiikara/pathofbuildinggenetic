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

    local usedNormalNodeCount, usedAscendancyNodeCount = dna:ConvertDnaToBuild()

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

    csvs = csvs * CalcCsv(stats.TotalEHP, 1, 66000)
    csvs = csvs * CalcCsv(stats.Life, 1, 3000)
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
        csvs = csvs * CalcCsv((stats.LifeLeechGainRate + stats.LifeRegenRecovery) / stats.Life, 1, 0.5)
    else
        csvs = csvs * CalcCsv(0, 1, 0.5)
    end

    csvs = csvs * CalcCsv((stats.LightningResist + stats.FireResist + stats.ColdResist) / 3.0, 1, 76)

    return csvs * stats.CombinedDPS
end
