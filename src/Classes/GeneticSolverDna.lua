math.randomseed(os.clock())

local calcs = LoadModule("Modules/Calcs")

local GeneticSolverDna = newClass("GeneticSolverDna", function(self, build)
    self.build = build
    self.nodesDna = { }
    self.fitnessScore = nil
    self.usedNodeCountWeight = 5
    self.usedNodeCountFactor = .0005
    self.csvWeightMultiplier = 10

end)

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
        local isMutated = math.random(100000) < probabilityToMutateGen * 1000000

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
        local isMine = 50 < math.random(100)

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
    return math.exp(weight * self.csvWeightMultiplier * x / target) / math.exp(weight * self.csvWeightMultiplier);
end

function GeneticSolverDna:ConvertDnaToBuild()
    local countNodesToAllocate = 0
    local nodesToAllocate = {}
    for nodeId, v in pairs(self.nodesDna) do
        if v == nil then
            error("ibats in fitnessScore")
        end

        local node = self.build.spec.nodes[nodeId]

        if node.type ~= "Mastery" and node.path then
            countNodesToAllocate = countNodesToAllocate + 1
            nodesToAllocate[countNodesToAllocate] = node

            if countNodesToAllocate == 100 then
                break
            end
        end
    end

    self.build.spec:ResetNodes()

    table.sort(nodesToAllocate, function(node1, node2)
        return node1.pathDist < node2.pathDist
    end)

    local nodesSelected = 0
    for _, node in pairs(nodesToAllocate) do
        if not node.alloc then
            local wasLinked = false
            for _, nodeLinked in pairs(node.linked) do
                if nodeLinked.alloc then
                    node.alloc = true
                    self.build.spec.allocNodes[node.id] = node
                    wasLinked = true

                    nodesSelected = nodesSelected + 1

                    break
                end
            end

            if not wasLinked then
                for _, pathNode in ipairs(node.path) do
                    if not pathNode.alloc then
                        pathNode.alloc = true
                        self.build.spec.allocNodes[pathNode.id] = pathNode

                        nodesSelected = nodesSelected + 1

                        if nodesSelected == 100 then
                            break
                        end
                    end
                end

                if nodesSelected == 100 then
                    break
                end
            else
                if nodesSelected == 100 then
                    break
                end
            end
        end
    end

    return nodesSelected
end

function GeneticSolverDna:GetFitnessScore()
    if self.fitnessScore ~= nil then
        return self.fitnessScore
    end

    local usedNodeCount = self:ConvertDnaToBuild()
    local totalPoints = 100

    local csvs = 1

    if usedNodeCount > totalPoints then
        csvs = csvs * self:CalcCsv(2 * totalPoints - usedNodeCount, self.usedNodeCountWeight, totalPoints)
    elseif (usedNodeCount < totalPoints) then
        csvs = csvs * 1 + self.usedNodeCountFactor * math.log(totalPoints + 1 - usedNodeCount);
    end

    local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(self.build, "MAIN")
    calcs.perform(env)

    local stats = env.player.output

    self.fitnessScore = csvs * stats.CombinedDPS * stats.CombinedDPS

    return self.fitnessScore
end

