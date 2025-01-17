--CUSTOM COLORS
local MCDU_BLUE = {0.0, 0.7, 0.8, 1.0}

--DATAREFS
local gndTemp = globalPropertyf("sim/cockpit2/temperature/outside_air_temp_degc")

function calculateGndTemp(fl)
    flTemp = fl/10 * 1.98
    local crzTemp = get(gndTemp) - flTemp
    return math.ceil(crzTemp)
end

-- GLOBAL VARIABLES
COST_INDEX = 0
local optionLables = {
    [1] = "CO RTE",
    [2] = "ALTN/CO RTE",
    [3] = "FLT NUMBER",
    [4] = "LAT",
    [5] = "COST INDEX",
    [6] = "CRZ FL/TEMP",
    [7] = "FROM/TO",
    [8] = "",
    [9] = "",
    [10] = "LONG",
    [11] = "TROPO",
    [12] = "GND TEMP"
}
local MCDU_ORANGE = {1.0, 0.549, 0.0, 1.0}
local MCDU_WHITE = {1.0, 1.0, 1.0, 1.0}

local inputs = {
    -- Format = {side, position, field length, color, message}
    CO_RTE = {1, 1, 10, MCDU_WHITE, " "},
    ALTN_CO_RTE = {1, 2, 15, MCDU_WHITE, " "},
    FLT_NBR = {1, 3, 8, MCDU_WHITE, " "},
    LAT = {1, 4, 6, MCDU_WHITE, " "},
    COST_INDEX = {1, 5, 3, MCDU_WHITE, " "},
    CRZ_FL_TEMP = {1, 6, 9, MCDU_WHITE, " "},
    FROM_TO = {2, 1, 9, MCDU_WHITE, " "},
    LONG = {2, 4, 6, MCDU_WHITE, " "},
    WIND = {2, 5}
}

function processCoRte()
    if string.len(scratchpad) == inputs.CO_RTE[3] and get(MCDU_CURRENT_BUTTON) == 0 then
        inputs.CO_RTE[5] = scratchpad
        set(MCDU_CURRENT_BUTTON, -1)
        scratchpad = ""
    elseif get(MCDU_CURRENT_BUTTON) == 0 and string.len(scratchpad) ~= inputs.CO_RTE[3] then
        scratchpad = "ERROR"
    end
end

function processAltnCoRte()
    if string.len(scratchpad) == inputs.ALTN_CO_RTE[3]and get(MCDU_CURRENT_BUTTON) == 1 and string.sub(scratchpad,5,5) == "/"then
        inputs.ALTN_CO_RTE[5] = scratchpad
        set(MCDU_CURRENT_BUTTON,-1)
        scratchpad = ""
    elseif get(MCDU_CURRENT_BUTTON) == 1 and (string.len(scratchpad) ~= inputs.ALTN_CO_RTE[3] or string.sub(scratchpad, 5,5) ~= "/") then
        print(string.sub(scratchpad, 5,5))
        scratchpad = "ERROR"
    end
end

function processFltNbr()
    if string.len(scratchpad) <= inputs.FLT_NBR[3] and string.len(scratchpad) >= 3 and get(MCDU_CURRENT_BUTTON) == 2 then
        inputs.FLT_NBR[5] = scratchpad
        set(MCDU_CURRENT_BUTTON,-1)
        scratchpad = ""
    elseif get(MCDU_CURRENT_BUTTON) == 2 and (string.len(scratchpad) > inputs.ALTN_CO_RTE[3] or string.len(scratchpad) < 3)  then
        scratchpad = "ERROR"
    end
end

function processLat()
    if string.len(scratchpad) == inputs.LAT[3]and get(MCDU_CURRENT_BUTTON) == 3 and string.sub(scratchpad,5,5) == "." then
        inputs.LAT[5] = scratchpad
        set(MCDU_CURRENT_BUTTON, -1)
        scratchpad = ""
    elseif get(MCDU_CURRENT_BUTTON) == 3 and (string.len(scratchpad) ~= inputs.LAT[3] or string.sub(scratchpad,5,5) ~= ".") then
        scratchpad = "ERROR"
    end
end

function processCostIndex()
    if string.len(scratchpad) == inputs.COST_INDEX[3] and get(MCDU_CURRENT_BUTTON) == 4 and toNum(scratchpad) then
        inputs.COST_INDEX[5] = scratchpad
        set(MCDU_CURRENT_BUTTON, -1)
        COST_INDEX = scratchpad
        scratchpad = ""
    elseif string.len(scratchpad) == 2 and get(MCDU_CURRENT_BUTTON) == 4 and toNum(scratchpad) then
        inputs.COST_INDEX[5] = "0"..scratchpad
        set(MCDU_CURRENT_BUTTON, -1)
        COST_INDEX = scratchpad
        scratchpad = ""
    elseif get(MCDU_CURRENT_BUTTON) == 4 then
        scratchpad = "ERROR: INVALID INPUT"
    end
end

function processCrzFlTemp()
    if (string.len(scratchpad) == inputs.CRZ_FL_TEMP[3] or string.len(scratchpad) == inputs.CRZ_FL_TEMP[3]-2) and get(MCDU_CURRENT_BUTTON) == 5 then
            inputs.CRZ_FL_TEMP[5] = scratchpad
    elseif (string.len(scratchpad) == inputs.CRZ_FL_TEMP[3]-3 or string.len(scratchpad) == inputs.CRZ_FL_TEMP[3]-5) and get(MCDU_CURRENT_BUTTON) == 5 then
        print("fat")
        local crzFL = ""
        if  string.sub(scratchpad,1,2) == "FL" and string.sub(scratchpad,6,6) == "/" then
                crzFL = string.sub(scratchpad,3,5)
                local crzTemp = calculateGndTemp(tonumber(crzFL))
                inputs.CRZ_FL_TEMP[5] = scratchpad .. crzTemp
                scratchpad = ""

        elseif string.sub(scratchpad,1,2) ~= "FL" and string.sub(scratchpad,4,4) == "/"then
                crzFL = string.sub(scratchpad,1,3)
                local crzTemp = calculateGndTemp(tonumber(crzFL))
                inputs.CRZ_FL_TEMP[5] = "FL" .. scratchpad .. crzTemp
                scratchpad = ""
        end
    elseif get(MCDU_CURRENT_BUTTON) == 5 and string.len(scratchpad) ~= inputs.CRZ_FL_TEMP[3] then
        scratchpad = "ERROR"
    end
end

function processFromTo()
    if string.len(scratchpad) == inputs.FROM_TO[3] and get(MCDU_CURRENT_BUTTON) == 6 then
        if string.sub(scratchpad,5,5) == "/" then
            local icao1 = string.sub(scratchpad,1,4)
            local icao2 = string.sub(scratchpad,6,9)
            if checkICAO(icao1) == true and checkICAO(icao2) == true then
                DEPARTURE_AIRPORT = icao1
                table.insert(fplanWpts, 1, icao1)
                DESTINATION_AIRPORT = icao2
                inputs.FROM_TO[5] = scratchpad
                scratchpad = ""
                set(FPLAN_INIT, 1)
                set(MCDU_CURRENT_PAGE, 12)
            else
                scratchpad = "ERROR: INVALID ICAO"
            end
        else
            scratchpad = "FORMAT ERROR"
        end
    elseif get(MCDU_CURRENT_BUTTON) == 6 and string.len(scratchpad) == 0 and string.len(inputs.FROM_TO[5]) == 9 then
        set(MCDU_CURRENT_PAGE, 12)
    elseif get(MCDU_CURRENT_BUTTON) == 6 then
        scratchpad = "ERROR"
    end
end

local function processPageInput()
    if get(MCDU_CURRENT_BUTTON) == 24 or get(MCDU_CURRENT_BUTTON) == 26 then
        set(MCDU_CURRENT_PAGE, 11)
    end
end

--TODO: function processFromTo - Need to validate airports

function drawInit()
    processPageInput()
    processCoRte()
    if inputs.CO_RTE[5] == " " then
        drawTextFieldBoxes(10, MCDU_ORANGE, -8, TEXT_Y[12]-4,1)
    else
        drawText(inputs.CO_RTE[5], 1, 12, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processAltnCoRte()
    if inputs.ALTN_CO_RTE[5] == " " then
        drawText("----/--------", 1, 10, MCDU_WHITE, SIZE.OPTION, false, "L")
    else
        drawText(inputs.ALTN_CO_RTE[5], 1, 10, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processFltNbr()
    if inputs.FLT_NBR[5] == " " then
        drawTextFieldBoxes(8, MCDU_ORANGE, -8, TEXT_Y[8]-3,1)
    else
        drawText(inputs.FLT_NBR[5], 1, 8, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processLat()
    if inputs.LAT[5] == " " then
        drawText("---.--", 1, 6, MCDU_WHITE, SIZE.OPTION, false, "L")
    else
        drawText(inputs.LAT[5], 1, 6, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processCostIndex()
    if inputs.COST_INDEX[5] == " " then
        drawText("---", 1, 4, MCDU_WHITE, SIZE.OPTION, false, "L")
    else
        drawText(inputs.COST_INDEX[5], 1, 4, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processCrzFlTemp()
    if inputs.CRZ_FL_TEMP[5] == " " then
        drawText("-----/---"..DEG_SYMBOL, 1, 2, MCDU_WHITE, SIZE.OPTION, false, "L")
    else
        drawText(inputs.CRZ_FL_TEMP[5]..DEG_SYMBOL, 1, 2, MCDU_WHITE, SIZE.OPTION, false, "L")
    end

    processFromTo()
    if inputs.FROM_TO[5] == " " then
        drawTextFieldBoxes(9, MCDU_ORANGE, 519, TEXT_Y[12]-4,2)
    else
        drawText(inputs.FROM_TO[5], 24, 12, MCDU_BLUE, SIZE.OPTION, false, "R")
    end
    --STATIC DRAWINGS
    drawText("INIT", 11, 14, MCDU_WHITE, SIZE.TITLE, false, "L")
    drawText("INIT", 24, 11, MCDU_ORANGE, SIZE.HEADER, false, "R")
    drawText("REQUEST*", 24, 10, MCDU_ORANGE, SIZE.OPTION, false, "R")


    drawText("WIND/TEMP>", 24, 6, MCDU_WHITE, SIZE.OPTION, false, "R")
    drawText("---"..DEG_SYMBOL, 24, 2, MCDU_WHITE, SIZE.OPTION, false, "R")
    drawOptionHeadings(optionLables)
end

function switchInitPage()
    if get(MCDU_CURRENT_PAGE) == 12 and get(MCDU_CURRENT_BUTTON) == 5 then
        set(MCDU_CURRENT_PAGE, 1)
        set(MCDU_CURRENT_BUTTON, -1)
    end
end

function drawCoRte()
    --STATIC DRAWINGS
    local CO_RTE_TITLE = DEPARTURE_AIRPORT.."/"..DESTINATION_AIRPORT
    drawText(CO_RTE_TITLE, 9, 14, MCDU_WHITE, SIZE.TITLE, false, "L")
    drawText("NONE", 1, 12, MCDU_WHITE, SIZE.OPTION, false, "L")
    drawText("<RETURN", 1, 2, MCDU_WHITE, SIZE.OPTION, false, "L")
end