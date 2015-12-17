/*********************************************************************************************************************
* 5 Phase Stepper motor Controller
* December 2015
*********************************************************************************************************************/


//TOP LEVEL MODULE
module epm240(rst, ena,dir, pul, mod, cmps, outs, hfc);   //module stepmot is the top level module.
   		input rst, ena;                        //rst when asserted brings the shaft to reference position.
        input mod;                           //mod specifies step operation or continuous operation.
        input dir;                               //dir is for clockwise or anti clockwise motion.
        input pul;      
		input [4:0] cmps;
		output hfc;
		output [9:0] outs;
		wire w_pwm;

	/* Instantiation  of controller module.*/
	stepper s1(
		.rst (rst),
		.ena (ena),
		.pul (pul),
		.dir (dir),
		.mod (mod),
		.pwm (w_pwm),
		.outs (outs),
		.cmps (cmps));

	/* Instantiation  of clock generate module.      */	
	clk_generate cg1(
		.ena (ena),
		.pul (pul),
		.rst (rst),
		.pwm (w_pwm),
		.hfc (hfc));

endmodule


/* Module stepper is the motor controller module */
module stepper (rst, ena, pul, dir, mod, pwm, outs, cmps);
	parameter A1 = 0, A2 = 10, B1 = 5, B2 = 15, C1 = 7, C2 = 19, D1 = 12, D2 = 2, E1 = 17, E2 = 6;
    input ena, pul, rst, dir, mod, pwm;
	input [4:0] cmps;
    output reg [9:0] outs;
    reg [19:0] position;
	reg fmod;

	always @(posedge pul or negedge rst) begin
		if(rst == 0) begin                                      // array resets to 11111111100000000000 at rst=0
			position = 20'b11111111100000000000;
			fmod = 1'b0;
		end else if(ena == 1) begin
				//mod=0/1 for half/full step
				//dir=0/1 for anticlockwise/clockwise motion
				if(fmod == 1 && mod == 1) begin
					position = {position[18:0], position[19]};
					fmod = 1'b0;
				end
				if(mod == 0) begin
					if (dir == 0)
						position = {position[18:0], position[19]};
					else
						position = {position[0], position[19:1]};
					fmod = fmod + 1'b1;
				end else begin
					if (dir==0)
						position = {position[17:0], position[19:18]};
					else
						position = {position[1:0], position[19:2]};
				end
		end
	end

	always @(posedge pwm or negedge cmps[0] or negedge rst or negedge ena) begin
		if(rst == 0 || cmps[0] == 0 || ena == 0)
			outs[1:0] = 2'b00;
		else
			outs[1:0] = {position[A2], position[A1]};
	end

	always @(posedge pwm or negedge cmps[1] or negedge rst or negedge ena) begin
		if(rst == 0 || cmps[1] == 0 || ena == 0)
			outs[3:2] = 2'b00;
		else
			outs[3:2] = {position[B2], position[B1]};
	end

	always @(posedge pwm or negedge cmps[2] or negedge rst or negedge ena) begin
		if(rst == 0 || cmps[2] == 0 || ena == 0)
			outs[5:4] = 2'b00;
		else
			outs[5:4] = {position[C2], position[C1]};
	end

	always @(posedge pwm or negedge cmps[3] or negedge rst or negedge ena) begin
		if(rst == 0 || cmps[3] == 0 || ena == 0)
			outs[7:6] = 2'b00;
		else
			outs[7:6] = {position[D2], position[D1]};
	end

	always @(posedge pwm or negedge cmps[4] or negedge rst or negedge ena) begin
		if(rst == 0 || cmps[4] == 0 || ena == 0)
			outs[9:8] = 2'b00;
		else
			outs[9:8] = {position[E2], position[E1]};
	end
endmodule

/**************************************************************************************************
* clock generate
* clock = 3.3MHz  pwm = clock / 256 = 13KHz  half_current = pwm / 
**************************************************************************************************/
`timescale 1 ps / 1 ps
module  clk_altufm_osc_1p3( osc) /* synthesis synthesis_clearbox=1 */;
	output   osc;
	wire  wire_maxii_ufm_block1_osc;
	maxii_ufm   maxii_ufm_block1( 
		.arclk(1'b0),
		.ardin(1'b0),
		.arshft(1'b0),
		.bgpbusy(),
		.busy(),
		.drclk(1'b0),
		.drdout(),
		.drshft(1'b0),
		.osc(wire_maxii_ufm_block1_osc),
		.oscena(1'b1)
		`ifdef FORMAL_VERIFICATION
		`else
		
		`endif
		,
		.drdin(1'b0),
		.erase(1'b0),
		.program(1'b0)
		`ifdef FORMAL_VERIFICATION
		`else
		
		`endif
		
		,
		.ctrl_bgpbusy(),
		.devclrn(),
		.devpor(),
		.sbdin(),
		.sbdout()	
	);
	defparam
		maxii_ufm_block1.address_width = 9,
		maxii_ufm_block1.osc_sim_setting = 300000,
		maxii_ufm_block1.lpm_type = "maxii_ufm";
	assign
		osc = wire_maxii_ufm_block1_osc;
endmodule 

module clk_generate(ena, pul, rst, pwm, hfc);
	input ena, pul, rst;
	output reg pwm, hfc;
	wire  osc;
	reg [14:0] count_hfc;
	reg [9:0] count_pwm;
	
	clk_altufm_osc_1p3	clk_altufm_osc_1p3_component (
		.osc (osc));
					
	
	always @(posedge osc or negedge rst or negedge ena) begin
		if (rst == 0 || ena == 0) begin               // counter resets to 0 at rst=0 or pul=1
			count_pwm[9:0] = 10'b0;
			pwm = 1'b0;
		end else begin
			count_pwm = count_pwm + 1'b1;
			pwm = count_pwm[8];
		end
	end
	
	always @(posedge pwm or posedge pul or negedge rst or negedge ena) begin
		if(pul == 1 || rst == 0 || ena == 0) begin                        // counter resets to 0 at rst=0 or pul=1
			count_hfc[14:0] = 15'b0;
			hfc = 1'b1;
		end else begin
			if (count_hfc[14] == 1)
				hfc = 1'b0;
			else
				count_hfc = count_hfc + 1'b1;
		end
	end
endmodule
/***********************************END OF PROGRAM.**********************************************/


