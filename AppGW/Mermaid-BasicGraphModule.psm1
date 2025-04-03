Class MermaidNode {
  [String]$sourceNode
  [String]$sourceNodeLabel
  [String]$sourceNodeType   #[] () >] {{}} [()] ([]) [[]]
  [String]$destNode
  [String]$destNodeLabel
  [String]$destNodeType     #[] () >] {{}} [()] ([]) [[]]
  [String]$edgeType         #--> <--> --- <--- -.- -..- -..> -..->
  [String]$edgeLabel        #<--|Label|-->
}

function Build-MermaidTitle {
    param (
        [parameter(Mandatory=$true)][string] $title,
        [Parameter(Mandatory=$false)][ValidateSet("TD", "DT", "LR", "RL")][string] $mermaidDirection = 'TD'
    )

    $Mermaid = "---`n"
    $Mermaid += "title: $title`n"
    $Mermaid += "---`n"
    $Mermaid += "flowchart $mermaidDirection`n"

    return $Mermaid 
}

function Build-MermaidNode {
    param (
        [parameter(Mandatory=$true)][string] $sourceNode,
        [parameter(Mandatory=$true)][string] $sourceNodeLabel,
        [parameter(Mandatory=$true)][string] $sourceNodeType,
        [parameter(Mandatory=$true)][string] $destNode,
        [parameter(Mandatory=$true)][string] $destNodeLabel,
        [parameter(Mandatory=$true)][string] $destNodeType,
        [parameter(Mandatory=$true)][string] $edgeType,
        [parameter(Mandatory=$false)][string] $edgeLabel
    )

    $Mermaid = "$sourceNode$(getNodeType -nType $sourceNodeType -position 0)$sourceNodeLabel$(getNodeType -nType $sourceNodeType -position 1) $edgeType $destNode$(getNodeType -nType $destNodeType -position 0)$destNodeLabel$(getNodeType -nType $destNodeType -position 1)`n"

    return $Mermaid 
}

function getNodeType {
    param (
        [ValidateLength(2,4)][parameter(Mandatory=$true)][string] $nType,
        [validateRange(0,1)][parameter(Mandatory=$true)][int] $position # 0 = before, 1 = after
    )

    $r = ""

    #If there are errors just give the normal rectangle type based on position
    if ($position -eq 0) {
        $r = "["
    } else {
        $r = "]"
    }

    if ($nType.Length -eq 2) {
        if ($position -eq 0) {
            $r = $nType.Substring(0, 1)
        } else {
            $r = $nType.Substring($nType.Length -1, 1)
        }
    } elseif ($nType.Length -eq 4) {
        if ($position -eq 0) {
            $r = $nType.Substring(0, 2)
        } else {
            $r = $nType.Substring($nType.Length -2, 2)
        }
    }

    return $r
}

Export-ModuleMember -Function Build-MermaidTitle, Build-MermaidNode