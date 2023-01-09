math.randomseed(os.clock())

local calcs = LoadModule("Modules/Calcs")

local usedNodeCountWeight = 5
local usedNodeCountFactor = .0005
local csvWeightMultiplier = 10

local GeneticSolverDna = newClass("GeneticSolverDna", function(self, build)
    self.build = build
    self.nodesDna = { }
    self.fitnessScore = nil
end)

function GeneticSolverDna:AsTable()
    return self.nodesDna
end

function GeneticSolverDna:InitFromTable(dnaTable)
    self.nodesDna = dnaTable
end

function GeneticSolverDna:Clone()
    local newGeneticSolverDna = new("GeneticSolverDna", self.build)
    newGeneticSolverDna.fitnessScore = self.fitnessScore

    for k, v in pairs(self.nodesDna) do
        newGeneticSolverDna.nodesDna[k] = v
    end

    return newGeneticSolverDna
end

function GeneticSolverDna:Generate()
    self:Mutate(10 * 1.0 / 1200.0)
end

function GeneticSolverDna:GenerateFromCurrentBuild()
    for _, treeNode in pairs(self.build.spec.nodes) do
        if treeNode.alloc then
            self.nodesDna[treeNode.id] = 1
        else
            self.nodesDna[treeNode.id] = nil
        end
    end
end

function GeneticSolverDna:Mutate(probabilityToMutateGen)
    for _, treeNode in pairs(self.build.spec.nodes) do
        local isMutated = math.random() < probabilityToMutateGen

        if isMutated then
            if self.nodesDna[treeNode.id] == nil
            then
                self.nodesDna[treeNode.id] = 1
            else
                self.nodesDna[treeNode.id] = nil
            end
        end
    end

    self.fitnessScore = nil
end

function GeneticSolverDna:Selection(partnerDna)
    local newGeneticSolverDna = new("GeneticSolverDna", self.build)

    for _, treeNode in pairs(self.build.spec.nodes) do
        local isMine = 0.5 < math.random()

        if isMine then
            newGeneticSolverDna.nodesDna[treeNode.id] = self.nodesDna[treeNode.id]
        else
            newGeneticSolverDna.nodesDna[treeNode.id] = partnerDna.nodesDna[treeNode.id]
        end
    end

    return newGeneticSolverDna
end

function GeneticSolverDna:CalcCsv(x, weight, target)
    x = math.min(x, target);
    return math.exp(weight * csvWeightMultiplier * x / target) / math.exp(weight * csvWeightMultiplier);
end

function GeneticSolverDna:ConvertDnaToBuild(
        targetNormalNodesCount,
        targetAscendancyNodesCount
)
    local countNormalNodesToAllocate = 0
    local countAscendancyNodesToAllocate = 0
    local normalNodesToAllocate = {}
    local ascendancyNodesToAllocate = {}
    for nodeId, v in pairs(self.nodesDna) do
        if v == nil then
            error("ibats in fitnessScore")
        end

        local node = self.build.spec.nodes[nodeId]

        if node.type ~= "Mastery" and node.path then
            if node.ascendancyName then
                countAscendancyNodesToAllocate = countAscendancyNodesToAllocate + 1
                ascendancyNodesToAllocate[countAscendancyNodesToAllocate] = node
            else
                countNormalNodesToAllocate = countNormalNodesToAllocate + 1
                normalNodesToAllocate[countNormalNodesToAllocate] = node
            end

        end
    end

    self.build.spec:ResetNodes()

    table.sort(normalNodesToAllocate, function(node1, node2)
        return node1.pathDist < node2.pathDist
    end)

    local normalNodesSelected = 0
    for _, node in pairs(normalNodesToAllocate) do
        if not node.alloc then
            for _, nodeLinked in pairs(node.linked) do
                if nodeLinked.alloc then
                    node.alloc = true
                    self.build.spec.allocNodes[node.id] = node

                    normalNodesSelected = normalNodesSelected + 1
                    break
                end
            end

            if not node.alloc then
                for _, pathNode in ipairs(node.path) do
                    if not pathNode.alloc then
                        pathNode.alloc = true
                        self.build.spec.allocNodes[pathNode.id] = pathNode

                        normalNodesSelected = normalNodesSelected + 1

                        if normalNodesSelected == targetNormalNodesCount then
                            break
                        end
                    end
                end

                if normalNodesSelected == targetNormalNodesCount then
                    break
                end
            else
                if normalNodesSelected == targetNormalNodesCount then
                    break
                end
            end
        end
    end

    local ascendancyNodesSelected = 0
    for _, node in pairs(ascendancyNodesToAllocate) do
        if not node.alloc then
            local wasLinked = false
            for _, nodeLinked in pairs(node.linked) do
                if nodeLinked.alloc then
                    node.alloc = true
                    self.build.spec.allocNodes[node.id] = node
                    wasLinked = true

                    ascendancyNodesSelected = ascendancyNodesSelected + 1
                    break
                end
            end

            if not wasLinked then
                for _, pathNode in ipairs(node.path) do
                    if not pathNode.alloc then
                        pathNode.alloc = true
                        self.build.spec.allocNodes[pathNode.id] = pathNode

                        ascendancyNodesSelected = ascendancyNodesSelected + 1

                        if ascendancyNodesSelected == targetAscendancyNodesCount then
                            break
                        end
                    end
                end

                if ascendancyNodesSelected == targetAscendancyNodesCount then
                    break
                end
            else
                if ascendancyNodesSelected == targetAscendancyNodesCount then
                    break
                end
            end
        end
    end

    return normalNodesSelected, ascendancyNodesSelected
end

function GeneticSolverDna:GetFitnessScore(targetNormalNodesCount,
                                          targetAscendancyNodesCount)
    if self.fitnessScore ~= nil then
        return self.fitnessScore
    end

    local usedNormalNodeCount, usedAscendancyNodeCount = self:ConvertDnaToBuild()

    local csvs = 1

    if usedNormalNodeCount > targetNormalNodesCount then
        csvs = csvs * self:CalcCsv(2 * targetNormalNodesCount - usedNormalNodeCount, usedNodeCountWeight, targetNormalNodesCount)
    elseif (usedNormalNodeCount < targetNormalNodesCount) then
        csvs = csvs * 1 + usedNodeCountFactor * math.log(targetNormalNodesCount + 1 - usedNormalNodeCount);
    end

    if usedAscendancyNodeCount > targetAscendancyNodesCount then
        csvs = csvs * self:CalcCsv(2 * targetAscendancyNodesCount - usedAscendancyNodeCount, usedNodeCountWeight, targetAscendancyNodesCount)
    elseif (usedAscendancyNodeCount < targetAscendancyNodesCount) then
        csvs = csvs * 1 + usedNodeCountFactor * math.log(targetAscendancyNodesCount + 1 - usedAscendancyNodeCount);
    end

    local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(self.build, "MAIN")
    calcs.perform(env)

    local stats = env.player.output

    csvs = csvs * self:CalcCsv(stats.TotalEHP, 1, 145000)
    csvs = csvs * self:CalcCsv(stats.Life, 1, 3000)
    if stats.SpellSuppressionChance then
        csvs = csvs * self:CalcCsv(stats.SpellSuppressionChance, 1, 100)
    else
        csvs = csvs * self:CalcCsv(0, 1, 100)
    end

    if not stats.LifeLeechGainRate then
        stats.LifeLeechGainRate = 0
    end

    if not stats.LifeRegenRecovery then
        stats.LifeRegenRecovery = 0
    end

    if stats.LifeLeechGainRate + stats.LifeRegenRecovery ~= 0 then
        csvs = csvs * self:CalcCsv((stats.LifeLeechGainRate + stats.LifeRegenRecovery) / stats.Life, 1, 0.5)
    else
        csvs = csvs * self:CalcCsv(0, 1, 0.5)
    end

    csvs = csvs * self:CalcCsv(stats.LightningResist, 0.9, 90)
    csvs = csvs * self:CalcCsv(stats.LightningResist, 1, 76)

    self.fitnessScore = csvs * stats.CombinedDPS

    return self.fitnessScore
end

