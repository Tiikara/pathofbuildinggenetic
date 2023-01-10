math.randomseed(os.clock())

local maxMutateClusterSize = 4

local GeneticSolverDna = newClass("GeneticSolverDna", function(self, build)
    self.build = build
    self.nodesDna = { }

    self.fitnessScore = -1
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

function GeneticSolverDna:GenerateFromCurrentBuild()
    for _, treeNode in pairs(self.build.spec.nodes) do
        if treeNode.alloc then
            self.nodesDna[treeNode.id] = 1
        else
            self.nodesDna[treeNode.id] = nil
        end
    end
end

function GeneticSolverDna:MutateWithCluster(treeNodesArray, nodesCount)
    local mutateClusterSize = math.random(1, maxMutateClusterSize)
    local startNum = math.random(1, nodesCount - mutateClusterSize - 1)

    for i = startNum, startNum + mutateClusterSize - 1 do
        local treeNode = treeNodesArray[i]

        if self.nodesDna[treeNode.id] == nil
        then
            self.nodesDna[treeNode.id] = 1
        else
            self.nodesDna[treeNode.id] = nil
        end
    end

    self.fitnessScore = -1
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

    self.fitnessScore = -1
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

function GeneticSolverDna:SelectionWithCluster(dna2, treeNodesArray, nodesCount)
    local crossoverStart = math.random(1, nodesCount);
    local crossoverEnd = math.random(1, nodesCount);

    if (crossoverStart > crossoverEnd) then
        return self:CrossoverDNA(dna2, self, crossoverEnd, crossoverStart, treeNodesArray);
    else
        return self:CrossoverDNA(self, dna2, crossoverStart, crossoverEnd, treeNodesArray);
    end
end

function GeneticSolverDna:CrossoverDNA(dna1, dna2, from, to, treeNodesArray)
    local newGeneticSolverDna = dna1:Clone()

    for i = from, to do
        local treeNode = treeNodesArray[i]

        newGeneticSolverDna.nodesDna[treeNode.id] = dna2.nodesDna[treeNode.id]
    end

    return newGeneticSolverDna
end

function GeneticSolverDna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    local countNormalNodesToAllocate = 0
    local countAscendancyNodesToAllocate = 0
    local normalNodesToAllocate = {}
    local ascendancyNodesToAllocate = {}
    for nodeId, v in pairs(self.nodesDna) do
        if v == nil then
            error("ibats in fitnessScore")
        end

        local node = self.build.spec.nodes[nodeId]

        if node.type ~= "Mastery" and node.path and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
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

    table.sort(ascendancyNodesToAllocate, function(node1, node2)
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

