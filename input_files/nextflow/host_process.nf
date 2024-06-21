params.ntasks = 1   // Default value

process host1 {
    ARRAY
    memory '0.5 GB'
    input:
        val n

    output:
        val n
	stdout

    script:
    """
    hostname
    """
}

workflow {
  ntasks1 = Channel.from(1..params.ntasks)
  (n, hname) = host1(ntasks1)
  hname.view() { hname -> "hostname_h1: $hname" }
}
