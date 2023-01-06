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
    local countIdsNodesToAllocate = 0
    local idsNodesLeftToAllocate = {}
    for nodeId, v in pairs(self.nodesDna) do
        if v == nil then
            error("ibats in fitnessScore")
        end

        local node = self.build.spec.nodes[nodeId]

        if node.type ~= "Mastery" then
            idsNodesLeftToAllocate[nodeId] = 1
            countIdsNodesToAllocate = countIdsNodesToAllocate + 1
        end
    end

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    local nodesSelected = 0

    while countIdsNodesToAllocate > 0 do
        local closestNode = nil

        for nodeId in pairs(idsNodesLeftToAllocate) do
            if closestNode == nil then
                closestNode = self.build.spec.nodes[nodeId]
            else
                if closestNode.pathDist > self.build.spec.nodes[nodeId].pathDist then
                    closestNode = self.build.spec.nodes[nodeId]
                end
            end
        end

        idsNodesLeftToAllocate[closestNode.id] = nil

        if closestNode.path and not closestNode.alloc then
            --self.build.spec:AllocNode(closestNode, nil)
            for _, pathNode in ipairs(closestNode.path) do
                pathNode.alloc = true
                self.build.spec.allocNodes[pathNode.id] = pathNode

                nodesSelected = nodesSelected + 1

                if nodesSelected == 100 then
                    break
                end
            end

            self.build.spec:BuildAllDependsAndPaths()

            if nodesSelected == 100 then
                break
            end
        end

        countIdsNodesToAllocate = countIdsNodesToAllocate - 1
    end
end

function GeneticSolverDna:GetFitnessScore()
    if self.fitnessScore ~= nil then
        return self.fitnessScore
    end

    self:ConvertDnaToBuild()

    local usedNodeCount = self.build.spec:CountAllocNodes()
    local totalPoints = 100

    local csvs = 1

    if usedNodeCount > totalPoints then
        csvs = csvs * self:CalcCsv(2 * totalPoints - usedNodeCount, self.usedNodeCountWeight, totalPoints)
    elseif (usedNodeCount < totalPoints) then
        csvs = csvs * 1 + self.usedNodeCountFactor * math.log(totalPoints + 1 - usedNodeCount);
    end

    local stats = calcs.buildOutput(self.build, "CALCS").player.output

    self.fitnessScore = csvs * stats.CombinedDPS * stats.CombinedDPS

    return self.fitnessScore
end

