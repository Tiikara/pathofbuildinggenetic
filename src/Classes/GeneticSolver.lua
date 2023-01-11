
dofile('Classes/GeneticSolverWorker.lua')

local lanesIsInitialized = false

local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'

local GeneticSolver = newClass("GeneticSolver", function(self, build)
    self.build = build
    self.buildNum = 1

    if not lanesIsInitialized then
        lanes = require "lanes"
        lanes.configure()
        lanesIsInitialized = true
    end

    path_of_building_genetic_solver.InitGeneticSolver()

    self.fitnessWorkers = { }
    for i=1,22 do
        self.fitnessWorkers[i] = lanes.gen("*", GeneticSolverWorker)()

        --self.linda:receive("GeneticSolverWorkerInitialized")
    end

    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x86/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()
end)

function GeneticSolver:Solve()
    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    local maxGenerationsCount = 50000
    local stopGenerationEps = 200
    local countGenerationsMutateEps = 50
    local populationMaxGenerationSize = 5000

    local targetNormalNodesCount = 98
    local targetAscendancyNodesCount = 6

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    local treeNodesArray = {}
    local treeNodesCount = 0

    for _,treeNode in pairs(self.build.spec.nodes) do
        treeNodesCount = treeNodesCount + 1
        treeNodesArray[treeNodesCount] = treeNode
    end

    -- Make sure that the nodes are sorted to synchronize with the threads
    table.sort(treeNodesArray, function(treeNode1, treeNode2) return treeNode1.id > treeNode2.id end)

    local resultDnaData = path_of_building_genetic_solver.StartGeneticSolver(
            maxGenerationsCount,
            stopGenerationEps,
            countGenerationsMutateEps,
            populationMaxGenerationSize,
            treeNodesCount
    )

    local bestDna = new("GeneticSolverDna", self.build)

    bestDna:FromDnaData(resultDnaData, treeNodesArray)

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    bestDna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true
end

function GeneticSolver:GeneratePopulationDistribution()
    local dnas = { }
    local dnaCount = 0

    for _, treeNode in pairs(self.build.spec.nodes) do
        local dna = new("GeneticSolverDna", self.build)
        dna.nodesDna[treeNode.id] = 1

        dnaCount = dnaCount + 1
        dnas[dnaCount] = dna
    end

    return dnas, dnaCount
end
