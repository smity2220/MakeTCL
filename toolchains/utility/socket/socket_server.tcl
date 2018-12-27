# I think I'd like to eventually implement something like this:
# 	https://github.com/tcltk/tclapps/blob/master/apps/ircbridge/cmdloop.tcl
# The cmd loop portion may not be useful, though it is quite neat.

global sock
global closed
set closed    false

# Handler for socket traffic
proc handleComm {S} {
	global closed
 	set rxStr [gets $S]
	switch -exact -- $rxStr { 
		-1 { 
			#the connection was closed 
			#on the other end so close our side 
			puts "closing connection to $dns_addr $port on read	eof" 
			close $S 
			return 
		} 
		0 { 
			#ignore empty messages 
			return 
		} 
	} 
 	if {$rxStr == "close"} {
 		puts "closing connection!"
 		close $S
 		set closed true
     	# exit
    } else {
 		# Just print responses from the client
 		# puts "FROM CLIENT - $rxStr"
 		# eval $rxStr
 	}
}


# Accept connections
proc accept {chan addr port} {   
	global sock
	set sock $chan

    # automate flushing
    fconfigure $chan -buffering line     

    puts "$addr:$port connected"

    #Test code
	# sockSend "hi there"
              
    # set up to handle incoming data when necessary
    fileevent $chan readable [list handleComm $chan]          
}     

# Utility for pushing data over the socket
proc sockSend {cmd} {
    global sock
    puts $sock $cmd
    flush $sock
}

# Handler for stdin events
#   If we get something over stdin then simply
# 	push it out as is to the client.
global command 
proc StdinRead {} {
	global sock
	global closed
	global command 
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
        #     sockSend $command(line)
        # }
		flush stdout
		set command(line) {}
	}
}

# Link our stdin handler to the event
fileevent stdin readable StdinRead

# Wait for a connection
socket -server accept 54321

#Wait for the client to come back and say they are closing
proc serverVwait {} {
	global closed
	vwait $closed
}

#Clear our handler of stdin
# fileevent $stdin readable {}


# socket -server accept 12345   ;# pick your own port number...
# proc accept {channel host port} {
#     exec [info nameofexecutable] realScript.tcl \
#             <@$channel >@$channel 2>@$channel &
# }
# vwait forever                 ;# run the event loop to serve sockets...