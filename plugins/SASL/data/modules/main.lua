sasl.options.setAircraftPanelRendering(true)
sasl.options.set3DRendering(false)
sasl.options.setInteractivity(true)
addSearchPath(moduleDirectory.."/images/")
addSearchPath(moduleDirectory .. "/Custom Module/ADIRS/")
addSearchPath(moduleDirectory .. "/Custom Module/PFD/")
addSearchPath(moduleDirectory .. "/Custom Module/ND/")
addSearchPath(moduleDirectory .. "/Custom Module/ECAM/")
addSearchPath(moduleDirectory .. "/Custom Module/ATSAW/")
addSearchPath(moduleDirectory .. "/Custom Module/efb/")
addSearchPath(moduleDirectory .. "/Custom Module/MCDU/")
addSearchPath(moduleDirectory .. "/Custom Module/Comms/")
addSearchPath(moduleDirectory .. "/Custom Module/DCDU")
addSearchPath(moduleDirectory .. "/Custom Module/MCDU_Rewrite")
addSearchPath(moduleDirectory .. "/Custom Module/autopilot")


size = {4096, 4096}

panelWidth3d = 4096
panelHeight3d = 4096


MCDU_DISPLAY = sasl.gl.createTexture(500, 510)

fplanWpts = {}

components = {
  customdataref {};
  elec {};
  FADEC {};
  ADIRS {};
  fuel {};
  hydraulics {};
  bleed {};
  fltwrngsys {};
  mcdu {
    fbo = true ,
    fpsLimit = 29
  };
  PFD_CAPT {
    fbo = true ,
    fpsLimit = 29
  };
  PFD_FRST {
    fbo = true ,
    fpsLimit = 29
  };
  upper_ecam {
    fbo = true ,
    fpsLimit = 20
  };
  lower_ecam {
    fbo = true ,
    fpsLimit = 20
  };
  --[[Radio {
		fbo = true ,
		fpsLimit = 20
	};]]--
  --[[transponder {
		fbo = true ,
		fpsLimit = 20
	}; ]]--
--   efb{
--     cursor = {
--       x = -15 ,
--       y = -15 ,
--       width = 30 ,
--       height = 30 ,
--       shape = sasl.gl.loadImage ("efb/icons/cursor.png") ,
--       hideOSCursor = true
--       },
--       fbo = true,
--       fpsLimit = 20
--   };
  cockpit {};
  DCDUmain {
    fbo = true,
    fpsLimit = 20
  };
  autopilot {};
  --maintenance {};
  ND_CAPT {
    fbo = true ,
    fpsLimit = 29
  };
  ND_FRST {
    fbo = true ,
    fpsLimit = 29
  };
  mcdu2 {};
  panel_drawing {};
  menu {};
  autopilot_main {};
  cockpitlighting {};
}
