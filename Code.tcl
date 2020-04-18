set ns [new Simulator]
set namfile [ open out.nam w ]
$ns namtrace-all $namfile

#Enable dynamic routing
$ns rtproto DV

for {set i 0} {$i < 14} {incr i} {
	set n($i) [$ns node]
}

$ns duplex-link $n(0) $n(2) 4Mb 10ms SFQ #stochastic fair queueing
$ns duplex-link $n(1) $n(2) 4Mb 10ms SFQ
$ns duplex-link $n(2) $n(3) 3Mb 10ms SFQ
$ns duplex-link $n(3) $n(4) 3Mb 10ms SFQ 
$ns duplex-link $n(2) $n(5) 2Mb 5ms SFQ
$ns duplex-link $n(5) $n(6) 2Mb 5ms SFQ
$ns duplex-link $n(2) $n(7) 4Mb 10ms SFQ
$ns duplex-link $n(7) $n(8) 4Mb 10ms SFQ
$ns duplex-link $n(4) $n(9) 4Mb 10ms SFQ
$ns duplex-link $n(6) $n(9) 4Mb 10ms SFQ
$ns duplex-link $n(8) $n(9) 4Mb 10ms SFQ
$ns duplex-link $n(9) $n(10) 4Mb 10ms SFQ
$ns duplex-link $n(9) $n(11) 4Mb 10ms SFQ
$ns duplex-link $n(12) $n(3) 4Mb 5ms SFQ
$ns duplex-link $n(13) $n(7) 4Mb 5ms SFQ

$ns duplex-link-op $n(0) $n(2) orient right-down
$ns duplex-link-op $n(1) $n(2) orient right-up
$ns duplex-link-op $n(2) $n(3) orient right-up
$ns duplex-link-op $n(3) $n(4) orient right
$ns duplex-link-op $n(2) $n(5) orient right
$ns duplex-link-op $n(5) $n(6) orient right
$ns duplex-link-op $n(2) $n(7) orient right-down
$ns duplex-link-op $n(7) $n(8) orient right
$ns duplex-link-op $n(4) $n(9) orient right-down
$ns duplex-link-op $n(6) $n(9) orient right
$ns duplex-link-op $n(8) $n(9) orient right-up
$ns duplex-link-op $n(9) $n(10) orient right-up
$ns duplex-link-op $n(9) $n(11) orient right-down
$ns duplex-link-op $n(12) $n(3) orient right-down
$ns duplex-link-op $n(13) $n(7) orient right-up

$ns duplex-link-op $n(3) $n(4) queuePos 0.5
$ns duplex-link-op $n(2) $n(5) queuePos 0.5
$ns duplex-link-op $n(7) $n(8) queuePos 0.5
$ns duplex-link-op $n(9) $n(10) queuePos 0.5
$ns duplex-link-op $n(9) $n(11) queuePos 0.5

#Create UDP Agent
set udp0 [new Agent/UDP]
$ns attach-agent $n(0) $udp0

set udp1 [new Agent/UDP]
$ns attach-agent $n(13) $udp1

#Create TCP Agent
set tcp0 [new Agent/TCP/Newreno]
$ns attach-agent $n(1) $tcp0

set tcp1 [new Agent/TCP/Vegas]
$ns attach-agent $n(12) $tcp1

set tcp2 [new Agent/TCP/Reno]
$ns attach-agent $n(1) $tcp2

#Setup FTP over TCP
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

#Attach CBR to UDP
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 10000
$cbr0 set rate_ 1mb
$cbr0 attach-agent $udp0

set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 10000
$cbr1 set rate_ 2mb
$cbr1 attach-agent $udp1

#Attach sink
set udpsink0 [new Agent/LossMonitor]
$ns attach-agent $n(10) $udpsink0
$ns connect $udp0 $udpsink0

set udpsink1 [new Agent/LossMonitor]
$ns attach-agent $n(10) $udpsink1
$ns connect $udp1 $udpsink1

set tcpsink0 [new Agent/TCPSink]
$ns attach-agent $n(11) $tcpsink0
$ns connect $tcp0 $tcpsink0

set tcpsink1 [new Agent/TCPSink]
$ns attach-agent $n(11) $tcpsink1
$ns connect $tcp1 $tcpsink1

set tcpsink2 [new Agent/TCPSink]
$ns attach-agent $n(11) $tcpsink2
$ns connect $tcp2 $tcpsink2

#Set color
$udp0 set class_ 1
$ns color 1 Blue
$tcp0 set class_ 2
$ns color 2 Yellow
$udp1 set class_ 3
$ns color 3 Green
$tcp1 set class_ 4
$ns color 4 Magenta

set time 0
for {set i 0} {$i<12} {incr i} {
	for {set j [expr $i + 1]} {$j<12} {incr j} {
		if { [catch {$ns rtmodel-at $time down $n($i) $n($j)}]} {
			puts "Nodes $i and $j are not adjacent."
		} else {
			puts "Adjacent"
			set time [expr $time + 0.5]
			$ns rtmodel-at $time up $n($i) $n($j)
			set time [expr $time + 0.5]
		}
	}
}

set udpSinkFile0 [open udpout0.tr w]
set udpSinkFile1 [open udpout1.tr w]
set tcpCwndFile0 [open tcpout0.tr w]
set tcpCwndFile1 [open tcpout1.tr w]
set tcpCwndFile2 [open tcpout2.tr w]

puts "Saving out.nam"
proc finish {} {
	global ns namfile udpSinkFile0 udpSinkFile1 tcpCwndFile0 tcpCwndFile1 tcpout2 tcpCwndFile2
	close $udpSinkFile0
	close $udpSinkFile1
	close $tcpCwndFile0
	close $tcpCwndFile1
	close $tcpCwndFile2
	close $namfile
	
	exec nam out.nam &
	exec /home/vaibhav/XGraph/bin/xgraph udpout0.tr udpout1.tr &
	exec /home/vaibhav/XGraph/bin/xgraph tcpout0.tr tcpout1.tr &
	exec /home/vaibhav/XGraph/bin/xgraph tcpout0.tr tcpout2.tr &
	exit 0
}

proc record {} {
	global udpsink0 udpSinkFile0 udpsink1 udpSinkFile1 tcp0 tcpCwndFile0 tcp1 tcpCwndFile1 tcp2 tcpCwndFile2
	set ns [Simulator instance]
	
	#Procedure is called again after 0.7 sec
	set time 0.3
	
	#Get bytes received
	set bytes_received0 [$udpsink0 set bytes_]
	set bytes_received1 [$udpsink1 set bytes_]
	
	#Current time
	set now [$ns now]
	
	#Save
	puts $udpSinkFile0 "$now [expr $bytes_received0/$time*8/1000000]"
	puts $udpSinkFile1 "$now [expr $bytes_received1/$time*8/1000000]"
	
	#Reset udpSink
	$udpsink0 set bytes_ 0
	$udpsink1 set bytes_ 0
	
	#Get congestion window size
	set congestion_win0 [$tcp0 set cwnd_]
	set congestion_win1 [$tcp1 set cwnd_]
	set congestion_win2 [$tcp2 set cwnd_]
	
	#Save
	puts $tcpCwndFile0 "$now $congestion_win0"
	puts $tcpCwndFile1 "$now $congestion_win1"
	puts $tcpCwndFile2 "$now $congestion_win2"
	
	#Reschedule procedure
	$ns at [expr $now + $time] "record"
}

$ns at 0.3 "record"
$ns at 0.2 "$cbr0 start"
$ns at 0.4 "$cbr1 start"
$ns at 0.4 "$ftp0 start"
$ns at 0.2 "$ftp1 start"
$ns at 0.2 "$ftp2 start"
$ns at 37.0 "$ftp0 stop"
$ns at 38.0 "$ftp1 stop"
$ns at 37.0 "$ftp2 start"
$ns at 38.0 "$cbr0 stop"
$ns at 37.0 "$cbr1 stop"

#run finish procedure after 15 sec of exec time.
$ns at 15.0 "finish"

$ns run

