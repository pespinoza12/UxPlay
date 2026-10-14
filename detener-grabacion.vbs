' Termina el modo grabación: apaga UxPlay, convierte las tomas a MP4 editables
' (C:\Users\pedro\Videos\iPhone) y deja UxPlay de nuevo en modo normal, sin grabar.
Set sh = CreateObject("WScript.Shell")
sh.Run "taskkill /IM uxplay.exe /F", 0, True
WScript.Sleep 1500

sh.Popup "Convirtiendo las tomas… te aviso al terminar.", 3, "UxPlay", 64
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File ""C:\tools\UxPlay\convertir-grabaciones.ps1""", 0, True

sh.Run "wscript ""C:\tools\UxPlay\iniciar-uxplay.vbs""", 0, False
sh.Popup "Listo. Las tomas están en Videos\iPhone." & vbCrLf & "UxPlay sigue disponible, sin grabar.", 8, "UxPlay", 64
sh.Run "explorer ""C:\Users\pedro\Videos\iPhone""", 1, False
