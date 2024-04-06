params.log = 'log.txt' // Default value
logfile = params.log

params.ntasks = 1   // Default value

process host1 {
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

process host2 {
    memory '0.5 GB'
    input:
        val n

    output:
    	stdout

    """
    hostname
    """
}

workflow {
  ntasks1 = Channel.from(1..params.ntasks)
  (n, hname1) = host1(ntasks1)
  hname1.view() { hname -> "hostname_h1: $hname" }
  host2(n) | view { hname -> "hostname_h2: $hname" }
}
