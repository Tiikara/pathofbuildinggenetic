
local GeneticSolverDnaEncoder = newClass("GeneticSolverDnaEncoder", function(self, build)
    self.build = build

    self.treeNodesArray = {}
    self.treeNodesCount = 0

    self.mysteriesNodesArray = {}
    self.mysteriesNodesCount = 0

    for _,treeNode in pairs(self.build.spec.nodes) do
        self.treeNodesCount = self.treeNodesCount + 1
        self.treeNodesArray[self.treeNodesCount] = treeNode

        if treeNode.type == 'Mastery' then
            local effectCount = 0
            local effects = { }
            for treeNodeMasteryEffectsNum, effect in ipairs(treeNode.masteryEffects) do
                effectCount = effectCount + 1
                effects[effectCount] = {
                    treeNodeMasteryEffectsNum = treeNodeMasteryEffectsNum,
                    effect = effect
                }
            end

            table.sort(effects, function(effect1, effect2) return effect1.effect.effect > effect2.effect.effect end)

            self.mysteriesNodesCount = self.mysteriesNodesCount + 1
            self.mysteriesNodesArray[self.mysteriesNodesCount] = {
                node = treeNode,
                effects = effects,
                effectCount = effectCount
            }
        end
    end

    -- Make sure that the nodes are sorted to be synchronized
    table.sort(self.treeNodesArray, function(treeNode1, treeNode2) return treeNode1.id > treeNode2.id end)
    table.sort(self.mysteriesNodesArray, function(node1, node2) return node1.node.id > node2.node.id end)
end)

function GeneticSolverDnaEncoder:CreateDnaFromDnaData(dnaData)
    local dna = new("GeneticSolverDna", self.build)

    for number, _ in pairs(dnaData.treeNodesNumbers) do
        local treeNode = self.treeNodesArray[number]

        dna.nodesDna[treeNode.id] = 1
    end

    for nodeNumber, masteryEffectNumbers in pairs(dnaData.mysteriesNodesEffectsInfo) do
        local masteryNodeInfo = self.mysteriesNodesArray[nodeNumber]

        local effectsCount = 0
        local effects = { }
        for effectNumber, _ in pairs(masteryEffectNumbers) do
            local effectInfo = masteryNodeInfo.effects[effectNumber]

            if not effectInfo then
                break
            end

            effectsCount = effectsCount + 1
            effects[effectsCount] = effectInfo.effect
        end

        dna.masteriesDna[masteryNodeInfo.node.id] = effects
    end

    return dna
end
