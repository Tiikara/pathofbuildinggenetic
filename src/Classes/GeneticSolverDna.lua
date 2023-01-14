local GeneticSolverDna = newClass("GeneticSolverDna", function(self, build)
    self.build = build
    self.nodesDna = { }
    self.masteriesDna = { }
end)

function GeneticSolverDna:GenerateFromCurrentBuild()
    for _, treeNode in pairs(self.build.spec.nodes) do
        if treeNode.alloc then
            self.nodesDna[treeNode.id] = 1
        else
            self.nodesDna[treeNode.id] = nil
        end
    end
end

-- Ensure you run
--    self.build.spec:ResetNodes()
--    self.build.spec:BuildAllDependsAndPaths()
-- before run this method
function GeneticSolverDna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    self:ResetNodes()

    local countNormalNodesToAllocate = 0
    local countAscendancyNodesToAllocate = 0
    local normalNodesToAllocate = {}
    local ascendancyNodesToAllocate = {}
    for nodeId, v in pairs(self.nodesDna) do
        if v == nil then
            error("ibats in fitnessScore")
        end

        local node = self.build.spec.nodes[nodeId]

        if node.path and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
            if node.ascendancyName then
                countAscendancyNodesToAllocate = countAscendancyNodesToAllocate + 1
                ascendancyNodesToAllocate[countAscendancyNodesToAllocate] = node
            else
                countNormalNodesToAllocate = countNormalNodesToAllocate + 1
                normalNodesToAllocate[countNormalNodesToAllocate] = node
            end

        end
    end

    table.sort(ascendancyNodesToAllocate, function(node1, node2)
        return node1.pathDist < node2.pathDist
    end)

    local normalNodesSelected = 0
    self.masteryNodesSelectedEffectsNum = { }

    for _,node in pairs(self.build.spec.nodes) do
        if not node.ascendancyName then
            node.pathDist = (node.alloc and not node.dependsOnIntuitiveLeapLike) and 0 or 1000
            node.path = nil
            if node.isJewelSocket or node.expansionJewel then
                node.distanceToClassStart = 0
            end
        end
    end

    for _, node in pairs(self.build.spec.allocNodes) do
        if not node.dependsOnIntuitiveLeapLike then
            self.build.spec:BuildPathFromNode(node)
            if node.isJewelSocket or node.expansionJewel then
                self.build.spec:SetNodeDistanceToClassStart(node)
            end
        end
    end

    while countNormalNodesToAllocate > 0 do
        local smallestNode
        local smallestNodeNum
        for number, node in pairs(normalNodesToAllocate) do
            if node.alloc then
                normalNodesToAllocate[number] = nil
                countNormalNodesToAllocate = countNormalNodesToAllocate - 1
            else
                if smallestNode == nil or smallestNode.pathDist > node.pathDist then
                    smallestNode = node
                    smallestNodeNum = number
                end
            end
        end

        if smallestNode == nil then
            break
        end

        countNormalNodesToAllocate = countNormalNodesToAllocate - 1
        normalNodesToAllocate[smallestNodeNum] = nil

        for _, pathNode in ipairs(smallestNode.path) do
            self:AllocNode(pathNode)

            normalNodesSelected = normalNodesSelected + 1

            if normalNodesSelected == targetNormalNodesCount then
                break
            end
        end

        if normalNodesSelected == targetNormalNodesCount then
            break
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

function GeneticSolverDna:ResetNodes()
    self.build.spec:ResetNodes()
end

function GeneticSolverDna:AllocNode(node)
    if node.type == "Mastery" then
        self:TryAllocMastery(node)
    else
        node.alloc = true
        self.build.spec.allocNodes[node.id] = node

        self.build.spec:BuildPathFromNode(node)
    end
end

function GeneticSolverDna:TryAllocMastery(node)
    local effects = self.masteriesDna[node.id]

    if effects then
        if not self.masteryNodesSelectedEffectsNum[node.id] then
            self.masteryNodesSelectedEffectsNum[node.id] = 1
        else
            self.masteryNodesSelectedEffectsNum[node.id] = self.masteryNodesSelectedEffectsNum[node.id] + 1
        end

        local effect = effects[self.masteryNodesSelectedEffectsNum[node.id]]

        if effect then
            node.alloc = true
            self.build.spec.allocNodes[node.id] = node
            self.build.spec.masterySelections[node.id] = effect.effect

            node.sd = effect.sd
            node.allMasteryOptions = false
            node.reminderText = { "Tip: Right click to select a different effect" }
            self.build.spec.tree:ProcessStats(node)

            self.build.spec:BuildPathFromNode(node)
        end
    end
end
