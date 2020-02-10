oo::class create SocketServer {
    # variable MTCL_OBJ

    variable sock
    variable closed
    variable connected
    variable ack
    variable command

    #Wait for the client to come back and say they are closing
    method serverVwait {} {
        my variable connected
        puts "waiting for event"
        vwait [my varname connected]
    }

    # Handler for socket traffic
    method handleComm {} {
        my variable sock
        my variable closed
        my variable ack
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
            if {[lindex $rxStr 0] == "mtclCmd"} {
                puts "FOUND a mtclCmd! CMD = [lindex $rxStr 1]"
                # puts $sock [lindex $rxStr 1]
                catch {uplevel #0 [lindex $rxStr 1]} result
            }
            # Increment ack to trigger events. Use the absolute variable name
            incr [my varname ack]
        }
    }

    # Accept connections
    method accept {chan addr port} {
        my variable sock
        my variable connected 
        # Save the channel to the sock variable for this instance
        set sock $chan

        # automate flushing
        fconfigure $sock -buffering line     

        puts "$addr:$port connected"

        #Test code
        # send "hi there"

        set connected true
        puts "accept - connected = $connected"
                  
        # set up to handle incoming data when necessary
        fileevent $sock readable [list [self object] handleComm]
    } 

    # Utility for pushing data over the socket
    method send {cmd {blocking false}} {
        my variable sock
        my variable ack
        # Push the string over the sock channel
        puts $sock $cmd
        flush $sock
        if {$blocking} {
            # puts "  waiting for ack event"
            vwait [my varname ack]
            # puts "  ACK'D"
        }
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
        my variable closed
        my variable connected
        my variable ack
        set closed false
        set connected false
        set ack 0

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