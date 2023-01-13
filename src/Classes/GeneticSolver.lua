
local lanesIsInitialized = false

local GeneticSolver = newClass("GeneticSolver", function(self, build)
    self.build = build

    if not lanesIsInitialized then
        lanes = require "lanes"
        lanes.configure()
        lanesIsInitialized = true
    end

    local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'

    self.backendGeneticSolver = path_of_building_genetic_solver.CreateGeneticSolver()

    self.backendGeneticSolver:CreateWorkers(22)
end)

function GeneticSolver:StartSolve()
    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    if self.backendGeneticSolver:IsProgress() then
        error("Cannot start process. Already started")
    end

    local maxGenerationsCount = 5000
    local stopGenerationEps = 100
    local countGenerationsMutateEps = 5
    local populationMaxGenerationSize = 5000

    self.targetNormalNodesCount = 107
    self.targetAscendancyNodesCount = 6

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    self.dnaEncoder = new("GeneticSolverDnaEncoder", self.build)

    self.backendGeneticSolver:StartSolve(
            maxGenerationsCount,
            stopGenerationEps,
            countGenerationsMutateEps,
            populationMaxGenerationSize,
            self.dnaEncoder.treeNodesCount,
            self.dnaEncoder.mysteriesNodesCount,
            self.targetNormalNodesCount,
            self.targetAscendancyNodesCount
    )
end

function GeneticSolver:GetBestDnaNumber()
    return self.backendGeneticSolver:GetBestDnaNumber()
end

function GeneticSolver:IsProgress()
    return self.backendGeneticSolver:IsProgress()
end


function GeneticSolver:GenerateBuildFromCurrentBestResult()
    local bestDnaData = self.backendGeneticSolver:GetBestDnaData()

    local bestDna = self.dnaEncoder:CreateDnaFromDnaData(bestDnaData)

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    bestDna:ConvertDnaToBuild(self.targetNormalNodesCount, self.targetAscendancyNodesCount)
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true
end
