# -----------------------
# SOCKET TESTING
# -----------------------
global sock
global closed
set closed false

# Utility for pushing data over the socket
proc sockSend {cmd} {
    global sock
    puts $sock $cmd
    flush $sock
}

# Handler for socket traffic
proc handleComm {S} {
    global closed

    if {[eof $S]} {
        close $S
        fileevent stdin readable {}
        exit
    }
    set rxStr [gets $S]
    # puts "rxStr = $rxStr"
    # puts "message of length $rxStr recieved" 
    switch -exact -- $rxStr { 
        -1 { 
            #the connection was closed 
            #on the other end so close our side 
            puts "closing connection to $dns_addr $port on read eof" 
            close $S
            fileevent stdin readable {}
            exit 
        } 
        0 { 
            #ignore empty messages 
            return 
        } 
    } 
    if {$rxStr == "close"} {
        puts "closing connection!"
        sockSend "close"
        close $S
        set closed true
        fileevent stdin readable {}
        exit
    } else {
        # puts "FROM SERVER - $rxStr"
        catch {uplevel #0 $rxStr} result
        # send the result back to the server
        # puts "CLIENT - done running command $rxStr"
        # sockSend "$result"
        
        # Send something back to the server to ack that we are done
        sockSend "CLIENT - done running command $rxStr"
    }
}

# Open the connection
set sock [socket 127.0.0.1 54321]
fileevent $sock readable [list handleComm $sock]


# Handler for stdin events
#   If we get something over the socket we
#   try to evaluate it and send the results
#   back to the server.
global command 
proc StdinRead {} {
    global sock
    global command 
    # if [eof stdin] {
    #     fileevent stdin readable {}
    #     exit
    # }
    append command(line) [gets stdin]
    if [info complete $command(line)] {
        catch {uplevel #0 $command(line)} result
        # puts "I'm the client - $result"
        flush stdout
        set command(line) {}
    }
}

# Link our stdin handler to the event
# fileevent stdin readable StdinRead


vwait closed;

#Clear our handler of stdin
fileevent stdin readable {}

#Get out
exit
