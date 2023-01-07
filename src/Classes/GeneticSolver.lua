


local GeneticSolver = newClass("GeneticSolver", function(self, build)
    self.build = build
end)

function GeneticSolver:PrepareTreePaths()
    self.build.spec:ResetNodes()
    self.build.spec:BuildAllDependsAndPaths()
end

function GeneticSolver:Solve()
    local population = { }

    local populationSize = 2
    local iterationCount = 10

    local populationCount = 0

    for populationNum=1,populationSize do
        local dna = new("GeneticSolverDna", self.build)
        dna:Generate()
        populationCount = populationCount + 1
        population[populationCount] = dna
    end

    local dna = new("GeneticSolverDna", self.build)
    dna:GenerateFromCurrentBuild()
    populationCount = populationCount + 1
    population[populationCount] = dna

    self:PrepareTreePaths()

    table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

    for iterationNum=1,iterationCount do

        local countOfAdded = populationSize/2
        for addedNum=1,countOfAdded do
            local generatedDna = new("GeneticSolverDna", self.build)
            generatedDna:Generate()
            populationCount = populationCount + 1
            population[populationCount] = generatedDna
        end

        for populationNum=1,populationSize do
            local cupOfMutationChance = populationSize-populationNum
            local isMutated = math.random(populationSize) < cupOfMutationChance

            if isMutated then
                local mutatedDna = population[populationNum]:Clone()
                mutatedDna:Mutate(0.0001)

                populationCount = populationCount + 1
                population[populationCount] = mutatedDna
            end
        end
        table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

        local countOfFucks = populationSize / 2

        local bastards = self:makeHardFuck(population, populationCount, countOfFucks)

        for _,bastardDna in pairs(bastards) do
            populationCount = populationCount + 1
            population[populationCount] = bastardDna
        end

        table.sort(population, function(dna1, dna2) return dna1:GetFitnessScore() > dna2:GetFitnessScore()  end)

        local zbsPopulation = {}
        for populationNum=1,populationSize do
            zbsPopulation[populationNum] = population[populationNum]
        end

        population = zbsPopulation
        populationCount = populationSize
    end

    population[1]:ConvertDnaToBuild()
    self.build.spec:BuildAllDependsAndPaths()

    self.build.buildFlag = true
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


