extends RefCounted

const SCRIPT_PATH = "res://windows/create_shortcut.ps1"

static func available() -> bool:
 return OS.get_name() == "Windows" and not OS.has_feature("editor")

static func powershell_literal(value: String) -> String:
 # A literal, not executable text: apostrophes are doubled in PowerShell.
 return "'"+value.replace("'","''")+"'"

static func command_for(executable: String) -> String:
 return "$env:DOWNSTACK_SHORTCUT_TARGET="+powershell_literal(executable)+";\n"+FileAccess.get_file_as_string(SCRIPT_PATH)

static func create() -> Dictionary:
 if not available():
  return {"ok":false,"message":"Desktop shortcut creation is available in the Windows release."}
 var executable = OS.get_executable_path()
 if not FileAccess.file_exists(executable.get_basename()+".pck"):
  return {"ok":false,"message":"Extract the entire ZIP first. Keep Downstack.exe and Downstack.pck together."}
 var powershell = OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
 if not FileAccess.file_exists(powershell):
  return {"ok":false,"message":"Windows PowerShell is unavailable. Right-click Downstack.exe and use Send to > Desktop (create shortcut)."}
 var output = []
 var code = OS.execute(powershell,PackedStringArray(["-NoLogo","-NoProfile","-NonInteractive","-Command",command_for(executable)]),output,true,false)
 if code != 0:
  return {"ok":false,"message":"Could not create the shortcut. "+"\n".join(output).strip_edges().left(650)}
 return {"ok":true,"message":"Desktop shortcut created with the T icon. Keep this game folder in place."}
