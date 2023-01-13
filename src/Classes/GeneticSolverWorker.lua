function GeneticSolverWorker()
    -- Initialize PoB VM instance
    arg = { }

    dofile(ScriptAbsoluteWorkingDir .. 'HeadlessWrapper.lua')

    LoadModule('Classes/GeneticSolverFitnessFunction.lua')
    LoadModule('Classes/GeneticSolverDnaEncoder.lua')
    LoadModule('Classes/GeneticSolverDna.lua')

    local dnaEncoder
    local sessionParameters

    local sessionNumber = 0

    while true do
        local dnaCommand = GeneticWorkerReceiveNextCommand()

        local currentSessionNumber = GeneticWorkerGetSessionNumber()

        if sessionNumber ~= currentSessionNumber then
            sessionNumber = currentSessionNumber

            build.abortSave = true

            local f = assert(io.open("genetic_build.xml", "rb"))
            local xmlText = f:read("*all")
            f:close()

            main:SetMode("BUILD", false, "", xmlText)
            runCallback("OnFrame")

            dnaEncoder = new("GeneticSolverDnaEncoder", build)

            build.spec:ResetNodes()
            build.spec:BuildAllDependsAndPaths()

            sessionParameters = GeneticWorkerGetSessionParameters()
        end

        if dnaCommand.dnaData then
            local dna = dnaEncoder:CreateDnaFromDnaData(dnaCommand.dnaData)

            local fitnessScore = GeneticSolverFitnessFunction.CalculateAndGetFitnessScore(
                    dna,
                    sessionParameters.targetNormalNodesCount,
                    sessionParameters.targetAscendancyNodesCount
            )

            GeneticWorkerSetResultToHandler(dnaCommand.handler, fitnessScore)
        end
    end
end
