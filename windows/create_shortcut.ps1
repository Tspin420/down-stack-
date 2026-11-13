# Used by the in-game button and the generated double-click CMD helper.
# The target is passed as data. No administrator access or policy change.
$ErrorActionPreference = 'Stop';
try {
    $exe = [IO.Path]::GetFullPath($env:DOWNSTACK_SHORTCUT_TARGET);
    $folder = [IO.Path]::GetDirectoryName($exe);
    if (([IO.Path]::GetFileName($exe) -ne 'Downstack.exe') -or !(Test-Path -LiteralPath $exe -PathType Leaf) -or !(Test-Path -LiteralPath ([IO.Path]::ChangeExtension($exe, '.pck')) -PathType Leaf)) { throw 'Extract the entire ZIP first and keep Downstack.exe and Downstack.pck together.'; };
    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory);
    if ([string]::IsNullOrWhiteSpace($desktop) -or !(Test-Path -LiteralPath $desktop -PathType Container)) { throw 'Your Windows Desktop folder is unavailable.'; };
    $path = [IO.Path]::Combine($desktop, 'Downstack.lnk');
    $shell = New-Object -ComObject WScript.Shell;
    $shortcut = $shell.CreateShortcut($path);
    if ((Test-Path -LiteralPath $path) -and ([IO.Path]::GetFileName($shortcut.TargetPath) -ne 'Downstack.exe')) { throw 'A different shortcut named Downstack already exists on your desktop. Rename it first.'; };
    $shortcut.TargetPath = $exe;
    $shortcut.Arguments = '';
    $shortcut.WorkingDirectory = $folder;
    $shortcut.IconLocation = $exe + ',0';
    $shortcut.Description = 'Downstack';
    $shortcut.WindowStyle = 1;
    $shortcut.Save();
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Windows did not save the shortcut.'; };
    $saved = $shell.CreateShortcut($path);
    if (($saved.TargetPath -ne $exe) -or ($saved.WorkingDirectory -ne $folder)) { throw 'Windows did not save the expected shortcut target. Please try again.'; };
    Write-Output ('Desktop shortcut created: ' + $path);
    exit 0;
} catch {
    [Console]::Error.WriteLine($_.Exception.Message);
    exit 1;
};
