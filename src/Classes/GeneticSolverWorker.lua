-- Initialize PoB VM instance
arg = { }

dofile(ScriptAbsoluteWorkingDir .. 'HeadlessWrapper.lua')

local calcs = LoadModule("Modules/Calcs")

function GeneticWorkerInitializeSession()
    build.abortSave = true

    local f = assert(io.open("genetic_build.xml", "rb"))
    local xmlText = f:read("*all")
    f:close()

    main:SetMode("BUILD", false, "", xmlText)
    runCallback("OnFrame")
end

function GeneticWorkerCalculateStats()
    local env, _, _, _ = calcs.initEnv(build, "MAIN")
    calcs.perform(env)
    return env
end
