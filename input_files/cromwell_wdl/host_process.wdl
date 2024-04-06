task hostTask {
	Int i

	command {
		hostname
		sleep 0

	}
	output {
		Int taskID = i
		String result = read_string(stdout())
	}
        runtime {
        memory: "0.5 GB"
        cpu: 1
       }
}

task catHostsTask {
	Array[String] result1
	String logfile

	command {
		echo "${sep=';' result1}"| tr ";" "\n" | sort > ${logfile}
	}
	output {
		File result = "${logfile}"
	}
        runtime {
        memory: "0.5 GB"
        cpu: 1
       }
}

workflow hostwf {
	String logfile1
	Int ntasks

        scatter (n in range(ntasks)) {
		call hostTask as host1 {input: i=n}
	}
	call catHostsTask {input: result1 = host1.result, logfile = logfile1 }
	output {
		File log = catHostsTask.result
	}
}
