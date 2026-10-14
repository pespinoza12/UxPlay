' Apaga UxPlay ("PC Pedro"): el iPhone deja de verlo hasta que lo vuelvas a iniciar.
Set sh = CreateObject("WScript.Shell")
sh.Run "taskkill /IM uxplay.exe /F", 0, True
