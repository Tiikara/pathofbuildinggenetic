local GeneticSolver = newClass("GeneticSolver", function(self, build)
    self.build = build

    local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'
    self.backendGeneticSolver = path_of_building_genetic_solver.CreateGeneticSolver()
end)

function GeneticSolver:AllocateWorkersIfNotExists()
    if not self.workersAllocated then
        self.backendGeneticSolver:CreateWorkers()
        self.workersAllocated = true
    end
end

function GeneticSolver:StartSolve(maxGenerationsCount,
                                  stopGenerationEps,
                                  countGenerationsMutateEps,
                                  populationMaxGenerationSize,
                                  targetNormalNodesCount,
                                  targetAscendancyNodesCount,
                                  targetStats,
                                  maximizeStats)
    if self.backendGeneticSolver:IsProgress() then
        error("Cannot start process. Already started")
    end

    self:AllocateWorkersIfNotExists()

    self.targetNormalNodesCount = targetNormalNodesCount
    self.targetAscendancyNodesCount = targetAscendancyNodesCount

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'

    self.dnaEncoder = path_of_building_genetic_solver.CreateDnaEncoder(self.build)

    self.backendGeneticSolver:StartSolve(
            maxGenerationsCount,
            stopGenerationEps,
            countGenerationsMutateEps,
            populationMaxGenerationSize,
            self.dnaEncoder:GetTreeNodesCount(),
            self.dnaEncoder:GetMasteryCount(),
            self.targetNormalNodesCount,
            self.targetAscendancyNodesCount,
            targetStats,
            maximizeStats
    )
end

function GeneticSolver:StopSolve()
    self.backendGeneticSolver:StopSolve()
end

function GeneticSolver:GetBestDnaNumber()
    return self.backendGeneticSolver:GetBestDnaNumber()
end

function GeneticSolver:IsProgress()
    return self.backendGeneticSolver:IsProgress()
end

function GeneticSolver:GetCurrentGenerationNumber()
    return self.backendGeneticSolver:GetCurrentGenerationNumber()
end

function GeneticSolver:GenerateBuildFromCurrentBestResult()
    local bestDna = self.backendGeneticSolver:GetBestDna()

    self.dnaEncoder:ConvertDnaToBuild(self.build, bestDna, self.targetNormalNodesCount, self.targetAscendancyNodesCount);

    self.build.spec:BuildAllDependsAndPaths();

    self.build.buildFlag = true
end
