position = {49, 1545, 1262, 1390}
size = {500, 500}

-- get datarefs
local setupComplete = false
local enrouteWaypoints = {}
local enrouteNavaids = {}
local fplanWptXY = {}
local fplanWptLatLong = {}
local startup_complete = false
local eng1N1 = globalProperty("sim/flightmodel/engine/ENGN_N1_[0]")

local BUS = globalProperty("A318/systems/ELEC/ACESS_V")
local selfTest = 0

local DELTA_TIME = globalProperty("sim/operation/misc/frame_rate_period")
local Timer = 0
local TimerFinal = math.random(25, 40)

local ADIRS_mode = globalProperty("A318/systems/ADIRS/1/mode")
local ADIRS_aligned = globalProperty("A318/systems/ADIRS/1/aligned")
local heading = globalPropertyf("A318/systems/ADIRS/1/inertial/heading")
local currentLat = globalPropertyf("A318/systems/ADIRS/1/inertial/latitude")
local currentLon = globalPropertyf("A318/systems/ADIRS/1/inertial/longitude")

local latGroup = 0
local lonGroup = 0

local navid = globalProperty("sim/cockpit2/radios/indicators/nav1_nav_id")
local navfreq = globalProperty("sim/cockpit/radios/nav1_freq_hz")
local navCrs = globalProperty("sim/cockpit/radios/nav1_course_degm")
local navhdev = globalProperty("sim/cockpit/radios/nav1_hdef_dot")
local navvdev = globalProperty("sim/cockpit/radios/nav1_vdef_dot")

local tas = globalPropertyf("A318/systems/ADIRS/1/air/tas")
local gs = globalPropertyf("A318/systems/ADIRS/1/inertial/gs")
local winddirection = globalPropertyf("sim/weather/wind_direction_degt")
local windspeed = globalPropertyf("sim/weather/wind_speed_kt")

local CaptNdMode = createGlobalPropertyi("A318/systems/ND/capt_mode", 3)
local rngeKnob = createGlobalPropertyi("A318/systems/ND/capt_rnge", 2)
local CaptNdRnge = 40

local CaptNdCSTR = createGlobalPropertyi("A318/systems/ND/capt_cstr", 0)
local CaptNdWPT = createGlobalPropertyi("A318/systems/ND/capt_wpt", 0)
local CaptNdVORD = createGlobalPropertyi("A318/systems/ND/capt_vord", 0)
local CaptNdNDB = createGlobalPropertyi("A318/systems/ND/capt_ndb", 0)
local CaptNdARPT = createGlobalPropertyi("A318/systems/ND/capt_arpt", 1)
local CaptNdTERR = createGlobalPropertyi("A318/systems/ND/capt_terr", 0)
local captNdBright = createGlobalPropertyf("A318/cockpit/capt/ndBright", 1)

--fonts
local ndFont = sasl.gl.loadFont("fonts/PanelFont.ttf")

--get images
local symbols = sasl.gl.loadImage("ND/symbols.png")
local miniplane = sasl.gl.loadImage("plane.png", 0, 0, 160, 160)
local rose = sasl.gl.loadImage("rose.png", 0, 0, 550, 550)
local rose_unaligned = sasl.gl.loadImage("rose-unaligned.png", 0, 0, 550, 550)
local arcMask = sasl.gl.loadImage("ND/arcMask.png")
local arcTape = sasl.gl.loadImage("arc.png", 0, 0, 2048, 2048)
local arcTape_unaligned = sasl.gl.loadImage("arc_unaligned.png", 0, 0, 2048, 2048)

function plane_startup()
    if get(eng1N1) > 1 then
        -- engines running
        selfTest = 1
        Timer = 0
    else
        -- cold and dark
        selfTest = 0
    end
end

local function draw_overlay_text()
    sasl.gl.drawText(ndFont, 10, 475, "GS", 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 66, 475, math.floor(get(gs)+ 0.5), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.GREEN) -- GROUND SPEED

    sasl.gl.drawText(ndFont, 75, 475, "TAS", 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.WHITE)
    if get(ADIRS_aligned) == 0 then
        sasl.gl.drawText(ndFont, 141, 475, "---", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.GREEN)
    else
        sasl.gl.drawText(ndFont, 141, 475, math.floor(get(tas)+ 0.5), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.GREEN) -- TAS
    end

    if get(ADIRS_aligned) == 0 then 
        sasl.gl.drawText(ndFont, 10, 455, "---", 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
        sasl.gl.drawText(ndFont, 43, 455, "/", 18, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.WHITE)
        sasl.gl.drawText(ndFont, 48, 455, "--", 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
    else
        if get(gs) < 100 then 
            sasl.gl.drawText(ndFont, 10, 455, "---", 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
            sasl.gl.drawText(ndFont, 43, 455, "/", 18, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.WHITE)
            sasl.gl.drawText(ndFont, 48, 455, "--", 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
        else 
            sasl.gl.drawText(ndFont, 10, 455, string.format("%03d", math.floor(get(winddirection) + 0.5)), 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
            sasl.gl.drawText(ndFont, 43, 455, "/", 18, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.WHITE)
            sasl.gl.drawText(ndFont, 48, 455, math.floor(get(windspeed) + 0.5), 18, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
        end
    end

    if get(ADIRS_aligned) == 0 then
        sasl.gl.drawText(ndFont, 250, 25, "GPS  PRIMARY  LOST", 20, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.ORANGE)
        sasl.gl.drawWidePolyLine({ 100, 22, 400, 22, 400, 42, 100, 42, 100, 22, 110, 22}, 2, ECAM_COLOURS.WHITE)
    end
end

local function draw_ils()
    sasl.gl.drawText(ndFont, 450, 475, "ILS1  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 475, string.format("%.2f", get(navfreq) / 100), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 460, 455, "CRS  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 455, string.format("%03d", (math.floor(get(navCrs) + 0.5))).."°", 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 490, 435, get(navid), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)

    sasl.gl.saveGraphicsContext ()
    sasl.gl.setTranslateTransform (250, 250)
    sasl.gl.setRotateTransform(-1 * (get(heading) - get(navCrs)))
    sasl.gl.drawWideLine(0, 90, 0, 175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.drawWideLine(-20, 107, 20, 107, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawCircle(-100, 0, 4, false, ECAM_COLOURS.WHITE) -- full left
    sasl.gl.drawCircle(-50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(100, 0, 4, false, ECAM_COLOURS.WHITE) -- full right

    sasl.gl.drawWideLine(0 + (50 * get(navhdev)), 80, 0 + (50 * get(navhdev)), -80, 3, ECAM_COLOURS.PURPLE) -- Horizontal Deviation bar

    sasl.gl.drawWideLine(0, -90, 0, -175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.restoreGraphicsContext ()

    sasl.gl.drawWideLine(470, 250, 490, 250, 3, ECAM_COLOURS.YELLOW)
    sasl.gl.drawCircle(480, 350, 4, false, ECAM_COLOURS.WHITE) -- full down
    sasl.gl.drawCircle(480, 300, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(480, 200, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(480, 150, 4, false, ECAM_COLOURS.WHITE) -- full up

    if get(navvdev) > 2 then
        sasl.gl.drawWidePolyLine({488, 150, 480, 137, 472, 150}, 1.5, ECAM_COLOURS.PURPLE)
    elseif get(navvdev) < -2 then
        sasl.gl.drawWidePolyLine({ 472, 350, 480, 363, 488, 350}, 1.5, ECAM_COLOURS.PURPLE)
    else
        sasl.gl.drawWidePolyLine({ 472, 250 - (50 * get(navvdev)), 480, 263 - (50 * get(navvdev)), 488, 250 - (50 * get(navvdev)), 480, 237 - (50 * get(navvdev)), 472, 250 - (50 * get(navvdev))}, 1.5, ECAM_COLOURS.PURPLE) -- Vertical Deviation bar
    end

    sasl.gl.drawRotatedTexture(rose, -1 * get(heading), 0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawWideLine(250, 417, 250, 433, 3, ECAM_COLOURS.YELLOW )
    sasl.gl.drawTexture(miniplane, 225, 216, 50, 50, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_ils_unaligned()
    sasl.gl.drawText(ndFont, 450, 475, "ILS1  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 475, string.format("%.2f", get(navfreq) / 100), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 460, 455, "CRS  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 455, string.format("%03d", (math.floor(get(navCrs) + 0.5))).."°", 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 490, 435, get(navid), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)

    sasl.gl.saveGraphicsContext ()
    sasl.gl.setTranslateTransform (250, 250)
    sasl.gl.drawWideLine(0, 90, 0, 175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.drawWideLine(-20, 107, 20, 107, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawCircle(-100, 0, 4, false, ECAM_COLOURS.WHITE) -- full left
    sasl.gl.drawCircle(-50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(100, 0, 4, false, ECAM_COLOURS.WHITE) -- full right

    sasl.gl.drawWideLine(0 + (50 * get(navhdev)), 80, 0 + (50 * get(navhdev)), -80, 3, ECAM_COLOURS.PURPLE) -- Horizontal Deviation bar

    sasl.gl.drawWideLine(0, -90, 0, -175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.restoreGraphicsContext ()

    sasl.gl.drawWideLine(470, 250, 490, 250, 3, ECAM_COLOURS.YELLOW)
    sasl.gl.drawCircle(480, 350, 4, false, ECAM_COLOURS.WHITE) -- full down
    sasl.gl.drawCircle(480, 300, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(480, 200, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(480, 150, 4, false, ECAM_COLOURS.WHITE) -- full up

    if get(navvdev) > 2 then
        sasl.gl.drawWidePolyLine({488, 150, 480, 137, 472, 150}, 1.5, ECAM_COLOURS.PURPLE)
    elseif get(navvdev) < -2 then
        sasl.gl.drawWidePolyLine({ 472, 350, 480, 363, 488, 350}, 1.5, ECAM_COLOURS.PURPLE)
    else
        sasl.gl.drawWidePolyLine({ 472, 250 - (50 * get(navvdev)), 480, 263 - (50 * get(navvdev)), 488, 250 - (50 * get(navvdev)), 480, 237 - (50 * get(navvdev)), 472, 250 - (50 * get(navvdev))}, 1.5, ECAM_COLOURS.PURPLE) -- Vertical Deviation bar
    end

    sasl.gl.drawCircle(250, 250, 6, true, ECAM_COLOURS.RED)
    sasl.gl.drawCircle(250, 250, 4, true, {0.0, 0.0, 0.0, 1.0})
    sasl.gl.drawTexture(rose_unaligned,0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 250, 345, "HDG", 30, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_vor()
    sasl.gl.drawText(ndFont, 450, 475, "VOR1  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 475, string.format("%.2f", get(navfreq) / 100), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 460, 455, "CRS  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 455, string.format("%03d", (math.floor(get(navCrs) + 0.5))).."°", 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 490, 435, get(navid), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)

    sasl.gl.saveGraphicsContext ()
    sasl.gl.setTranslateTransform (250, 250)
    sasl.gl.setRotateTransform(-1 * (get(heading) - get(navCrs)))
    sasl.gl.drawWideLine(0, 90, 0, 175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.drawWideLine(-20, 107, 20, 107, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawCircle(-100, 0, 4, false, ECAM_COLOURS.WHITE) -- full left
    sasl.gl.drawCircle(-50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(100, 0, 4, false, ECAM_COLOURS.WHITE) -- full right

    sasl.gl.drawWideLine(0 + (50 * get(navhdev)), 80, 0 + (50 * get(navhdev)), -80, 3, ECAM_COLOURS.PURPLE) -- Horizontal Deviation bar
    sasl.gl.drawWidePolyLine({-10 + (50 * get(navhdev)), 70, 0 + (50 * get(navhdev)), 80, 10 + (50 * get(navhdev)), 70}, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawWideLine(0, -90, 0, -175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.restoreGraphicsContext ()

    sasl.gl.drawRotatedTexture(rose, -1 * get(heading), 0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawWideLine(250, 417, 250, 433, 3, ECAM_COLOURS.YELLOW )
    sasl.gl.drawTexture(miniplane, 225, 216, 50, 50, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_vor_unaligned()
    sasl.gl.drawText(ndFont, 450, 475, "VOR1  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 475, string.format("%.2f", get(navfreq) / 100), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 460, 455, "CRS  ", 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 490, 455, string.format("%03d", (math.floor(get(navCrs) + 0.5))).."°", 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.PURPLE)
    sasl.gl.drawText(ndFont, 490, 435, get(navid), 18, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.WHITE)

    sasl.gl.saveGraphicsContext ()
    sasl.gl.setTranslateTransform (250, 250)
    sasl.gl.drawWideLine(0, 90, 0, 175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.drawWideLine(-20, 107, 20, 107, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawCircle(-100, 0, 4, false, ECAM_COLOURS.WHITE) -- full left
    sasl.gl.drawCircle(-50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(50, 0, 4, false, ECAM_COLOURS.WHITE)
    sasl.gl.drawCircle(100, 0, 4, false, ECAM_COLOURS.WHITE) -- full right

    sasl.gl.drawWideLine(0 + (50 * get(navhdev)), 80, 0 + (50 * get(navhdev)), -80, 3, ECAM_COLOURS.PURPLE) -- Horizontal Deviation bar
    sasl.gl.drawWidePolyLine({-10 + (50 * get(navhdev)), 70, 0 + (50 * get(navhdev)), 80, 10 + (50 * get(navhdev)), 70}, 3, ECAM_COLOURS.PURPLE)

    sasl.gl.drawWideLine(0, -90, 0, -175, 3, ECAM_COLOURS.PURPLE)
    sasl.gl.restoreGraphicsContext ()

    sasl.gl.drawCircle(250, 250, 6, true, ECAM_COLOURS.RED)
    sasl.gl.drawCircle(250, 250, 4, true, {0.0, 0.0, 0.0, 1.0})
    sasl.gl.drawTexture(rose_unaligned,0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 250, 345, "HDG", 30, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_nav()
    sasl.gl.drawTexture(miniplane, 225, 216, 50, 50, ECAM_COLOURS.WHITE)
    sasl.gl.drawRotatedTexture(rose, -1 * get(heading), 0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawWideLine(250, 417, 250, 433, 3, ECAM_COLOURS.YELLOW )
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_nav_unaligned()
    sasl.gl.drawCircle(250, 250, 6, true, ECAM_COLOURS.RED)
    sasl.gl.drawCircle(250, 250, 4, true, {0.0, 0.0, 0.0, 1.0})
    sasl.gl.drawTexture(rose_unaligned,0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 250, 345, "HDG", 30, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
    sasl.gl.drawText(ndFont, 250, 285, "MAP NOT AVAIL", 27, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
    sasl.gl.drawText(ndFont, 125, 126, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 190, 191, get(CaptNdRnge) / 4, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
end

local function draw_arc()
    if get(CaptNdWPT) == 1 then
        if get(CaptNdRnge) <= 80 then
            draw_waypoints()
        end
    end
    if get(CaptNdVORD) == 1 then
        if get(CaptNdRnge) <= 160 then
            draw_vors()
        end
    end
    if get(CaptNdNDB) == 1 then
        if get(CaptNdRnge) <= 160 then
            draw_ndbs()
        end
    end
    sasl.gl.drawTexture(arcMask, 0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawTexture(miniplane, 225, 50, 50, 50, ECAM_COLOURS.WHITE)
    sasl.gl.drawRotatedTexture(arcTape, -1 * get(heading), -123, -290, 746, 746, ECAM_COLOURS.WHITE)
    sasl.gl.drawWideLine(250, 398, 250, 425, 3, ECAM_COLOURS.YELLOW )

    sasl.gl.setInternalLineWidth(2.0)
    sasl.gl.setInternalLineStipple(true, 8, 0xAAAA)
    sasl.gl.drawArcLine(250, 83, 247, 15, 150.0, ECAM_COLOURS.WHITE)
    sasl.gl.drawArcLine(250, 83, 164, 15, 150.0, ECAM_COLOURS.WHITE)
    sasl.gl.drawArcLine(250, 83, 81, 15, 150.0, ECAM_COLOURS.WHITE)
    sasl.gl.setInternalLineWidth(1.0)
    sasl.gl.setInternalLineStipple( false)
    sasl.gl.drawText(ndFont, 110, 150, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 35, 187, 3 * (get(CaptNdRnge) / 4), 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 390, 150, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 465, 187, 3 * (get(CaptNdRnge) / 4), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.BLUE)
end

local function draw_arc_unaligned()
    sasl.gl.drawTexture(arcTape_unaligned, -123, -290, 746, 746, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 250, 345, "HDG", 30, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
    sasl.gl.drawText(ndFont, 250, 285, "MAP NOT AVAIL", 27, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)

    sasl.gl.setInternalLineWidth(2.0)
    sasl.gl.setInternalLineStipple(true, 8, 0xAAAA)
    sasl.gl.drawArcLine(250, 83, 247, 15, 150.0, ECAM_COLOURS.RED)
    sasl.gl.drawArcLine(250, 83, 164, 15, 150.0, ECAM_COLOURS.RED)
    sasl.gl.drawArcLine(250, 83, 81, 15, 150.0, ECAM_COLOURS.RED)
    sasl.gl.setInternalLineWidth(1.0)
    sasl.gl.setInternalLineStipple( false)
    sasl.gl.drawText(ndFont, 110, 150, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 35, 187, 3 * (get(CaptNdRnge) / 4), 15, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 390, 150, get(CaptNdRnge) / 2, 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.BLUE)
    sasl.gl.drawText(ndFont, 465, 187, 3 * (get(CaptNdRnge) / 4), 15, false, false, TEXT_ALIGN_RIGHT, ECAM_COLOURS.BLUE)


    sasl.gl.drawCircle(250, 83, 6, true, ECAM_COLOURS.RED)
    sasl.gl.drawCircle(250, 83, 4, true, {0.0, 0.0, 0.0, 1.0})
end

local function draw_unavail()
    sasl.gl.drawCircle(250, 250, 6, true, ECAM_COLOURS.RED)
    sasl.gl.drawCircle(250, 250, 4, true, {0.0, 0.0, 0.0, 1.0})
    sasl.gl.drawTexture(rose_unaligned,0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawText(ndFont, 250, 285, "MAP NOT AVAIL", 27, false, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.RED)
end

local function draw_plan()
    sasl.gl.drawTexture(miniplane, 225, 225, 50, 50, ECAM_COLOURS.WHITE)
    sasl.gl.drawRotatedTexture(rose, -1 * get(heading), 0, 0, 500, 500, ECAM_COLOURS.WHITE)
    sasl.gl.drawWideLine(250, 417, 250, 433, 3, ECAM_COLOURS.YELLOW )
end

function draw_waypoints()
    if enrouteWaypoints[latGroup][lonGroup] ~= nil then
        for i, wpt in ipairs(enrouteWaypoints[latGroup][lonGroup]) do
            local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
            sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
            sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
        end
    end

    for u=-1,1 do
        if enrouteWaypoints[latGroup + u][lonGroup - 2] ~= nil then
            for i, wpt in ipairs(enrouteWaypoints[latGroup + u][lonGroup - 2]) do
                local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
        if enrouteWaypoints[latGroup + u][lonGroup - 1] ~= nil then
            for i, wpt in ipairs(enrouteWaypoints[latGroup + u][lonGroup - 1]) do
                local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
        if u ~= 0 then
            if enrouteWaypoints[latGroup + u][lonGroup] ~= nil then
                for i, wpt in ipairs(enrouteWaypoints[latGroup + u][lonGroup]) do
                    local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if enrouteWaypoints[latGroup + u][lonGroup + 1] ~= nil then
            for i, wpt in ipairs(enrouteWaypoints[latGroup + u][lonGroup + 1]) do
                local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
        if enrouteWaypoints[latGroup + u][lonGroup + 2] ~= nil then
            for i, wpt in ipairs(enrouteWaypoints[latGroup + u][lonGroup + 2]) do
                local x, y = recomputePoint(get(wpt.lat), get(wpt.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 25, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(wpt.fixId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
    end
end

function draw_vors()
    if enrouteNavaids[latGroup][lonGroup] ~= nil then
        for i, vor in ipairs(enrouteNavaids[latGroup][lonGroup]) do
            if get(vor.navType) == "3" then
                local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
    end    

    for u=-1,1 do
        if enrouteNavaids[latGroup + u][lonGroup - 2] ~= nil then
            for i, vor in ipairs(enrouteNavaids[latGroup + u][lonGroup - 2]) do
                if get(vor.navType) == "3" then
                    local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup - 1] ~= nil then
            for i, vor in ipairs(enrouteNavaids[latGroup + u][lonGroup - 1]) do
                if get(vor.navType) == "3" then
                    local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if u ~= 0 then
            if enrouteNavaids[latGroup + u][lonGroup] ~= nil then
                for i, vor in ipairs(enrouteNavaids[latGroup + u][lonGroup]) do
                    if get(vor.navType) == "2" then
                        local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                        sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                        sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                    end
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup + 1] ~= nil then
            for i, vor in ipairs(enrouteNavaids[latGroup + u][lonGroup + 1]) do
                if get(vor.navType) == "3" then
                    local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup + 2] ~= nil then
            for i, vor in ipairs(enrouteNavaids[latGroup + u][lonGroup + 2]) do
                if get(vor.navType) == "3" then
                    local x, y = recomputePoint(get(vor.lat), get(vor.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 75, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(vor.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
    end
end

function draw_ndbs()
    if enrouteNavaids[latGroup][lonGroup] ~= nil then
        for i, ndb in ipairs(enrouteNavaids[latGroup][lonGroup]) do
            if get(ndb.navType) == "2" then
                local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
    end    

    for u=-1,1 do
        if enrouteNavaids[latGroup + u][lonGroup - 2] ~= nil then
            for i, ndb in ipairs(enrouteNavaids[latGroup + u][lonGroup - 2]) do
                if get(ndb.navType) == "2" then
                    local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup - 1] ~= nil then
            for i, ndb in ipairs(enrouteNavaids[latGroup + u][lonGroup - 1]) do
                if get(ndb.navType) == "2" then
                    local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if u ~= 0 then
            if enrouteNavaids[latGroup + u][lonGroup] ~= nil then
                for i, ndb in ipairs(enrouteNavaids[latGroup + u][lonGroup]) do
                    if get(ndb.navType) == "2" then
                        local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                        sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                        sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                    end
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup + 1] ~= nil then
            for i, ndb in ipairs(enrouteNavaids[latGroup + u][lonGroup + 1]) do
                if get(ndb.navType) == "2" then
                    local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
        if enrouteNavaids[latGroup + u][lonGroup + 2] ~= nil then
            for i, ndb in ipairs(enrouteNavaids[latGroup + u][lonGroup + 2]) do
                if get(ndb.navType) == "2" then
                    local x, y = recomputePoint(get(ndb.lat), get(ndb.lon), get(currentLat), get(currentLon), get(CaptNdRnge), get(heading), 330)
                    sasl.gl.drawTexturePart(symbols, (242 + x), 75 + y, 16, 16, 100, 100, 25, 25, ECAM_COLOURS.WHITE)
                    sasl.gl.drawText(ndFont, (260 + x), 65 + y, get(ndb.navId), 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
                end
            end
        end
    end
end

function setup()
    local path = getXPlanePath()
    local earthFix = path .. "/Custom Data/earth_fix.dat"
    local earthNav = path .. "/Custom Data/earth_nav.dat"
    
    if not isFileExists(earthFix) then
        earthFix = path .. "/Resources/default data/earth_fix.dat"
    end
    if not isFileExists(earthNav) then
        earthNav = path .. "/Resources/default data/earth_nav.dat"
    end

    readFileLines(earthFix, addWaypoint)
    readFileLines(earthNav, addNavaid)
end

local function tableContains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end

function readFileLines(path, lineFunction)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local lineNumber = 0
    for line in io.lines(path) do
        lineNumber = lineNumber + 1
        if lineNumber > 4 then
            lineFunction(line)
        end
    end

    file:close()
end

function addFplanWpt(line)
    local lat, lon, fixId, airportId, icaoRegion, waypointType = line:match("([%d%-%.]+)%s+([%d%-%.]+)%s+(%w+)%s+(%w+)%s+(%w+)%s+(%d+)")
    if not lon then
        return false
    end
end


function addWaypoint(line)
    local lat, lon, fixId, airportId, icaoRegion, waypointType = line:match("([%d%-%.]+)%s+([%d%-%.]+)%s+(%w+)%s+(%w+)%s+(%w+)%s+(%d+)")
    if not lon then
        return false
    end
    if airportId == "ENRT" then
        return addEnrouteWaypoint(lat, lon, fixId, airportId, icaoRegion, waypointType)
    end
end

function addNavaid(line)
    local navType, lat, lon, elev, freq, class, slavedVar, navId, airportId, icaoRegion, navName = line:match("(%d+)%s+([%d%-%.]+)%s+([%d%-%.]+)%s+(%d+)%s+(%d+)%s+([%d%-%.]+)%s+([%d%-%.]+)%s+(%w+)%s+(%w+)%s+(%w+)%s+(%w+)")
    if not lon then
        return false
    end

    if navType == "2" or navType == "3" then
        return addEnrouteNavaid(navType, lat, lon, navId)
    end
end

function group(num)
    return math.floor(num)
end

function addEnrouteWaypoint(lat, lon, fixId, airportId, icaoRegion, waypointType)
    local latGroup = group(lat)
    local lonGroup = group(lon)
    if type(enrouteWaypoints[latGroup]) ~= "table" then
        enrouteWaypoints[latGroup] = {}
    end
    if type(enrouteWaypoints[latGroup][lonGroup]) ~= "table" then
        enrouteWaypoints[latGroup][lonGroup] = {}
    end
    table.insert(enrouteWaypoints[latGroup][lonGroup], {lat = lat, lon = lon, fixId = fixId, airportId = airportId, icaoRegion = icaoRegion, waypointType = waypointType})
end

function addEnrouteNavaid(navType, lat, lon, navId)
    local latGroup = group(lat)
    local lonGroup = group(lon)
    if type(enrouteNavaids[latGroup]) ~= "table" then
        enrouteNavaids[latGroup] = {}
    end
    if type(enrouteNavaids[latGroup][lonGroup]) ~= "table" then
        enrouteNavaids[latGroup][lonGroup] = {}
    end
    --print("type: '".. navType .. "'" .. " Lat: '" .. lat .. "'" .. " Lon: '" .. lon .. "'" .. " ID: '" .. navId .. "'" .. " LatGroup: '" .. latGroup .. "' LonGroup: '" .. lonGroup .. "'")
    table.insert(enrouteNavaids[latGroup][lonGroup], {navType = navType, lat = lat, lon = lon, navId = navId})
end

local function gnome(lat, lon, clat, clon)
    local sin = math.sin
    local cos = math.cos
    local cosc = sin(clat) * sin(lat) + cos(clat) * cos(lat) * cos(lon - clon)
    local x = (cos(lat) * sin(lon - clon)) / cosc
    local y = (cos(clat) * sin(lat) - sin(clat) * cos(lat) * cos(lon - clon)) / cosc
    return x, y
end


local function haversine(lat1, lon1, lat2, lon2)
    local sin = math.sin
    local cos = math.cos
    local dLat = (lat2 - lat1)
    local dLon = (lon2 - lon1)
    local h = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
    local c = 2 * math.asin(h ^ .5) * 3440.1
    return c
end

local WPTS

function createTokens(str, separator)
    local tokens = {}
    for token in string.gmatch(str, "[^%"..separator.."]+") do
        table.insert(tokens, token)
    end
    return tokens
end

function getBasicLatLong(icao)
    local path = getXPlanePath()
--    if isFileExists(path.."/Resources/default data/CIFP/"..icao..".dat", "r") then
    local file = assert(io.open(path.."/Resources/default data/CIFP/"..icao..".dat", "r"))
    local str = ""
    io.input(file)
    for line in io.lines() do
        if string.match(line, "RWY") then
            str = line
            break
        end
    end
        local firstTokenSet = createTokens(str, ";")[2]
        local secondTokenSet = createTokens(firstTokenSet, ",")
        file:close()
        if string.sub(tostring(secondTokenSet[1]),1,1) == "S" then
            secondTokenSet[1] = -1 * (tonumber(string.sub(tostring(secondTokenSet[1]),2,-1)))*(10^(-6))
        else
            secondTokenSet[1] = tonumber(string.sub(tostring(secondTokenSet[1]),2,-1))*(10^(-6))
        end
        if string.sub(tostring(secondTokenSet[2]),1,1) == "W" then
            secondTokenSet[2] = -1 * (tonumber(string.sub(tostring(secondTokenSet[2]),2,-1)))*(10^(-6))
        else
            secondTokenSet[2] = (tonumber(string.sub(tostring(secondTokenSet[2]),2,-1)))*(10^(-6))
        end
        return {secondTokenSet[1], secondTokenSet[2]}
 --   else
--        print("DIABETES")
 --       return "0"
   -- end
end


function checkICAO(icao)
    local path = getXPlanePath() --gets the xplane path
    local file = io.open(path.."/Custom Data/CIFP/"..icao..".dat", "r")
    if file ~= nil then
        file:close()
        return true
    end
    file = io.open(path.."/Resources/default data/CIFP/"..icao..".dat", "r")
    if file ~= nil then
        file:close()
        return true
    end
    return false
end

local function draw_flight_plan() -- WE DRAW THE FLIGHT PLAN POINTS
    if #fplanWpts ~= WPTS then
        fplanWptLatLong = {}
        local path = getXPlanePath()
        local earthFix = path .. "/Custom Data/earth_fix.dat"
        local earthNav = path .. "/Custom Data/earth_nav.dat"

        if not isFileExists(earthFix) then
            earthFix = path .. "/Resources/default data/earth_fix.dat"
        end
        if not isFileExists(earthNav) then
            earthNav = path .. "/Resources/default data/earth_nav.dat"
        end

        if #fplanWpts ~= 0 then
            for i in ipairs(fplanWpts) do
                if i == 1 and checkICAO(fplanWpts[1]) then
                    local dptCoord = getBasicLatLong(fplanWpts[1])
                    fplanWptLatLong[1] = dptCoord[1]
                    fplanWptLatLong[2] = dptCoord[2]
                elseif i~=1 and string.len(fplanWpts[i]) <= 3 then
                    local file = io.open(earthNav, "rb")
                    for line in io.lines(earthNav) do
                        if string.find(line,fplanWpts[i]) then
                            local navType, lat, lon, elev, freq, class, slavedVar, navId, airportId, icaoRegion, navName = line:match("(%d+)%s+([%d%-%.]+)%s+([%d%-%.]+)%s+(%d+)%s+(%d+)%s+([%d%-%.]+)%s+([%d%-%.]+)%s+(%w+)%s+(%w+)%s+(%w+)%s+(%w+)")
                            table.insert(fplanWptLatLong,2,lat)
                            table.insert(fplanWptLatLong,2,lon)
                        end
                    end
                    file:close()
                else
                    local file = io.open(earthFix, "rb")
                    for line in io.lines(earthFix) do
                        if string.find(line,fplanWpts[i]) then
                            local lat, lon, fixId, airportId, icaoRegion, waypointType = line:match("([%d%-%.]+)%s+([%d%-%.]+)%s+(%w+)%s+(%w+)%s+(%w+)%s+(%d+)")
                            table.insert(fplanWptLatLong,2,lat)
                            table.insert(fplanWptLatLong,2,lon)
                        end
                    end
                    file:close()
                end
            end
        end
        WPTS = #fplanWpts
    end
    fplanWptXY = {}
    if #fplanWptLatLong > 2 then
        -- print('-----------')
        -- print(#fplanWptLatLong)
        for i=#fplanWptLatLong,1,-2 do
            if fplanWptLatLong[i] ~= nil and fplanWptLatLong[i+1] ~= nil then
                local x,y = recomputePoint(fplanWptLatLong[i+1],fplanWptLatLong[i],get(currentLat),get(currentLon),get(CaptNdRnge),get(heading),330)
--                print(i,":",fplanWptLatLong[i-1],fplanWptLatLong[i+1])
                table.insert(fplanWptXY,#fplanWptXY+1,x+242)
                table.insert(fplanWptXY,#fplanWptXY+1,y+95)
            end
        end
        sasl.gl.drawWidePolyLine(fplanWptXY,4,ECAM_COLOURS.GREEN) -- we draw the flight plan line using the table of x and y coords
        for i in ipairs(fplanWpts) do -- Draw Wpt Markers
            if fplanWptXY[(2*i)-1] ~= nil and fplanWptXY[2*i] ~= nil then
                sasl.gl.drawText(ndFont, fplanWptXY[(2*i)-1], fplanWptXY[2*i], "X", 15, true, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.PURPLE)
            end
        end
        for i in ipairs(fplanWpts) do -- Draw Wpt Labels
            if fplanWptXY[(2*i)-1] ~= nil and fplanWptXY[2*i] ~= nil then
                sasl.gl.drawText(ndFont, fplanWptXY[(2*i)-1], fplanWptXY[2*i], fplanWpts[i], 20, false, false, TEXT_ALIGN_LEFT, ECAM_COLOURS.GREEN)
            end
        end
    end
end

function recomputePoint(lat, lon, centerLat, centerLon, range, hdg, iscale)
    lat = math.rad(lat)
    lon = math.rad(lon)
    centerLat = math.rad(centerLat)
    centerLon = math.rad(centerLon)
    local hd = haversine(centerLat, centerLon, lat, lon)
    local force = (hd / range)
    local gx, gy = gnome(lat, lon, centerLat, centerLon)
    local d = math.sqrt(gx ^ 2 + gy ^ 2)
    local nfx = -(gx / d) * force
    local nfy = -(gy / d) * force
    local fx = nfx
    local fy = nfy
    local x, y = -fx * iscale, -fy * iscale
    local a = x * math.cos(math.rad(hdg)) - y * math.sin(math.rad(hdg))
    local b = x * math.sin(math.rad(hdg)) + y * math.cos(math.rad(hdg))

    return a, b
end


function update()

    latGroup = group(get(currentLat))
    lonGroup = group(get(currentLon))


    if not setupComplete then
        setup()
        setupComplete = true
    end

    if not startup_complete then
        plane_startup()
        startup_complete = true
    end

    if get(rngeKnob) == 6 then
        set(rngeKnob, 5)
    end

    if get(CaptNdMode) > 4 then
        set(CaptNdMode, 4)
    end

    if get(rngeKnob) == 0 then
        CaptNdRnge = 10
    elseif get(rngeKnob) == 1 then
        CaptNdRnge = 20
    elseif get(rngeKnob) == 2 then
        CaptNdRnge = 40
    elseif get(rngeKnob) == 3 then
        CaptNdRnge = 80
    elseif get(rngeKnob) == 4 then
        CaptNdRnge = 160
    elseif get(rngeKnob) == 5 then
        CaptNdRnge = 320
    end

    if Timer < TimerFinal and selfTest == 0 then
        Timer = Timer + 1 * get(DELTA_TIME)
    else
        selfTest = 1
    end
end

function draw()
    sasl.gl.setClipArea(0,0,500,500)
    if get(BUS) > 0 then
        if selfTest == 1 then
            if get(CaptNdMode) == 0 then
                if get(ADIRS_aligned) == 0 or get(ADIRS_mode) == 2 then
                    draw_ils_unaligned()
                else
                    draw_ils()
                end
            elseif get(CaptNdMode) == 1 then
                if get(ADIRS_aligned) == 0 or get(ADIRS_mode) == 2 then
                    draw_vor_unaligned()
                else
                    draw_vor()
                end
            elseif get(CaptNdMode) == 2 then
                if get(ADIRS_aligned) == 0 or get(ADIRS_mode) == 2 then
                    draw_nav_unaligned()
                else
                    draw_nav()
                end
            elseif get(CaptNdMode) == 3 then
                if get(ADIRS_aligned) == 0 or get(ADIRS_mode) == 2 then
                    draw_arc_unaligned()
                else
                    draw_arc()
                    draw_flight_plan()
                   -- draw_flight_plan()
                end
            elseif get(CaptNdMode) == 4 then
                if get(ADIRS_aligned) == 0 then
                    draw_unavail()
                else
                    draw_unavail()
                end
            end
            draw_overlay_text()
            Timer = 0
        else
            sasl.gl.drawText(AirbusFont, 250, 255, "SELF TEST IN PROGESS", 22, true, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.GREEN)
            sasl.gl.drawText(AirbusFont, 250, 230, "MAX 40 SECONDS", 21, true, false, TEXT_ALIGN_CENTER, ECAM_COLOURS.GREEN)
        end
        --sasl.gl.drawRectangle(0,0,500,500, {0.33, 0.38, 0.42, 0.35 * get(captNdBright)})
    else
        Timer = 0
        selfTest = 0
    end

    
    sasl.gl.drawRectangle(0,0,500,500, {0.0, 0.0, 0.0, 1 - get(captNdBright)})

    sasl.gl.resetClipArea()
end
