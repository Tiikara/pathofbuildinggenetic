math.randomseed(os.clock())

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

    self.build.spec:ResetNodes()

    table.sort(normalNodesToAllocate, function(node1, node2)
        return node1.pathDist < node2.pathDist
    end)

    table.sort(ascendancyNodesToAllocate, function(node1, node2)
        return node1.pathDist < node2.pathDist
    end)

    local normalNodesSelected = 0
    self.masteryNodesSelectedEffectsNum = { }
    for _, node in pairs(normalNodesToAllocate) do
        if not node.alloc then
            for _, nodeLinked in pairs(node.linked) do
                if nodeLinked.alloc then
                    self:AllocNode(node)

                    normalNodesSelected = normalNodesSelected + 1
                    break
                end
            end

            if not node.alloc then
                for _, pathNode in ipairs(node.path) do
                    if not pathNode.alloc then
                        self:AllocNode(pathNode)

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

function GeneticSolverDna:AllocNode(node)
    if node.type == "Mastery" then
        self:TryAllocMastery(node)
    else
        node.alloc = true
        self.build.spec.allocNodes[node.id] = node
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
            self.build.spec.masterySelections[node.id] = effect
        end
    end
end
