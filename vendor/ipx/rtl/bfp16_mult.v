`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// BFP16 Multiplier 

// https://github.com/danshanley/FPU/blob/master/fpu.v
// with slight modifications to turn FP32 to BFP16
// for area approximation

// Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// NOTE: MORE VERIFICATION NEEDED
/////////////////////////////////////////////////////////////

module multiplier(clk, A, B, O);

  input [15:0] A, B;
  input clk;
  output [15:0] O;

  wire a_sign;
  wire b_sign;
  wire [7:0] a_exponent;
  wire [7:0] b_exponent;
  wire [7:0] a_mantissa;
  wire [7:0] b_mantissa;
  wire [15:0] O;
             
  reg o_sign;
  reg [7:0]  o_exponent;
  reg [8:0] o_mantissa;  
	
  reg [15:0] multiplier_a_in;
  reg [15:0] multiplier_b_in;
  wire [15:0] multiplier_out;

  assign O[15] = o_sign;
  assign O[14:7] = o_exponent;
  assign O[6:0] = o_mantissa[6:0];

  assign a_sign = A[15];
  assign a_exponent[7:0] = A[14:7];
  assign a_mantissa[7:0] = {1'b1, A[6:0]};

  assign b_sign = B[15];
  assign b_exponent[7:0] = B[14:7];
  assign b_mantissa[7:0] = {1'b1, B[6:0]};

	gMultiplier M1 (
		.a(multiplier_a_in),
		.b(multiplier_b_in),
		.out(multiplier_out)
	);
	
  assign multiplier_a_in = A; // timing fix - singly cycle
  assign multiplier_b_in = B; // timing fix - single cycle

  always @ (posedge clk) begin //Multiplication
    //If a is NaN return NaN
    if (a_exponent == 255 && a_mantissa != 0) begin
      o_sign = a_sign;
      o_exponent = 255;
      o_mantissa = a_mantissa;
		//If b is NaN return NaN
	end else if (b_exponent == 255 && b_mantissa != 0) begin
	  o_sign = b_sign;
	  o_exponent = 255;
	  o_mantissa = b_mantissa;
	//If a or b is 0 return 0
	end else if ((a_exponent == 0) && (a_mantissa == 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
	  o_sign = a_sign ^ b_sign;
	  o_exponent = 0;
	  o_mantissa = 0;
	//if a or b is inf return inf
	end else if ((a_exponent == 255) || (b_exponent == 255)) begin
	  o_sign = a_sign;
	  o_exponent = 255;
	  o_mantissa = 0;
	end else if (A == 'd0 && B == 'd0) begin
	  o_sign = 0;
	  o_exponent = 0;
	  o_mantissa = 0;
	end else begin // Passed all corner cases
	  //multiplier_a_in = A;
	  //multiplier_b_in = B;
	  o_sign = multiplier_out[15];
	  o_exponent = multiplier_out[14:7];
	  o_mantissa = multiplier_out[6:0]; 
    end
  end

endmodule


module gMultiplier(a, b, out);
  input  [15:0] a, b;
  output [15:0] out;
  wire [15:0] out;
    reg a_sign;
  reg [7:0] a_exponent;
  reg [7:0] a_mantissa;
	reg b_sign;
  reg [7:0] b_exponent;
  reg [7:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [8:0] o_mantissa;

	reg [15:0] product;

  assign out[15] = o_sign;
  assign out[14:7] = o_exponent;
  assign out[6:0] = o_mantissa[6:0];

	reg  [7:0] i_e;
	reg  [15:0] i_m;
	wire [7:0] o_e;
	wire [15:0] o_m;

	multiplication_normaliser norm1
	(
		.in_e(i_e),
		.in_m(i_m),
		.out_e(o_e),
		.out_m(o_m)
	);


  always @ ( * ) begin
		a_sign = a[15];
   
		if(a[14:7] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[6:0]};
		end else begin
			a_exponent = a[14:7];
			a_mantissa = {1'b1, a[6:0]};
		end
   
		b_sign = b[15];
   
		if(b[14:7] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[6:0]};
		end else begin
			b_exponent = b[14:7];
			b_mantissa = {1'b1, b[6:0]};
		end
   
    o_sign = a_sign ^ b_sign;
    o_exponent = a_exponent + b_exponent - 127;
    product = a_mantissa * b_mantissa;
    
		// Normalization
    //if(product[13] == 1) begin
    if(product[15] == 1 ) begin // fix
      o_exponent = o_exponent + 1;
      product = product >> 1;
    end else if((product[14] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = product;
      o_exponent = o_e;
      product = o_m;
    end
    
		o_mantissa = product[14:7];
	end
endmodule
