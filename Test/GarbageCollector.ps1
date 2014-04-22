if (($i % 200) -eq 0){
    [System.GC]::Collect()
}