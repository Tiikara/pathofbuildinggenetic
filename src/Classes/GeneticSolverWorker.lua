
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

    local path_of_building_genetic_solver = require 'path_of_building_genetic_solver'

    local targetNormalNodesCount
    local targetAscendancyNodesCount

    local treeNodesArray
    local treeNodesCount

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

            --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
            --local dbg = require('emmy_core')
            --dbg.tcpListen('localhost', 9966)
            --dbg.waitIDE()

            treeNodesCount = 0
            treeNodesArray = {}

            for _,treeNode in pairs(build.spec.nodes) do
                treeNodesCount = treeNodesCount + 1
                treeNodesArray[treeNodesCount] = treeNode
            end

            table.sort(treeNodesArray, function(treeNode1, treeNode2) return treeNode1.id > treeNode2.id end)

            build.spec:ResetNodes()
            build.spec:BuildAllDependsAndPaths()

            targetNormalNodesCount = 98
            targetAscendancyNodesCount = 6
        end

        if dnaCommand.dnaData then
            local dna = new("GeneticSolverDna", build)

            dna:FromDnaData(dnaCommand.dnaData, treeNodesArray)

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
