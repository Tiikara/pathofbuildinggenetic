local OptimizationTabClass = newClass("OptimizationTab", "ControlHost", function(self, build)
    self.ControlHost()

    self.build = build

    self.maxGenerationCount = 5000
    self.stopGenerationEps = 100
    self.countGenerationsMutateEps = 20
    self.populationMaxGenerationSize = 5000

    self.targetNormalNodesCount = 100
    self.targetAscendancyNodesCount = 6

    self.selectedStatNumber = 1
    self.currentStatWeight = 1
    self.currentStatTarget = 0
    self.currentStatIsMaximize = false

    self.targetStats = { }

    self.anchorControls = new("Control", nil, 0, 0, 0, 20)

    self.controls.start = new("ButtonControl", { "LEFT", self.anchorControls, "LEFT" }, 0, 0, 200, 30, "Start optimization", function()
        if not self.geneticSolver then
            self.geneticSolver = new("GeneticSolver", self.build)
        end

        self.geneticSolver:StartSolve(
                self.maxGenerationCount,
                self.stopGenerationEps,
                self.countGenerationsMutateEps,
                self.populationMaxGenerationSize
        )
    end)
    self.controls.start.locked = function()
        return self.geneticSolver and self.geneticSolver:IsProgress()
    end

    self.controls.geneticOptionSection = new("SectionControl", {"TOPLEFT", self.controls.start, "BOTTOMLEFT"}, 0, 60, 400, 120, "Genetic Options")
    local prevControlGeneticOptionSection = self.controls.geneticOptionSection

    --
    self.controls.maxGenerationCount = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "TOPLEFT" }, 8 + 200, 20, 90, 18, tostring(self.maxGenerationCount), nil, "%D", 7, function(buf, placeholder)
        self.maxGenerationCount = tonumber(buf)
    end)
    self.controls.maxGenerationCount.tooltipText = function()
        return "Max generations used by genetic algorithm"
    end
    self.controls.controlMaxGenerationCountLabel = new("LabelControl", {"RIGHT", self.controls.maxGenerationCount, "LEFT"}, -4, 0, 0, 14, "Max generations number:")
    prevControlGeneticOptionSection = self.controls.maxGenerationCount
    --
    self.controls.stopGenerationEps = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.stopGenerationEps), nil, "%D", 7, function(buf, placeholder)
        self.stopGenerationEps = tonumber(buf)
    end)
    self.controls.stopGenerationEps.tooltipText = function()
        return "The number of generations in which the build does not improve, after which the algorithm stops"
    end
    self.controls.stopGenerationEpsLabel = new("LabelControl", {"RIGHT", self.controls.stopGenerationEps, "LEFT"}, -4, 0, 0, 14, "Stop generation eps:")
    prevControlGeneticOptionSection = self.controls.stopGenerationEps
    --
    self.controls.countGenerationsMutateEps = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.countGenerationsMutateEps), nil, "%D", 7, function(buf, placeholder)
        self.countGenerationsMutateEps = tonumber(buf)
    end)
    self.controls.countGenerationsMutateEps.tooltipText = function()
        return "Number of generations after which more aggressive mutations are included"
    end
    self.controls.countGenerationsMutateEpsLabel = new("LabelControl", {"RIGHT", self.controls.countGenerationsMutateEps, "LEFT"}, -4, 0, 0, 14, "Number generations mutate eps:")
    prevControlGeneticOptionSection = self.controls.countGenerationsMutateEps
    --
    self.controls.populationMaxGenerationSize = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.populationMaxGenerationSize), nil, "%D", 7, function(buf, placeholder)
        self.populationMaxGenerationSize = tonumber(buf)
    end)
    self.controls.populationMaxGenerationSize.tooltipText = function()
        return "Maximum number of individuals in the population"
    end
    self.controls.populationMaxGenerationSizeLabel = new("LabelControl", {"RIGHT", self.controls.populationMaxGenerationSize, "LEFT"}, -4, 0, 0, 14, "Population max size:")
    prevControlGeneticOptionSection = self.controls.stopGenerationEps
    --

    self.controls.targetsSection = new("SectionControl", {"TOPLEFT", self.controls.geneticOptionSection, "BOTTOMLEFT"}, 0, 20, 400, 300, "Targets")
    local prevControlTargetsSection = self.controls.targetsSection

    --
    self.controls.targetNormalNodesCount = new("EditControl", { "TOPLEFT", prevControlTargetsSection, "TOPLEFT" }, 8 + 200, 20, 90, 18, tostring(self.targetNormalNodesCount), nil, "%D", 7, function(buf, placeholder)
        self.targetNormalNodesCount = tonumber(buf)
    end)
    self.controls.targetNormalNodesCount.tooltipText = function()
        return "Required number of points invested in regular nodes"
    end
    self.controls.targetNormalNodesCountLabel = new("LabelControl", {"RIGHT", self.controls.targetNormalNodesCount, "LEFT"}, -4, 0, 0, 14, "Number of normal nodes:")
    prevControlTargetsSection = self.controls.targetNormalNodesCount
    --
    self.controls.targetAscendancyNodesCount = new("EditControl", { "TOPLEFT", prevControlTargetsSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.targetAscendancyNodesCount), nil, "%D", 7, function(buf, placeholder)
        self.targetAscendancyNodesCount = tonumber(buf)
    end)
    self.controls.targetAscendancyNodesCount.tooltipText = function()
        return "Required number of points invested in ascendancy nodes"
    end
    self.controls.targetAscendancyNodesCountLabel = new("LabelControl", {"RIGHT", self.controls.targetAscendancyNodesCount, "LEFT"}, -4, 0, 0, 14, "Number of ascendancy nodes:")
    prevControlTargetsSection = self.controls.targetAscendancyNodesCount
    --
    self.controls.targetsList = new("ListControl", {"TOPLEFT", prevControlTargetsSection , "BOTTOMLEFT"}, -190, 12, 360, 220, 14, "Selected targets", function(selectedNode)

    end)
    self.controls.targetsList.colList = {
        { width = 340 * 0.70, label = "Stat", sortable = true },
        { width = 340 * 0.15, label = "Weight" },
        { width = 340 * 0.15, label = "Target" }
    }
    self.controls.targetsList.colLabels = true
    function self.controls.targetsList:GetRowValue(column, index, values)
        return values[column]
    end
    --
    --
    self.controls.addTargetSection = new("SectionControl", {"TOPLEFT", self.controls.targetsSection, "BOTTOMLEFT"}, 0, 24, 400, 150, "Add target stat")
    local prevControlAddTargetSection = self.controls.addTargetSection

    self.stats = { }
    self.statsCount = 0
    for _, stat in pairs(self.build.displayStats) do
        if stat.stat then
            self.statsCount = self.statsCount + 1
            self.stats[self.statsCount] = {
                stat = stat,
                actor = 'player',
                label = stat.label,
                fmt = stat.fmt
            }
        end
    end
    for _, stat in pairs(self.build.minionDisplayStats) do
        if stat.stat then
            self.statsCount = self.statsCount + 1
            self.stats[self.statsCount] = {
                stat = stat,
                actor = 'minion',
                label = "Minion: " .. stat.label,
                fmt = stat.fmt
            }
        end
    end

    for _, stat in pairs(self.stats) do
        if stat.fmt and string.find(stat.fmt, "%%") then
            stat.label = stat.label .. " (%)"
        end
    end

    table.sort(self.stats, function(a, b) return a.label < b.label end)

    self.controls.statsDropdown = new("DropDownControl", { "TOPLEFT", prevControlAddTargetSection, "TOPLEFT" }, 8 + 120, 20, 200, 18, self.stats, function(index)
        self.selectedStatNumber = index
    end)
    self.controls.statsDropdown.selIndex = self.selectedStatNumber
    self.controls.statsDropdownLabel = new("LabelControl", {"RIGHT", self.controls.statsDropdown, "LEFT"}, -4, 0, 0, 14, "Stat:")
    prevControlAddTargetSection = self.controls.statsDropdown
    --
    self.controls.currentStatWeight = new("EditControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.currentStatWeight), nil, "%D", 7, function(buf, placeholder)
        self.currentStatWeight = tonumber(buf)
    end)
    self.controls.currentStatWeight.tooltipText = function()
        return "Weight of stat"
    end
    self.controls.currentStatWeightLabel = new("LabelControl", {"RIGHT", self.controls.currentStatWeight, "LEFT"}, -4, 0, 0, 14, "Weight:")
    prevControlAddTargetSection = self.controls.currentStatWeight
    --
    self.controls.currentStatTarget = new("EditControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.currentStatTarget), nil, nil, 7, function(buf, placeholder)
        self.currentStatTarget = tonumber(buf)
    end)
    self.controls.currentStatTarget.enabled = function() return self.currentStatIsMaximize == false end
    self.controls.currentStatTarget.tooltipText = function()
        return "The value to which the optimizer will strive. No more, no less"
    end
    self.controls.currentStatTargetLabel = new("LabelControl", {"RIGHT", self.controls.currentStatTarget, "LEFT"}, -4, 0, 0, 14, "Target:")
    prevControlAddTargetSection = self.controls.currentStatTarget
    --
    self.controls.currentStatIsMaximize = new("CheckBoxControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 18, self.currentStatIsMaximize, function(state)
        self.currentStatIsMaximize = state
    end, "Maximize target stat")
    self.controls.currentStatIsMaximizeLabel = new("LabelControl", {"RIGHT", self.controls.currentStatIsMaximize, "LEFT"}, -4, 0, 0, 14, "Maximize stat?:")
    prevControlAddTargetSection = self.controls.currentStatIsMaximize
    --
    self.controls.addTargetStat = new("ButtonControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, -50, 8, 100, 20, "Add target stat", function()
        local selectedStat = self.stats[self.selectedStatNumber]
        local target = self.currentStatTarget

        if self.currentStatIsMaximize then
            target = 'MAX'
        end

        if not target then
            return
        end

        self.targetStats[selectedStat.stat] = {
            stat = selectedStat,
            weight = self.currentStatWeight,
            target = target,
            isMaximize = self.currentStatIsMaximize
        }

        self:GenerateTargetList()
    end)
end)

function OptimizationTabClass:GenerateTargetList()
    local list = { }
    local count = 0
    for _, stat in pairs(self.targetStats) do
        count = count + 1
        list[count] = {
            stat.stat.label,
            stat.weight,
            stat.target
        }
    end

    self.controls.targetsList.list = list
end

function OptimizationTabClass:Draw(viewPort, inputEvents)
    self.anchorControls.x = viewPort.x + 8
    self.anchorControls.y = viewPort.y + 12

    self:ProcessControlsInput(inputEvents, viewPort)
    self:DrawControls(viewPort)
end

function OptimizationTabClass:Save(xml)
    -- TODO
    xml.attrib = {}
end

function OptimizationTabClass:Load(xml, dbFileName)
    -- TODO
end
