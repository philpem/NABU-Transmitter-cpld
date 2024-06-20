/**********
 * NABU Data Generator
 *
 * Takes parallel data from a host processor.
 * Turns it into 
 */

module top(

	output DIL_1,
	input  DIL_1_GCK,
	output DIL_2,
	input  DIL_2_GCK,
	
	input  DIL_3, DIL_4, DIL_5, DIL_6, DIL_7, DIL_8, DIL_9, DIL_10, DIL_11,
	input  DIL_12,
	output DIL_13,
	
	// DIL_14: GND

/* 
	DIL_15, DIL_16,
	DIL_17,
	input DIL_18,
	input DIL_19,
	input DIL_20,
	input DIL_21,
	input DIL_22,
	input DIL_23,
	input DIL_24,
	input DIL_25,
	input DIL_26,
	input DIL_27,
*/
	output DIL_26,
	output DIL_27,
	
	// DIL_28: +5V
	
	output _PGND1,
	output _PGND2
);

	// PGND need to be pulled low to avoid ground bounce
	assign _PGND1 = 1'b0;
	assign _PGND2 = 1'b0;
	  
	// DIL1 and DIL2 are paired with the GCKs and need to be assigned hi-Z
	assign DIL_1 = 1'bZ;
	assign DIL_2 = 1'bZ;
	
	
	// DIL1/GCK1: bit clock
	wire BIT_CLK = DIL_1_GCK;
	
	// DIL3..DIL11: data input
	wire [8:0] DATA_IN = {DIL_3, DIL_4, DIL_5, DIL_6, DIL_7, DIL_8, DIL_9, DIL_10, DIL_11};
	
	// DIL12: Transmit
	wire DATA_WR = DIL_12;
	
	// DIL13: Transmit holding register empty
	assign DIL_13 = thre;
	
	
	// DIL27: data output
	wire DATA_OUT;
	assign DIL_27 = DATA_OUT;
	
	// DIL26: debug, SDLC null insertion flag
	assign DIL_26 = sdlc_insert_null;

	
	//////
	// Transmit holding register
	//
	reg [8:0] txhold_r;
	always @(posedge DATA_WR) begin
		txhold_r <= DATA_IN;
	end

	
	//////
	// Transmit holding register empty flag
	//
	reg thre = 1'b1;	// Transmit holding register empty
	wire tx_pull;
	always @(posedge DATA_WR or posedge tx_pull) begin
		if (DATA_WR) begin
			// Data write, clear empty flag
			thre <= 1'b0;
		end else begin
			// Data pull, set empty flag
			thre <= 1'b1;
		end
	end

	
	//////
	// Bit counter
	//
	reg [3:0] bit_count;
	always @(posedge BIT_CLK) begin
		if (!sdlc_insert_null) begin
			bit_count <= bit_count + 1;
		end
	end
	assign tx_pull = (bit_count == 0);


	//////
	// Data shift register and "raw mode" (no zero insertion) latch bit
	//
	reg [7:0] sr_r;
	reg rawmode;

	// Raw-mode latch bit
	always @(posedge tx_pull) begin
		rawmode <= txhold_r[8];
	end
	
	// Loadable PISO shift register
	always @(posedge BIT_CLK or posedge tx_pull) begin
		if (tx_pull) begin
			// Pull -> load shift register
			sr_r <= txhold_r[7:0];
		end else begin
			// Bit clock, shift register left one bit
			// But only if we're not inserting a zero
			if (rawmode || !sdlc_insert_null) begin
				sr_r <= {sr_r[6:0], 1'b0};
			end
		end
	end
	
	// Output bit from SR
	// If outputting a null then it's a 0 else it's the MSB of the SR
	wire output_bit = sdlc_insert_null ? 1'b0 : sr_r[7];

	  
	//////
	// SDLC zero insertion
	//		
	// 6-bit shift register to track the output stream - including any zeroes we insert
	reg[5:0] sdlc_nullins_r;
	// Always clock in the actual output
	always @(posedge BIT_CLK) begin
		sdlc_nullins_r <= {sdlc_nullins_r[4:0], output_bit};
	end
	// Insert a null if there were five consecutive 1 bits
	wire sdlc_insert_null = (sdlc_nullins_r == 6'b011111);

	//////
	// Scrambler
	//
	scrambler _scram(BIT_CLK, output_bit, DATA_OUT);

endmodule
