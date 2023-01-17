function GeneticSolverWorker()
    -- Initialize PoB VM instance
    arg = { }

    dofile(ScriptAbsoluteWorkingDir .. 'HeadlessWrapper.lua')

    LoadModule('Classes/GeneticSolverFitnessFunction.lua')

    local dnaEncoder
    local sessionParameters
    local fitnessFunction

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

            dnaEncoder = GeneticWorkerCreateDnaEncoder(build)
            fitnessFunction = new("GeneticSolverFitnessFunction", build)

            sessionParameters = GeneticWorkerGetSessionParameters()
        end

        if dnaCommand.handler then
            local dnaConvertResult = dnaEncoder:ConvertDnaCommandHandlerToBuild(build,
                    dnaCommand.handler,
                    sessionParameters.targetNormalNodesCount,
                    sessionParameters.targetAscendancyNodesCount
            );

            local fitnessScore = fitnessFunction:CalculateAndGetFitnessScore(
                    dnaConvertResult,
                    sessionParameters.targetNormalNodesCount,
                    sessionParameters.targetAscendancyNodesCount,
                    sessionParameters.targetStats,
                    sessionParameters.maximizeStats
            )

            GeneticWorkerSetResultToHandler(dnaCommand.handler, fitnessScore)
        end
    end
end
