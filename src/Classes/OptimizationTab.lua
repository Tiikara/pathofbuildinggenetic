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

    local enabledNotInProgressFunc = function()
        return not self.geneticSolver or self.geneticSolver:IsProgress() == false
    end

    self.controls.start = new("ButtonControl", { "LEFT", self.anchorControls, "LEFT" }, 0, 0, 200, 30, "Start optimization", function()
        if not self.geneticSolver then
            self.geneticSolver = new("GeneticSolver", self.build)
        end

        local targetStatsCount = 0
        local targetStats = { }
        local maximizeStatsCount = 0
        local maximizeStats = { }

        for _, targetStat in pairs(self.targetStats) do
            if targetStat.isMaximize then
                maximizeStatsCount = maximizeStatsCount + 1
                maximizeStats[maximizeStatsCount] = {
                    stat = targetStat.stat.stat,
                    lowerIsBetter = targetStat.stat.displayStat.lowerIsBetter,
                    actor = targetStat.stat.actor,
                    weight = targetStat.weight
                }
            else
                targetStatsCount = targetStatsCount + 1
                targetStats[targetStatsCount] = {
                    stat = targetStat.stat.stat,
                    lowerIsBetter = targetStat.stat.displayStat.lowerIsBetter,
                    actor = targetStat.stat.actor,
                    weight = targetStat.weight,
                    target = targetStat.target
                }
            end
        end

        self.geneticSolver:StartSolve(
                self.maxGenerationCount,
                self.stopGenerationEps,
                self.countGenerationsMutateEps,
                self.populationMaxGenerationSize,
                self.targetNormalNodesCount,
                self.targetAscendancyNodesCount,
                targetStats,
                maximizeStats
        )
    end)
    self.controls.start.enabled = enabledNotInProgressFunc

    self.controls.stop = new("ButtonControl", { "TOPLEFT", self.controls.start, "TOPRIGHT" }, 8, 0, 200, 30, "Stop optimization", function()
        self.geneticSolver:StopSolve()
    end)
    self.controls.stop.enabled = function() return enabledNotInProgressFunc() == false end

    self.controls.geneticOptionSection = new("SectionControl", {"TOPLEFT", self.controls.start, "BOTTOMLEFT"}, 0, 60, 400, 120, "Genetic Options")
    local prevControlGeneticOptionSection = self.controls.geneticOptionSection

    --
    self.controls.maxGenerationCount = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "TOPLEFT" }, 8 + 200, 20, 90, 18, tostring(self.maxGenerationCount), nil, "%D", 7, function(buf, placeholder)
        self.maxGenerationCount = tonumber(buf)
    end)
    self.controls.maxGenerationCount.tooltipText = function()
        return "Max generations used by genetic algorithm"
    end
    self.controls.maxGenerationCount.enabled = enabledNotInProgressFunc
    self.controls.controlMaxGenerationCountLabel = new("LabelControl", {"RIGHT", self.controls.maxGenerationCount, "LEFT"}, -4, 0, 0, 14, "Max generations number:")
    prevControlGeneticOptionSection = self.controls.maxGenerationCount
    --
    self.controls.stopGenerationEps = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.stopGenerationEps), nil, "%D", 7, function(buf, placeholder)
        self.stopGenerationEps = tonumber(buf)
    end)
    self.controls.stopGenerationEps.tooltipText = function()
        return "The number of generations in which the build does not improve, after which the algorithm stops"
    end
    self.controls.stopGenerationEps.enabled = enabledNotInProgressFunc
    self.controls.stopGenerationEpsLabel = new("LabelControl", {"RIGHT", self.controls.stopGenerationEps, "LEFT"}, -4, 0, 0, 14, "Stop generation eps:")
    prevControlGeneticOptionSection = self.controls.stopGenerationEps
    --
    self.controls.countGenerationsMutateEps = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.countGenerationsMutateEps), nil, "%D", 7, function(buf, placeholder)
        self.countGenerationsMutateEps = tonumber(buf)
    end)
    self.controls.countGenerationsMutateEps.tooltipText = function()
        return "Number of generations after which more aggressive mutations are included"
    end
    self.controls.countGenerationsMutateEps.enabled = enabledNotInProgressFunc
    self.controls.countGenerationsMutateEpsLabel = new("LabelControl", {"RIGHT", self.controls.countGenerationsMutateEps, "LEFT"}, -4, 0, 0, 14, "Number generations mutate eps:")
    prevControlGeneticOptionSection = self.controls.countGenerationsMutateEps
    --
    self.controls.populationMaxGenerationSize = new("EditControl", { "TOPLEFT", prevControlGeneticOptionSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.populationMaxGenerationSize), nil, "%D", 7, function(buf, placeholder)
        self.populationMaxGenerationSize = tonumber(buf)
    end)
    self.controls.populationMaxGenerationSize.tooltipText = function()
        return "Maximum number of individuals in the population"
    end
    self.controls.populationMaxGenerationSize.enabled = enabledNotInProgressFunc
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
    self.controls.targetNormalNodesCount.enabled = enabledNotInProgressFunc
    self.controls.targetNormalNodesCountLabel = new("LabelControl", {"RIGHT", self.controls.targetNormalNodesCount, "LEFT"}, -4, 0, 0, 14, "Number of normal nodes:")
    prevControlTargetsSection = self.controls.targetNormalNodesCount
    --
    self.controls.targetAscendancyNodesCount = new("EditControl", { "TOPLEFT", prevControlTargetsSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.targetAscendancyNodesCount), nil, "%D", 7, function(buf, placeholder)
        self.targetAscendancyNodesCount = tonumber(buf)
    end)
    self.controls.targetAscendancyNodesCount.tooltipText = function()
        return "Required number of points invested in ascendancy nodes"
    end
    self.controls.targetAscendancyNodesCount.enabled = enabledNotInProgressFunc
    self.controls.targetAscendancyNodesCountLabel = new("LabelControl", {"RIGHT", self.controls.targetAscendancyNodesCount, "LEFT"}, -4, 0, 0, 14, "Number of ascendancy nodes:")
    prevControlTargetsSection = self.controls.targetAscendancyNodesCount
    --
    self.controls.targetsList = new("ListControl", {"TOPLEFT", prevControlTargetsSection , "BOTTOMLEFT"}, -190, 12, 360, 220, 14, true, true)
    self.controls.targetsList.colList = {
        { width = 340 * 0.60, label = "Stat", sortable = true },
        { width = 340 * 0.15, label = "Weight" },
        { width = 340 * 0.25, label = "Target" }
    }
    self.controls.targetsList.colLabels = true
    self.controls.targetsList.GetRowValue = function(_, column, index, values)
        if column == 3 and self.targetStats[values[4]].isMaximize then
            if self.targetStats[values[4]].stat.displayStat.lowerIsBetter then
                return "MIN"
            else
                return "MAX"
            end
        end

        return values[column]
    end
    self.controls.targetsList.OnSelClick = function(_, index, selectedStatList, doubleClick)
        if doubleClick then
            local statName = selectedStatList[4]

            self.targetStats[statName] = nil
            self:GenerateTargetList()
        end
    end
    self.controls.targetsList.AddValueTooltip = function(_, tooltip, _, _)
        tooltip.AddLine(16, "^7Double-click on stat to remove it from the list")
    end
    self.controls.targetsList.enabled = enabledNotInProgressFunc
    --
    --
    self.controls.addTargetSection = new("SectionControl", {"TOPLEFT", self.controls.targetsSection, "BOTTOMLEFT"}, 0, 24, 400, 150, "Add target stat")
    local prevControlAddTargetSection = self.controls.addTargetSection

    local statsPlayer = { }
    local statsMinion = { }
    self.stats = { }
    self.statsCount = 0
    for _, displayStat in pairs(self.build.displayStats) do
        if displayStat.stat then

            local stat = {
                stat = displayStat.stat,
                actor = 'player',
                label = displayStat.label,
                fmt = displayStat.fmt,
                displayStat = displayStat
            }

            self.statsCount = self.statsCount + 1
            self.stats[self.statsCount] = stat

            statsPlayer[displayStat.stat] = stat
        end
    end
    for _, displayStat in pairs(self.build.minionDisplayStats) do
        if displayStat.stat then
            local stat = {
                stat = displayStat.stat,
                actor = 'minion',
                label = "Minion: " .. displayStat.label,
                fmt = displayStat.fmt,
                displayStat = displayStat
            }

            self.statsCount = self.statsCount + 1
            self.stats[self.statsCount] = stat


            statsMinion[displayStat.stat] = stat
        end
    end

    self.statsByActor = {
        player = statsPlayer,
        minion = statsMinion
    }

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
    self.controls.statsDropdown.enabled = enabledNotInProgressFunc
    self.controls.statsDropdownLabel = new("LabelControl", {"RIGHT", self.controls.statsDropdown, "LEFT"}, -4, 0, 0, 14, "Stat:")
    prevControlAddTargetSection = self.controls.statsDropdown
    --
    self.controls.currentStatWeight = new("EditControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.currentStatWeight), nil, "%D", 7, function(buf, placeholder)
        self.currentStatWeight = tonumber(buf)
    end)
    self.controls.currentStatWeight.tooltipText = function()
        return "Weight of stat"
    end
    self.controls.currentStatWeight.enabled = enabledNotInProgressFunc
    self.controls.currentStatWeightLabel = new("LabelControl", {"RIGHT", self.controls.currentStatWeight, "LEFT"}, -4, 0, 0, 14, "Weight:")
    prevControlAddTargetSection = self.controls.currentStatWeight
    --
    self.controls.currentStatTarget = new("EditControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 90, 18, tostring(self.currentStatTarget), nil, nil, 7, function(buf, placeholder)
        self.currentStatTarget = tonumber(buf)
    end)
    self.controls.currentStatTarget.enabled = function() return self.currentStatIsMaximize == false and enabledNotInProgressFunc() end
    self.controls.currentStatTarget.tooltipText = function()
        return "The value to which the optimizer will strive. No more, no less"
    end
    self.controls.currentStatTargetLabel = new("LabelControl", {"RIGHT", self.controls.currentStatTarget, "LEFT"}, -4, 0, 0, 14, "Target:")
    prevControlAddTargetSection = self.controls.currentStatTarget
    --
    self.controls.currentStatIsMaximize = new("CheckBoxControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, 0, 4, 18, self.currentStatIsMaximize, function(state)
        self.currentStatIsMaximize = state
    end, "Maximize target stat")
    self.controls.currentStatIsMaximize.enabled = enabledNotInProgressFunc
    self.controls.currentStatIsMaximizeLabel = new("LabelControl", {"RIGHT", self.controls.currentStatIsMaximize, "LEFT"}, -4, 0, 0, 14, "Maximize stat?:")
    self.controls.currentStatIsMaximizeLabel.label = function()
        local stat = self.stats[self.selectedStatNumber]

        if stat.displayStat.lowerIsBetter then
            return "Minimize stat?:"
        else
            return "Maximize stat?:"
        end
    end
    prevControlAddTargetSection = self.controls.currentStatIsMaximize
    --
    self.controls.addTargetStat = new("ButtonControl", { "TOPLEFT", prevControlAddTargetSection, "BOTTOMLEFT" }, -75, 8, 150, 20, "Add target stat", function()
        local selectedStat = self.stats[self.selectedStatNumber]
        local target = self.currentStatTarget

        if not self.currentStatIsMaximize and not target then
            return
        end

        self.targetStats[selectedStat.stat] = {
            stat = selectedStat,
            label = selectedStat.label,
            weight = self.currentStatWeight,
            target = target,
            isMaximize = self.currentStatIsMaximize
        }

        self:GenerateTargetList()
    end)
    self.controls.addTargetStat.label = function()
        local stat = self.stats[self.selectedStatNumber]

        if stat and self.targetStats[stat.stat] then
            return "Change target stat"
        end

        return "Add target stat"
    end
    self.controls.addTargetStat.enabled = enabledNotInProgressFunc
end)

function OptimizationTabClass:GenerateTargetList()
    local list = { }
    local count = 0
    for _, targetStat in pairs(self.targetStats) do
        count = count + 1
        list[count] = {
            targetStat.label,
            targetStat.weight,
            targetStat.target,
            targetStat.stat.stat
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
    xml.attrib = {
        maxGenerationCount = tostring(self.maxGenerationCount),
        stopGenerationEps = tostring(self.stopGenerationEps),
        countGenerationsMutateEps = tostring(self.countGenerationsMutateEps),
        populationMaxGenerationSize = tostring(self.populationMaxGenerationSize),

        targetNormalNodesCount = tostring(self.targetNormalNodesCount),
        targetAscendancyNodesCount = tostring(self.targetAscendancyNodesCount)
    }

    local targetStatsXml = {
        elem = "TargetStats"
    }

    table.insert(xml, targetStatsXml)

    for _, targetStat in pairs(self.targetStats) do
        local statXml = {
            elem = "Stat",
            attrib = {
                stat = targetStat.stat.stat,
                actor = targetStat.stat.actor,
                weight = tostring(targetStat.weight),
                target = tostring(targetStat.target),
                isMaximize = tostring(targetStat.isMaximize)
            }
        }

        table.insert(targetStatsXml, statXml)
    end
end

function OptimizationTabClass:Load(xml, _)
    local attrib = xml.attrib
    if attrib then
        if attrib.maxGenerationCount ~= nil then
            self.controls.maxGenerationCount:SetText(attrib.maxGenerationCount, true)
        end

        if attrib.stopGenerationEps ~= nil then
            self.controls.stopGenerationEps:SetText(attrib.stopGenerationEps, true)
        end

        if attrib.countGenerationsMutateEps ~= nil then
            self.controls.countGenerationsMutateEps:SetText(attrib.countGenerationsMutateEps, true)
        end

        if attrib.populationMaxGenerationSize ~= nil then
            self.controls.populationMaxGenerationSize:SetText(attrib.populationMaxGenerationSize, true)
        end

        if attrib.targetNormalNodesCount ~= nil then
            self.controls.targetNormalNodesCount:SetText(attrib.targetNormalNodesCount, true)
        end

        if attrib.targetAscendancyNodesCount ~= nil then
            self.controls.targetAscendancyNodesCount:SetText(attrib.targetAscendancyNodesCount, true)
        end
    end

    self.targetStats = {  }

    for _, node in pairs(xml) do
        if type(node) == "table" and node.elem == "TargetStats" then
            for _, targetStatsNode in pairs(node) do
                if type(targetStatsNode) == "table" and targetStatsNode.elem == "Stat" then
                    local statAttrib = targetStatsNode.attrib

                    if statAttrib then
                        local stat = self.statsByActor[statAttrib.actor][statAttrib.stat]

                        self.targetStats[stat.stat] = {
                            stat = stat,
                            label = stat.label,
                            weight = tonumber(statAttrib.weight),
                            target = tonumber(statAttrib.target),
                            isMaximize = statAttrib.isMaximize == "true"
                        }
                    end
                end
            end
        end
    end

    self:GenerateTargetList()
end
