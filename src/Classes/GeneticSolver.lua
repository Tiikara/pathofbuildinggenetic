
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
    for i=1,15 do
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

    local maxGenerationsCount = 10000
    local stopGenerationEps = 300
    local countGenerationsMutateEps = 50
    local populationMaxGenerationSize = 5000

    local targetNormalNodesCount = 107
    local targetAscendancyNodesCount = 6

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    local dnaEncoder = new("GeneticSolverDnaEncoder", self.build)

    local bestDnaData = path_of_building_genetic_solver.StartGeneticSolver(
            maxGenerationsCount,
            stopGenerationEps,
            countGenerationsMutateEps,
            populationMaxGenerationSize,
            dnaEncoder.treeNodesCount,
            dnaEncoder.mysteriesNodesCount
    )

    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    local bestDna = dnaEncoder:CreateDnaFromDnaData(bestDnaData)

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    bestDna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true
end
