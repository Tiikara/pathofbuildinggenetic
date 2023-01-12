
local function myerrorhandler( err )

    local file,err_file = io.open("error_thread.txt",'w')
    file:write(tostring(err))
    file:close()
end

local function test()
    -- Initialize PoB VM instance
    arg = { }

    dofile('HeadlessWrapper.lua')

    dofile('Classes/GeneticSolverFitnessFunction.lua')
    dofile('Classes/GeneticSolverDnaEncoder.lua')

    local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'

    local targetNormalNodesCount
    local targetAscendancyNodesCount

    local dnaEncoder

    local dnaProcessNumber = 0

    while true do
        local dnaCommand = path_of_building_genetic_solver.WorkerReceiveNextCommand()

        local solverDnaProcessNumber = path_of_building_genetic_solver.WorkerGetDnaProcessNumber()

        if dnaProcessNumber ~= solverDnaProcessNumber then
            dnaProcessNumber = solverDnaProcessNumber

            build.abortSave = true

            local f = assert(io.open("genetic_build.xml", "rb"))
            local xmlText = f:read("*all")
            f:close()

            main:SetMode("BUILD", false, "", xmlText)
            runCallback("OnFrame")

            dnaEncoder = new("GeneticSolverDnaEncoder", build)

            build.spec:ResetNodes()
            build.spec:BuildAllDependsAndPaths()

            targetNormalNodesCount = 107
            targetAscendancyNodesCount = 6
        end

        if dnaCommand.dnaData then
            local dna = dnaEncoder:CreateDnaFromDnaData(dnaCommand.dnaData)

            local fitnessScore = GeneticSolverFitnessFunction.CalculateAndGetFitnessScore(
                    dna,
                    targetNormalNodesCount,
                    targetAscendancyNodesCount
            )

            path_of_building_genetic_solver.WorkerSetResultDnaFitness(dnaCommand.handler, fitnessScore)
        end
    end
end


function GeneticSolverWorker(a)
    xpcall( test, myerrorhandler )
end
