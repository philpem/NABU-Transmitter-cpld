/******
 * NABU Adaptor - bitstream scrambler/randomiser
 *
 * XORs incoming data bits with the output of a 20-bit maximal-length
 * linear-feedback shift register. This makes sure there are regular
 * bit transitions in the data stream, which the D-OQPSK demodulator
 * requires to recover the bit clock.
 */

module scrambler(
	input CLK,
	input DATA_IN,
	output DATA_OUT
);

	reg [19:0] scrambler_r;		// Scrambler shift register
	
	// Taps are x^2, x^19, and inverse of input bit.
	wire d_new = !DATA_IN ^ scrambler_r[2] ^ scrambler_r[19];
	always @(posedge CLK) begin
		scrambler_r <= {scrambler_r[18:0], d_new};
	end
	// Take data output from SR lowest bit so it's stable
	assign DATA_OUT = scrambler_r[0];
	
endmodule