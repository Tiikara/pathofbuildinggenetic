
dofile('Classes/GeneticSolverWorker.lua')

local lanesIsInitialized = false

local GeneticSolver = newClass("GeneticSolver", function(self, build)
    self.build = build
    self.buildNum = 1

    if not lanesIsInitialized then
        lanes = require "lanes"
        lanes.configure()
        lanesIsInitialized = true
    end

    self.linda = lanes.linda()

    local fitnessWorkers = { }
    for i=1,22 do
        fitnessWorkers[i] = lanes.gen("*", GeneticSolverWorker)(self.linda)

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

    local generationsCount = 50000
    local stopGenerationEps = 100
    local populationMaxGenerationSize = 5000

    local targetNormalNodesCount = 98
    local targetAscendancyNodesCount = 6

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    self.linda:set("GeneticSolverBuildNum", self.buildNum)
    self.buildNum = self.buildNum + 1

    local population
    local populationCount

    population, populationCount = self:GeneratePopulationDistribution()

    local dna = new("GeneticSolverDna", self.build)
    dna:GenerateFromCurrentBuild()
    populationCount = populationCount + 1
    population[populationCount] = dna

    self:CalcFitnessScoreWithWorkers(population, 1, populationCount)

    table.sort(population, function(dna1, dna2) return dna1.fitnessScore > dna2.fitnessScore  end)

    local treeNodesArray = {}
    local treeNodesCount = 0

    for _,treeNode in pairs(self.build.spec.nodes) do
        treeNodesCount = treeNodesCount + 1
        treeNodesArray[treeNodesCount] = treeNode
    end

    local bestDna = population[1]:Clone()
    local countGenerationsWithBest = 0

    for _=1, generationsCount do

        local mutatedDnas = {}

        for populationNum=1, populationCount do
            local mutatedDna = population[populationNum]:Clone()
            mutatedDna:MutateWithCluster(treeNodesArray, treeNodesCount)

            mutatedDnas[populationNum] = mutatedDna
        end

        self:CalcFitnessScoreWithWorkers(mutatedDnas, 1, populationCount)

        local curPopulationCount = populationCount
        for populationNum=1, curPopulationCount do
            local mutatedDna = mutatedDnas[populationNum]

            populationCount = populationCount + 1
            population[populationCount] = mutatedDna
        end

        table.sort(population, function(dna1, dna2) return dna1.fitnessScore > dna2.fitnessScore  end)

        local countOfFucks = populationMaxGenerationSize / 2
        if countOfFucks > populationCount then
            countOfFucks = populationCount
        end

        local bastards = self:makeHardFuck(population, populationCount, countOfFucks, treeNodesArray, treeNodesCount)

        self:CalcFitnessScoreWithWorkers(bastards, 1, countOfFucks)

        local zbsPopulation = {}
        local zbsPopulationCount = 0
        for populationNum=1, populationCount do
            zbsPopulationCount = zbsPopulationCount + 1
            zbsPopulation[zbsPopulationCount] = population[populationNum]

            if zbsPopulationCount == populationMaxGenerationSize / 2 then
                break
            end
        end

        for _,bastardDna in pairs(bastards) do
            zbsPopulationCount = zbsPopulationCount + 1
            zbsPopulation[zbsPopulationCount] = bastardDna
        end

        table.sort(zbsPopulation, function(dna1, dna2) return dna1.fitnessScore > dna2.fitnessScore  end)

        population = zbsPopulation
        populationCount = zbsPopulationCount

        if population[1].fitnessScore > bestDna.fitnessScore then
            bestDna = population[1]:Clone()
            countGenerationsWithBest = 0
        else
            countGenerationsWithBest = countGenerationsWithBest + 1
        end

        if countGenerationsWithBest == stopGenerationEps then
            for populationNum=1, populationCount do
                population[populationNum]:Mutate(0.0001)
            end
        end

        if countGenerationsWithBest == stopGenerationEps * 2 then
            break
        end
    end

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    bestDna:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true

    for populationNum=1, populationCount do
        ConPrintf(populationNum .. ": " .. population[populationNum].fitnessScore .. "\n")
    end
end

function GeneticSolver:StopWorkers()
    for _,worker in pairs(self.fitnessWorkers) do
        worker:cancel({force_kill_bool = true})
    end

    for _,worker in pairs(self.fitnessWorkers) do
        worker:join()
    end
end

function GeneticSolver:makeHardFuck(population, populationCount, countOfFucks, treeNodesArray, treeNodesCount)
    local bastards = {}

    for fuckNum=1,countOfFucks do
        local numberOfSlave = math.random(1, populationCount - 1)
        if numberOfSlave == fuckNum then
            numberOfSlave = numberOfSlave + 1
        end
        local masterDna = population[fuckNum]
        local slaveDna = population[numberOfSlave]

        local bastardDna = masterDna:SelectionWithCluster(slaveDna, treeNodesArray, treeNodesCount)

        bastards[fuckNum] = bastardDna
    end

    return bastards
end

function GeneticSolver:CalcFitnessScoreWithWorkers(dnas, from, to)
    for i=from, to do
        local dna = dnas[i]:AsTable()

        dna.id = i

        self.linda:send("GeneticSolverDnas", dna)

        dna.id = nil
    end

    for _=from,to do
        local _, scoreInfo = self.linda:receive("GeneticSolverDnasFitnessScores")

        dnas[scoreInfo.id].fitnessScore = scoreInfo.fitnessScore
    end
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
