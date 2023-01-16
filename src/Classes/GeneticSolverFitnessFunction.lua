local calcs = LoadModule("Modules/Calcs")

local usedNodeCountWeight = 5
local usedNodeCountFactor = .0005
local csvWeightMultiplier = 10

local function CalcCsv(x, weight, target)
    x = math.min(x, target);
    return math.exp(weight * csvWeightMultiplier * x / target) / math.exp(weight * csvWeightMultiplier);
end

local GeneticSolverFitnessFunction = newClass("GeneticSolverFitnessFunction", function(self, build)
    self.build = build

    local mapDisplayStatsPlayer = {}
    for _, stat in build.displayStats do
        if stat.stat then
            mapDisplayStatsPlayer[stat.stat] = stat
        end
    end

    local mapDisplayStatsMinion = {}
    for _, stat in build.minionDisplayStats do
        if stat.stat then
            mapDisplayStatsMinion[stat.stat] = stat
        end
    end

    self.mapDisplayStatsByActor = {
        player = mapDisplayStatsPlayer,
        minion = mapDisplayStatsMinion
    }
end)

function GeneticSolverFitnessFunction:CalculateAndGetFitnessScore(dnaConvertResult,
                                                                  targetNormalNodesCount,
                                                                  targetAscendancyNodesCount,
                                                                  targetStats,
                                                                  maximizeStats
)
    local csvs = 1

    local usedNormalNodeCount = dnaConvertResult.usedNormalNodeCount
    local usedAscendancyNodeCount = dnaConvertResult.usedAscendancyNodeCount

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

    local env, _, _, _ = calcs.initEnv(self.build, "MAIN")
    calcs.perform(env)

    for _, targetStat in targetStats do
        local statData = self.mapDisplayStatsByActor[targetStat.actor][targetStat.stat]

        local actor = env[targetStat.actor]
        local statVal = actor.output[statData.stat]
        if statVal and statVal > 0 and ((statData.condFunc and statData.condFunc(statVal, actor.output)) or (not statData.condFunc and statVal ~= 0)) then
            csvs = csvs * CalcCsv(statVal, targetStat.weight, targetStat.target)
        else
            csvs = csvs * CalcCsv(0, targetStat.weight, targetStat.target)
        end
    end

    for _, targetStat in maximizeStats do
        local statData = self.mapDisplayStatsByActor[targetStat.actor][targetStat.stat]

        local actor = env[targetStat.actor]
        local statVal = actor.output[statData.stat]
        if statVal and statVal > 0 and ((statData.condFunc and statData.condFunc(statVal, actor.output)) or (not statData.condFunc and statVal ~= 0)) then
            csvs = csvs * targetStat.weight * statVal
        else
            csvs = csvs * 0.01
        end
    end

    return csvs
end
