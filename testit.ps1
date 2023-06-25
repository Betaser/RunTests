param (
    # The file that will be validated
    $fileToValidate,
    # The data to validate against, if the program works or not
    $testData,
    # The file that validates if the program works or not according to testData
    $tester = "$PSScriptRoot\Match.java",
    [String[]] $runArgs
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
            clang++ -o $fileName $($fileName + "." + $extension) -fno-delete-null-pointer-checks 6> MaybeErr.txt
            $builtIt = [String]::IsNullOrWhiteSpace((Get-Content MaybeErr.txt))
            if ($builtIt) {
                & $("./" + $fileName + ".exe")
            } else {
                throw Get-Content MaybeErr.txt
                return
            }
            rm MaybeErr.txt
        }
        default {
            Write_Error "File extension not recognized as a buildable file type"
        }
    }
}

# Sets output to a list of lines
# Ok, Get-Content without -raw strips newlines, and so does output

$rawOutput = "RawOutput.txt"
Write-Host "building $fileToValidate"
try {
    $out = build $fileToValidate $runArgs
    $out *> $rawOutput
} catch {
    $err = $_
    Write-Host $_
    #Write-Host "$($err[0].ToString()) $($err[0].InvocationInfo.PositionMessage)"
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
build $tester $argsList
