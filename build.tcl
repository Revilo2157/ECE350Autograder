if {$argc != 3} {
        puts "Not enough arguments - 0: Assignment, 1: sourceDir, 2: Timing"
        return 0
}


set topLevel [lindex $argv 0] 
set sourceDir [lindex $argv 1]
set outputDir $sourceDir/out
set partNum xc7a100tcsg324-1

set files [glob -nocomplain "$outputDir/*"]
if {[llength $files] != 0} {
    # clear folder contents
    puts "deleting contents of $outputDir"
    file delete -force {*}[glob -directory $outputDir *]; 
} else {
    puts "$outputDir is empty"
}

create_project $topLevel $sourceDir/out
add_files [glob tests/$topLevel/main_tb.v]
add_files [glob $sourceDir/*.v]

if {[lindex $argv 2]} {
	

# Synthesis
synth_design -top $topLevel -part $partNum
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt

#run optimization
opt_design
place_design
report_clock_utilization -file $outputDir/clock_util.rpt

#get timing violations and run optimizations if needed
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
 puts "Found setup timing violations => running physical optimization"
 phys_opt_design
}
write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
}



#  Simulation
set tests [glob tests/$topLevel/*_exp.csv]
for {set a 0} {$a < [llength $tests]} {incr a} {
	set testFile [lindex $tests $a]
	set test [string range $testFile 7+[string length $topLevel] end-8]
	puts \n-------------------------------------------
	puts "Running $test"
	puts -------------------------------------------
	set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg test=/home/rapiduser/tests/$topLevel/$test" -objects [get_filesets sim_1]
	set_property top main_tb [get_filesets sim_1]
	set_property -name {xsim.simulate.runtime} -value {0} -objects [get_filesets sim_1]

	if {[lindex $argv 2]} {
		launch_simulation -mode post-implementation -type timing
		set mode timing 
	} else {
		launch_simulation -mode behavioral
		set mode behavioral
	}

	restart
	open_vcd /home/rapiduser/$sourceDir/results/${test}_${mode}.vcd
	log_vcd [get_object /main_tb/*]
	run -all
	close_vcd
	close_sim
}
