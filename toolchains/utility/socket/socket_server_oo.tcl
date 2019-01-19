oo::class create SocketServer {
    # variable MTCL_OBJ

    variable sock
    variable closed
    variable command

    #Wait for the client to come back and say they are closing
    method serverVwait {} {
        vwait $closed
    }

    # Handler for socket traffic
    method handleComm {} {
        # global closed
        set rxStr [gets $sock]
        switch -exact -- $rxStr { 
            -1 { 
                #the connection was closed 
                #on the other end so close our side 
                puts "closing connection to $dns_addr $port on read eof" 
                close $sock
                return 
            } 
            0 { 
                #ignore empty messages 
                return 
            } 
        } 
        if {$rxStr == "close"} {
            puts "closing connection!"
            close $sock
            set closed true
            # exit
        } else {
            # Just print responses from the client
            # puts "FROM CLIENT - $rxStr"
            # eval $rxStr
        }
    }

    # Accept connections
    method accept {chan addr port} {   
        # Save the channel to the sock variable for this instance
        set sock $chan

        # automate flushing
        fconfigure $sock -buffering line     

        puts "$addr:$port connected"

        #Test code
        # send "hi there"
                  
        # set up to handle incoming data when necessary
        fileevent $sock readable [list [self object] handleComm]
    } 

    # Utility for pushing data over the socket
    method send {cmd} {
        # Push the string over the sock channel
        puts $sock $cmd
        flush $sock
    }

    # Handler for stdin events
    #   If we get something over stdin then simply
    #   push it out as is to the client. 
    method stdinReadHdlr {} {
        # global command 
        if [eof stdin] {
            exit
        }
        append command(line) [gets stdin]
        if [info complete $command(line)] {
            # if {$closed} {
                catch {uplevel #0 $command(line)} result
                puts "$result"
                flush stdout
            # } else {
            #     send $command(line)
            # }
            flush stdout
            set command(line) {}
        }
    }

    constructor {{port 54321}} {
        set closed    false

        # Link our stdin handler to the event
        fileevent stdin readable [list [self] stdinReadHdlr]

        # Wait for a connection
        socket -server [list [self] accept] $port
    }
    destructor {
        #Clear our handler of stdin
        # fileevent $stdin readable {}
        SocketServer destroy
    }

}