' Pasa UxPlay ("PC Pedro") a modo grabación: todo lo que dupliques del iPhone
' queda en C:\Users\pedro\Videos\iPhone\crudo, con la misma calidad que el modo normal (H.264, hasta 1080p).
' Cada conexión y cada giro del iPhone es un archivo aparte.
Set sh = CreateObject("WScript.Shell")
sh.Run "taskkill /IM uxplay.exe /F", 0, True
WScript.Sleep 1000

d = Now
sello = Year(d) & Right("0" & Month(d), 2) & Right("0" & Day(d), 2) & "-" & Right("0" & Hour(d), 2) & Right("0" & Minute(d), 2)
Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FolderExists("C:\Users\pedro\Videos\iPhone\crudo") Then fso.CreateFolder "C:\Users\pedro\Videos\iPhone\crudo"

Set env = sh.Environment("PROCESS")
env("PATH") = "C:\msys64\ucrt64\bin;" & env("PATH")
sh.CurrentDirectory = "C:\msys64\ucrt64\bin"
sh.Run "cmd /c """"C:\tools\UxPlay\build\uxplay.exe"" -n ""PC Pedro"" -nh -vs d3d11videosink -as wasapi2sink -mp4 C:/Users/pedro/Videos/iPhone/crudo/iphone-" & sello & " > ""C:\tools\UxPlay\uxplay.log"" 2>&1""", 0, False

sh.Popup "Grabando. Todo lo que dupliques en «PC Pedro» queda grabado." & vbCrLf & vbCrLf & _
         "Al terminar: «Dejar de duplicar» en el iPhone y después «Detener grabación».", 6, "UxPlay", 64
