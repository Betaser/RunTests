param (
    # The file that will be validated
    $fileToValidate,
    # The data to validate against, if the program works or not
    $testData,
    # The file that validates if the program works or not according to testData
    $tester = "$PSScriptRoot\Match.java",
    [String[]] $runArgs,
    [String[]] $matchArgs
)

$buildErr = $null

function build($f, $argsArray) {
    $fullFile = $f
    $fileName = (Get-Item $f).BaseName
    $extension = (Get-Item $f).Extension.Substring(1)
    switch ($extension) {
        "java" {
            javac $fullFile
            # Java requires only the short class name, and assumes local directory
            $fullFileDir = (Get-Item $fileToValidate).Directory
            cd (Get-Item $f).Directory
            java $fileName $argsArray
            cd $fullFileDir
        }
        "cpp" {
            clang++ -o $fileName $($fileName + "." + $extension) -fno-delete-null-pointer-checks 2> MaybeErr.txt
            $maybeErr = Get-Content MaybeErr.txt
            if ($maybeErr -ne $null) {
                $maybeErr = [String]::Join("", $maybeErr)
                $atTilda = $maybeErr.IndexOf("~~~")
                $atNativeCommandError = $maybeErr.LastIndexOf("NativeCommandError ")
                $maybeErr = $maybeErr.Substring(0, $atTilda) + $maybeErr.Substring($atNativeCommandError + "NativeCommandError".Length)
                throw $maybeErr
                return
            }
            & $(".\" + $fileName + ".exe")
        }
        default {
            Write_Error "File extension not recognized as a buildable file type"
        }
    }
}

# Sets output to a list of lines
# Ok, Get-Content without -raw strips newlines, and so does output

Write-Host "building $fileToValidate"
$rawOutput = "RawOutput.txt"
try {
    $out = build $fileToValidate $runArgs
    $out *> $rawOutput
} catch {
    Write-Host $_
    Write-Host "File failed to build."
    exit
}

$output = (Get-Content $rawOutput -raw).split("`n")
$output = $output.replace("`"", "\`"")
rm $rawOutput

$testData = (Get-Content $testData -raw).split("`n")
$testData = $testData.replace("`"", "\`"")

Write-Host "Running test `"$tester`"..."

# Let's define the lists of strings by specifying the length of the first list as the first element of the large list
$argsList = New-Object System.Collections.Generic.List[System.Object]
$argsList.Add($output.Count - 1)
foreach ($line in $output) {
    $argsList.Add($line)
}
foreach ($line in $testData) {
    $argsList.Add($line)
}
foreach ($argu in $matchArgs) {
    $argsList.Add($argu)
}
build $tester $argsList
