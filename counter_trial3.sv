module counter(input wire clk,
			   input wire reset,
			   input wire mod,
			   output reg [3:0] count
			   );
	
	always@(posedge clk or posedge reset) begin
		if(reset) count = 4'b0000;
			else begin
				if(mod)
					count <= count + 1'd1;
				else
					count <= count - 1'd1;
			end
		end
endmodule

class counter_item;
	
	rand bit reset;
	rand bit mod;
	logic [3:0] count;
	int scenario_id;
	//add constraint if it is requured
	constraint reset_freq {reset dist {1 := 0 , 0 := 100 };}
	constraint mod_freq {mod dist {1 := 70 , 0:= 30};}
	
	function void print(string tag = "");
		$display("Time : %0t | %0s | scenario_id = %0d | reset = %0b | mod = %0d | count = %0d",$time,tag,scenario_id,reset,mod,count);
	endfunction
endclass

interface counter_if (input bit clk);
	logic reset;
	logic mod;
	logic [3:0] count;

	//modport DUT (input clk, input reset, input mod , output count);
	modport driver (input clk, output reset, output mod );
	modport monitor (input clk, input reset, input mod, input count);

endinterface

//generator class with scenario
class generator;
	mailbox drv_mbx;
	counter_item item;
	event drv_done;
	
	task run();
	//scenario 1 - check reset
		begin
			item = new();
			item.reset = 1'b1;
			item.mod = 1'b0;
			item.scenario_id = 32'd1;
			drv_mbx.put(item);
			item.print("GEN");
			@(drv_done);
		end 
	
	//scenario 2 - increment check
			for (int i = 0; i < 20; i++) begin
				item = new();
				item.reset = 1'b0;
				item.mod = 1'b1;
				item.scenario_id = 32'd2;
				drv_mbx.put(item);
				item.print("GEN");
				@(drv_done);
			end
	
	//senario 3 - decrement check
			for (int i = 0; i < 20; i++) begin
				item = new();
				item.reset = 1'b0;
				item.mod = 1'b0;
				item.scenario_id = 32'd3;
				drv_mbx.put(item);
				item.print("GEN");
				@(drv_done);
			end
	
	//senario 4 - toggle check
			for(int i = 0; i < 20; i++) begin
				item = new();
				item.scenario_id = 32'd4;
				item.randomize;
				drv_mbx.put(item);
				item.print("GEN");
				@(drv_done);
		end
		$display("Time : %0t | [GEN] done generating all scenarios ",$time); 
	endtask
endclass

//driver
class driver;
	virtual counter_if.driver vif;
	counter_item item;
	event drv_done;
	mailbox drv_mbx;
	mailbox mon_mbx;

	task run();
                repeat (61) begin
			//@(posedge vif.clk);
			drv_mbx.get(item);
			vif.reset = item.reset;
			vif.mod = item.mod;
			item.print("DRV");
			mon_mbx.put(item);
			@(posedge vif.clk);
			->drv_done;
			//@(posedge vif.clk);	
		end
	endtask
endclass 

//monitor 
class monitor;
	virtual counter_if.monitor vif;
	mailbox scb_mbx;
	mailbox mon_mbx;
	counter_item item;
	
	task run();

		repeat(61) begin
			item = new();
			@(posedge vif.clk);
			//@(posedge vif.clk);
			#1;
			mon_mbx.get(item);
			item.reset = vif.reset;
			//item.mod = vif.mod;			// causing errors by updating new mod from driver 
			item.count = vif.count;
			scb_mbx.put(item);
			item.print("MON");
			
		end
	endtask
endclass

//scoreboard
class scoreboard;
	mailbox scb_mbx;
	counter_item item;
	parameter MAX_VALUE = 4'b1111;
	parameter MIN_VALUE = 4'b0000;
	int total_checks;
	int total_errors;
	int prev_count = 0;
		function void scoreboard_report();
				$display("============================================================");
				$display("Time = %0t",$time);
				$display("scoreboard report");
				$display("total checks = %0d",total_checks);
				$display("total errors = %0d",total_errors);
				$display("============================================================");
				
			endfunction
			
	task run();
    forever begin
        scb_mbx.get(item);
        item.print("SCB");
        total_checks++;
        case (item.scenario_id)
            1: begin
                if (item.reset && item.count != 4'b0000) begin
                    $display("ERROR: Time = %0t | reset scenario failed ", $time);
                    $display("============================================================");
                    total_errors++;
                end else begin
                    $display("Time : %0t | reset scenario passed", $time);
                    $display("============================================================");
                end
            end
            2: begin
                if (!item.reset && item.mod) begin
                    if (prev_count == MAX_VALUE && item.count == 4'b0000) begin
                        $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                    end else if (prev_count != MAX_VALUE && item.count == prev_count + 1) begin
                        $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                    end else begin
                        $display("ERROR: Time : %0t | invalid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                        total_errors++;
                    end
                end 
            end
            3: begin
                if (!item.reset && !item.mod) begin 
                    if (prev_count == MIN_VALUE && item.count == 4'b1111) begin
                        $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                    end else if (prev_count != MIN_VALUE && item.count == prev_count - 1) begin
                        $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                    end else begin
                        $display("ERROR: Time : %0t | invalid transition from %0d to %0d", $time, prev_count, item.count);
                        $display("============================================================");
                        total_errors++;
                    end
                end 
            end
            4: begin 
                if (!item.reset) begin 
                    if (item.mod) begin
                        if (prev_count == MAX_VALUE && item.count == 4'b0000) begin
                            $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                        end else if (prev_count != MAX_VALUE && item.count == prev_count + 1) begin
                            $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                        end else begin
                            $display("ERROR: Time : %0t | invalid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                            total_errors++;
                        end
                    end else begin // !item.mod
                        if (prev_count == MIN_VALUE && item.count == 4'b1111) begin
                            $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                        end else if (prev_count != MIN_VALUE && item.count == prev_count - 1) begin
                            $display("Time : %0t | valid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                        end else begin
                            $display("ERROR: Time : %0t | invalid transition from %0d to %0d", $time, prev_count, item.count);
                            $display("============================================================");
                            total_errors++;
                        end
                    end
                end
            end
        endcase
        prev_count = item.count;
    end
endtask
endclass

//environment
class environment;
	
	generator g0;
	driver d0;
	monitor m0;
	scoreboard s0;
	mailbox mon_mbx, drv_mbx, scb_mbx;
	
	event drv_done;
	virtual counter_if vif;
	
	function new();
		g0 = new();
		d0 = new();
		m0 = new();
		s0 = new();
		drv_mbx = new();
		scb_mbx = new();
		mon_mbx = new();
	
		g0.drv_mbx = drv_mbx;
		d0.drv_mbx = drv_mbx;
	
		m0.scb_mbx = scb_mbx;
		s0.scb_mbx = scb_mbx;
	
		d0.mon_mbx = mon_mbx;
		m0.mon_mbx = mon_mbx;
		
		g0.drv_done=drv_done;
		d0.drv_done=drv_done;	
	endfunction
	
	virtual task run();
		d0.vif = vif.driver;
		m0.vif = vif.monitor;

		fork
			g0.run();
			d0.run();
			m0.run();
			s0.run();
		join_any
	endtask
	
endclass

//test
class test;
environment e0;

function new();
	e0 = new();
endfunction

task run();
	e0.run();
endtask

endclass 
 

//testbench module 
module tb;
reg clk;

counter_if if1(clk);
counter dut(.clk(if1.clk),
			.reset(if1.reset),
			.mod(if1.mod),
			.count(if1.count)
			);

test t0;
always #5 clk = ~clk;

initial begin
	clk = 0;
	#20;
	if1.reset = 1'b0;
	t0 = new();
	t0.e0.vif = if1;	
	t0.run();
	#20;
	#300;
	t0.e0.s0.scoreboard_report();

	$finish;
	end

initial begin 
	$shm_open("wave.shm");
	$shm_probe("ACTMF");
end
	
endmodule
 
