
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
    for i=1,21 do
        fitnessWorkers[i] = lanes.gen("*", GeneticSolverWorker)(self.linda)

        --self.linda:receive("GeneticSolverWorkerInitialized")
    end

    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x86/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()
end)

function GeneticSolver:Solve()
    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x86/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    local targetNormalNodesCount = 101
    local targetAscendancyNodesCount = 6

    local xmlText = self.build:SaveDB("genetic_build.xml")
    local file = io.open("genetic_build.xml", "w+")
    file:write(xmlText)
    file:close()

    self.linda:set("GeneticSolverBuildNum", self.buildNum)
    self.buildNum = self.buildNum + 1

    local population = { }

    local populationMaxGenerationSize = 5000
    local iterationCount = 100

    local populationCount = 0

    for populationNum=1, populationMaxGenerationSize do
        local dna = new("GeneticSolverDna", self.build)
        dna:Generate()
        populationCount = populationCount + 1
        population[populationCount] = dna
    end

    local dna = new("GeneticSolverDna", self.build)
    dna:GenerateFromCurrentBuild()
    populationCount = populationCount + 1
    population[populationCount] = dna

    self:CalcFitnessScoreWithWorkers(population, 1, populationCount)

    table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

    for iterationNum=1,iterationCount do

        local startFromFitnessScore = populationCount + 1

        local countOfAdded = populationMaxGenerationSize /2
        for addedNum=1,countOfAdded do
            local generatedDna = new("GeneticSolverDna", self.build)
            generatedDna:Generate()
            populationCount = populationCount + 1
            population[populationCount] = generatedDna
        end

        for populationNum=1, populationMaxGenerationSize do
            local cupOfMutationChance = populationMaxGenerationSize -populationNum
            local isMutated = math.random(populationMaxGenerationSize) < cupOfMutationChance

            if isMutated then
                local mutatedDna = population[populationNum]:Clone()
                mutatedDna:Mutate(0.0001)

                populationCount = populationCount + 1
                population[populationCount] = mutatedDna
            end
        end

        self:CalcFitnessScoreWithWorkers(population, startFromFitnessScore, populationCount)

        table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

        local countOfFucks = populationMaxGenerationSize / 2

        local bastards = self:makeHardFuck(population, populationCount, countOfFucks)

        startFromFitnessScore = populationCount + 1

        for _,bastardDna in pairs(bastards) do
            populationCount = populationCount + 1
            population[populationCount] = bastardDna
        end

        self:CalcFitnessScoreWithWorkers(population, startFromFitnessScore, populationCount)

        table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

        local zbsPopulation = {}
        for populationNum=1, populationMaxGenerationSize do
            zbsPopulation[populationNum] = population[populationNum]
        end

        population = zbsPopulation
        populationCount = populationMaxGenerationSize
    end

    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()

    population[1]:ConvertDnaToBuild(targetNormalNodesCount, targetAscendancyNodesCount)
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true
end

function GeneticSolver:StopWorkers()
    for _,worker in pairs(self.fitnessWorkers) do
        worker:cancel({force_kill_bool = true})
    end

    for _,worker in pairs(self.fitnessWorkers) do
        worker:join()
    end
end

function GeneticSolver:makeHardFuck(population, populationCount, countOfFucks)
    local bastards = {}

    for fuckNum=1,countOfFucks do
        local numberOfSlave = math.floor(populationCount * math.random())+1
        if numberOfSlave == fuckNum then
            numberOfSlave = numberOfSlave + 1
        end
        local masterDna = population[fuckNum]
        local slaveDna = population[numberOfSlave]

        local bastardDna = masterDna:Selection(slaveDna)

        bastards[fuckNum] = bastardDna
    end

    return bastards
end

function GeneticSolver:CalcFitnessScoreWithWorkers(population, from, to)
    for i=from, to do
        local dna = population[i]:AsTable()

        dna.id = i

        self.linda:send("GeneticSolverDnas", dna)

        dna.id = nil
    end

    for i=from,to do
        local _, scoreInfo = self.linda:receive("GeneticSolverDnasFitnessScores")

        population[scoreInfo.id].fitnessScore = scoreInfo.fitnessScore
    end
end
