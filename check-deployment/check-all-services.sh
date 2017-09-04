#!/usr/bin/awk -f

BEGIN {
    #dryrun=1
}

/^#.*/     { next }
(NF == 2)  {
    service_name = $1
    service_port = $2
    cmd="./check-service.sh '" service_name "' " service_port
    run(cmd)
}

END   {}

function run ( command ) {
    if (dryrun) {
         print("      - would run: " command);
    } else {
        while (command |& getline output) print output
    }
}
