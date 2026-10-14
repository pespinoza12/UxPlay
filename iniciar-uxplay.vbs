' Arranca UxPlay ("PC Pedro") oculto, sin ventana de consola.
' Si ya está corriendo, no hace nada. El log queda en C:\tools\UxPlay\uxplay.log
' Con el argumento "inicio" (lo usa el arranque de Windows) espera hasta 2 min a que haya red.
Set sh = CreateObject("WScript.Shell")
Set wmi = GetObject("winmgmts:\\.\root\cimv2")
If wmi.ExecQuery("select * from Win32_Process where Name='uxplay.exe'").Count > 0 Then WScript.Quit

If WScript.Arguments.Count > 0 Then
    If WScript.Arguments(0) = "inicio" Then
        For i = 1 To 24
            hayRed = False
            For Each a In wmi.ExecQuery("select DefaultIPGateway from Win32_NetworkAdapterConfiguration where IPEnabled=True")
                If Not IsNull(a.DefaultIPGateway) Then hayRed = True
            Next
            If hayRed Then Exit For
            WScript.Sleep 5000
        Next
        WScript.Sleep 3000
    End If
End If

Set env = sh.Environment("PROCESS")
env("PATH") = "C:\msys64\ucrt64\bin;" & env("PATH")
sh.CurrentDirectory = "C:\msys64\ucrt64\bin"
sh.Run "cmd /c """"C:\tools\UxPlay\build\uxplay.exe"" -n ""PC Pedro"" -nh -vs d3d11videosink -as wasapi2sink > ""C:\tools\UxPlay\uxplay.log"" 2>&1""", 0, False
