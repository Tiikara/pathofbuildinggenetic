
local GeneticSolverDnaEncoder = newClass("GeneticSolverDnaEncoder", function(self, build)
    self.build = build

    self.treeNodesArray = {}
    self.treeNodesCount = 0
    for _,treeNode in pairs(self.build.spec.nodes) do
        self.treeNodesCount = self.treeNodesCount + 1
        self.treeNodesArray[self.treeNodesCount] = treeNode
    end

    -- Make sure that the nodes are sorted to be synchronized
    table.sort(self.treeNodesArray, function(treeNode1, treeNode2) return treeNode1.id > treeNode2.id end)
end)

function GeneticSolverDnaEncoder:CreateDnaFromDnaData(dnaData)
    local dna = new("GeneticSolverDna", self.build)

    for index,_ in pairs(dnaData.treeNodesIndexes) do
        local treeNode = self.treeNodesArray[index]

        dna.nodesDna[treeNode.id] = 1
    end

    return dna
end
