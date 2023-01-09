
function GeneticSolverWorker(linda)
    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x86/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    -- Run new VM instance
    arg = { }

    dofile('HeadlessWrapper.lua')

    dofile('Classes/GeneticSolverFitnessFunction.lua')

    linda:send("GeneticSolverWorkerInitialized", 1)

    --package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/223.8214.52.plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
    --local dbg = require('emmy_core')
    --dbg.tcpListen('localhost', 9966)
    --dbg.waitIDE()

    local curBuildNum = 0

    while true do
        local _, dnaTable = linda:receive("GeneticSolverDnas")

        if dnaTable == nil then
            break
        end

        local buildNumLinda = linda:get("GeneticSolverBuildNum")

        if buildNumLinda ~= curBuildNum then
            curBuildNum = buildNumLinda

            build.abortSave = true

            local f = assert(io.open("genetic_build.xml", "rb"))
            local xmlText = f:read("*all")
            f:close()

            main:SetMode("BUILD", false, "", xmlText)
            runCallback("OnFrame")

            build.spec:ResetNodes()
            build.spec:BuildAllDependsAndPaths()
        end

        local id = dnaTable.id
        dnaTable.id = nil

        local dna = new("GeneticSolverDna", build)

        dna:InitFromTable(dnaTable)

        local res = {
            fitnessScore = GeneticSolverFitnessFunction.CalculateAndGetFitnessScore(
                    dna,
                    101,
                    6
            ),
            id = id
        }

        linda:send("GeneticSolverDnasFitnessScores", res)
    end

end
