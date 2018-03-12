

/////////////top_module///////////////////////////////////////
module mvm4_part3(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready,data_out,overflow); //in the netlist, Statecounter and enable_f are extra, we can just remove them as they are not needed, they are only there for verification


 //yet to define the inputs and outputs


parameter WIDTH=8, SIZE=64, LOGSIZE=6;
input [WIDTH-1:0] data_in; //1
input clk,reset,s_valid,m_ready;// 2,3,4,5


output logic m_valid, s_ready; //1,2
//output logic unsigned [4:0] StateCounter ;//
//output logic enable_f; //i dont even know what it is doing gere //
output logic signed [15:0] data_out; //data_out is actually the f//3
//output logic valid_out;
output logic overflow;//4
//output logic valid_out; //5

logic wr_en_x, wr_en_m,wr_en_y; //1,2
logic [LOGSIZE-1:0] addr_x, addr_m,addr_y; //3,4
logic clear_acc;//yeah this one too // 5
logic [WIDTH-1:0] data_out_x,data_out_m,data_out_y; //6,7
logic enable;//8
logic acc_source;

ControlModule c0(clk, reset, s_valid, m_ready, addr_x, wr_en_x, addr_m, wr_en_m, addr_y,wr_en_y, clear_acc, s_ready, enable, m_valid,acc_source);
datapath d0(clk,data_in,addr_x,addr_m, addr_y,wr_en_x,wr_en_m, wr_en_y,clear_acc, enable, overflow, data_out,acc_source);

endmodule





///////////////////////DATAPATH//////////////////
module datapath(clk,data_in,addr_x,addr_m, addr_y,wr_en_x,wr_en_m, wr_en_y,clear_acc, valid_in, overflow, data_out,acc_source);

parameter WIDTH=8, SIZE=64, LOGSIZE=6;
input [WIDTH-1:0] data_in; //1 
input clk;
//input reset;//2,3
input clear_acc;//4
input [LOGSIZE-1:0] addr_x, addr_m,addr_y;//5
input wr_en_x, wr_en_m,wr_en_y;//6
input valid_in;
input acc_source;
 
output logic signed [15:0] data_out; //data_out is actually the f//1
output logic overflow;//2

//logic valid_out;
logic [WIDTH-1:0] data_out_x,data_out_m,data_out_y; //6,7


memory_call m0(clk, data_in, data_out_x,data_out_m, data_out_y, addr_x,addr_m, addr_y, wr_en_x,wr_en_m,wr_en_y); 
part2_mac mac0(clk, clear_acc, data_out_x, data_out_m, data_out_y, valid_in, data_out, overflow,acc_source);


endmodule


///////////////////////////////////MEMORY CALL/////////////////////////
//memory call calls 2 memories at once
module memory_call(clk, data_in, data_out_a,data_out_b, data_out_c, addr_a,addr_b, addr_c, wr_en_a,wr_en_b,wr_en_c);  //now changing this for 2 memories and a control unit for testing
parameter WIDTH=8, SIZE=64, LOGSIZE=6;
input [WIDTH-1:0] data_in;
output logic [WIDTH-1:0] data_out_a,data_out_b,data_out_c;
input [LOGSIZE-1:0] addr_a, addr_b,addr_c;
input clk, wr_en_a,wr_en_b,wr_en_c;
//logic [SIZE-1:0][WIDTH-1:0] mem;
memory m1(clk, data_in, data_out_a, addr_a, wr_en_a);
memory m2(clk, data_in, data_out_b, addr_b, wr_en_b);
memory m3(clk, data_in, data_out_c, addr_c, wr_en_c);
endmodule

/////////////////////////MEMORY//////////////////////////////////////
//memory module provided in the PDF
module memory(clk, data_in, data_out, addr, wr_en);
parameter WIDTH=8, SIZE=64, LOGSIZE=6;
input [WIDTH-1:0] data_in;
output logic [WIDTH-1:0] data_out;
input [LOGSIZE-1:0] addr;
input clk, wr_en;
logic [SIZE-1:0][WIDTH-1:0] mem;
always_ff @(posedge clk) begin
data_out <= mem[addr];
if (wr_en)
mem[addr] <= data_in;
end
endmodule

////////////////////////MAC///////////////////////////////


// ESE 507 Project 1 Reference Design
// Part 2
// add the clear_acc state to this one

module part2_mac(clk, reset, a, b,c, valid_in, f, overflow,acc_source);
   input                      clk, reset, valid_in;
   input signed [7:0]         a, b;
	input [7:0] c;
	input acc_source;
	
   output logic signed [15:0] f;
   output logic               overflow;

   // Internal connections
   logic                      en_ab, en_f,en_f0;
   logic signed [7:0]         ffAOut, ffBOut;
   logic signed [15:0]        multOut, adderOut,adderOut0;
   logic                      overflow_internal;		      
 //  logic valid_out;

   // Registers
always_ff@ (posedge clk) begin
if(acc_source == 0)
	begin
	adderOut0<=adderOut;
	end
else if (acc_source == 1)
	begin
	adderOut0<=c;
	end
end	


   always_ff @(posedge clk) begin
      if (reset == 1) begin
         ffAOut <= 0;
         ffBOut <= 0;
         f 	<= 0;
	 overflow <= 0;
	adderOut0<=0;
      end
      else begin
         if (en_ab) begin
            ffAOut <= a;
            ffBOut <= b;
         end
         if (en_f) begin
            f <= adderOut0;

	    // Important: we only update overflow when valid_inputs allow us
	    // to update f.
	    overflow <= overflow_internal;
         end
      end
   end

//the part that includes the clear_acc is a little doubtful, but should atleast give some output even if the output is wrong






   // Combinational overflow detection
   always_comb begin
      // If we have already overflowed, we keep overflow = 1 until we reset.
      if (overflow)
	overflow_internal  = 1;

      // Here I am adding multOut + f; if they both have the same sign bit
      // and the sign bit of their sum (adderOut) doesn't match, then we
      // have overflowed.
      // (If multOut and f have *different* signs, then we know we are not
      // overflowing.
      else if ((multOut[15] == f[15]) && (adderOut[15] != f[15]))
	overflow_internal  = 1;
      else
	overflow_internal  = 0;      
   end
   
   
   // Combinational multiplication and addition
   always_comb begin
      multOut = ffAOut * ffBOut;
      adderOut = adderOut0 + multOut;
   end

   // Combinational control logic: en_ab
   assign en_ab = valid_in;

   // Sequential control
   // - en_f is en_ab delayed one cycle
   // - valid_out is en_f delayed one cycle
   always_ff @(posedge clk) begin
      if (reset == 1) begin
         //en_f        <= 0;
	en_f0 <=0;
	en_f<=0;
     //   valid_out   <= 0;
      end
      else begin
         en_f0 <= en_ab;
	en_f <=en_f0;
       //  valid_out   <= en_f;
      end
   end
   
endmodule 






////////////////////CONTROL MODULE 4///////////////////////
module ControlModule(clk, reset, s_valid, m_ready, addr_x, wr_en_x, addr_m, wr_en_m, addr_y,wr_en_y, clear_acc, s_ready, enable, m_valid,acc_source);


input clk, reset, s_valid, m_ready;//1234

output logic s_ready, wr_en_x, wr_en_m, wr_en_y, clear_acc, enable,m_valid,acc_source; //

//INTERNAL SIGNALS
logic unsigned [5:0] StateCounter ;
logic m_valid0,m_valid1,m_valid2, m_valid3,enable0,clear_acc0;
//logic m_ready0,m_ready1;
output logic unsigned [5:0] addr_m;
output logic unsigned [5:0] addr_x;
output logic unsigned [5:0] addr_y;

//assign acc_source=0;

always_comb
	begin 
		if(StateCounter == 31 || StateCounter == 37 || StateCounter == 43 || StateCounter == 49)
		begin
		m_valid=m_valid3;
		end
		
		else
		begin
		m_valid=0;
		end
	end


always_ff @(posedge clk) begin
//m_ready0<=m_ready1;
//m_ready1<=m_ready;
m_valid3<=m_valid2;
m_valid2<=m_valid1;
m_valid1<=m_valid0;
enable<=enable0;
clear_acc<=clear_acc0;
end 
//assign m_valid=m_valid0;


always_ff @(posedge clk) begin // STATE REGULATOR


if (reset==1) begin
	StateCounter <=0;	
end

else begin
	if (StateCounter < 16) begin 
		if (s_valid == 1) begin
			StateCounter <= StateCounter +1;
		end
		else begin
			StateCounter <= StateCounter;
		end
	end

	else if (StateCounter == 16)
			StateCounter <= StateCounter +1;

	else if (StateCounter < 21 && StateCounter >16) begin 
		if (s_valid == 1) begin
			StateCounter <= StateCounter +1;
		end
		else begin
			StateCounter <= StateCounter;
		end
	end

	else if (StateCounter == 21)
			StateCounter <= StateCounter +1;

	else if (StateCounter < 26 && StateCounter >21) begin 
		if (s_valid == 1) begin
			StateCounter <= StateCounter +1;
		end
		else begin
			StateCounter <= StateCounter;
		end
	end


	else if (StateCounter > 25 && StateCounter < 31 ) begin	
		StateCounter <= StateCounter +1;
	end
	else if (StateCounter == 31 ) begin 
		if (m_ready == 1 && m_valid3==1) begin
			StateCounter <= StateCounter +1;
		end
		else begin
			StateCounter <= StateCounter;
		end
	end
	else if (StateCounter > 31 && StateCounter < 37) begin
		StateCounter <= StateCounter +1;
	end
	else if (StateCounter == 37 ) begin
		if (m_ready == 1 && m_valid3==1) begin
			StateCounter <= StateCounter +1;
		end	
		else begin
			StateCounter <= StateCounter;
		end
	end	
	else if (StateCounter > 37 && StateCounter < 43) begin
		StateCounter <= StateCounter +1;
	end
	else if (StateCounter == 43) begin
		if (m_ready == 1 && m_valid3==1) begin
			StateCounter <= StateCounter +1;
		end	
		else begin
			StateCounter <= StateCounter;
		end		
	end

	else if (StateCounter > 43 && StateCounter < 49) begin
		StateCounter <= StateCounter +1;
	end

	else if (StateCounter == 49) begin
		if (m_ready == 1 && m_valid3==1) begin
			StateCounter <= StateCounter +1;
		end	
		else begin
			StateCounter <= StateCounter;
		end		
	end


	else if (StateCounter == 50) begin
		StateCounter <= 0;		
	end


end
end



always_comb begin
if (reset==1) begin
	wr_en_m = 0;
	wr_en_x = 0;
	wr_en_y =0;
	s_ready =0;
	clear_acc0 =0;
	addr_m = 0;
	addr_x = 0;
	addr_y=0;
	enable0 =0;
end
else begin
	if (StateCounter < 26) begin // READ AND STORE MODE
		//s_ready = 1;
		enable0= 0;
		m_valid0=0;
	
		if (s_valid == 1) begin //THE SYSTEM IS GETTING INPUT AND STORING IT IN ITS MEMORY
	
		
			if (StateCounter <16) begin
				addr_x = 0;
				wr_en_x = 0;
				addr_m = StateCounter;
				wr_en_m = 1;
				addr_y = 0;
				wr_en_y = 0;
				clear_acc0 =1;
				s_ready = 1;
			end
			else if (StateCounter ==16) begin 
				addr_x = 0;
				wr_en_x = 0;
				addr_m = 0;
				wr_en_m = 0;
				addr_y = 0;
				wr_en_y = 0;	
				clear_acc0 = 1;
				s_ready = 0;			
			end
				
			else if (StateCounter >16 && StateCounter < 21) begin
				addr_x = StateCounter - 17;
				wr_en_x = 1;
				addr_m = 0;
				wr_en_m = 0;
				addr_y = 0;
				wr_en_y = 0;
				clear_acc0 = 1;
				s_ready = 1;
			end
			
			else if (StateCounter == 21) begin 
				addr_x = 0;
				wr_en_x = 0;
				addr_m = 0;
				wr_en_m = 0;
				addr_y = 0;
				wr_en_y = 0;	
				clear_acc0 = 1;
				s_ready = 0;			
			end
			
			else if (StateCounter >21 && StateCounter < 26) begin
				addr_x = 0;
				wr_en_x = 0;
				addr_m = 0;
				wr_en_m = 0;
				wr_en_y = 1;
				addr_y=StateCounter-22;
				clear_acc0 = 1;
				s_ready = 1;
			end


		end
		else begin //NO INPUT IS GIVEN TO THE SYSTEM AND/OR THE SYSTEM IS NOT READY FOR NEW INPUT
			wr_en_m = 0;
			wr_en_x = 0;
			wr_en_y = 0;
			addr_m = addr_m;
			addr_x = addr_x;
			addr_y = addr_y;							
			clear_acc0 = 1;
		end
	end
	else if (StateCounter == 26) begin // WAITING STATE
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		wr_en_y=0;
		addr_m = 0;
		addr_x = 0;
		addr_y=0;
		enable0=0;
		m_valid0=0;
		clear_acc0 = 0;
	end
	else if (StateCounter > 26 && StateCounter < 31 ) begin // CALCULATION STATES
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_x = StateCounter -27;
		addr_m = StateCounter -27;		
		clear_acc0 =0;
		enable0 =1;
		m_valid0=0;
			if (StateCounter==28)
				begin	
				acc_source=1;
				end
			else 
				acc_source=0;
	end	
	else if ( StateCounter == 31 ) begin //WAITING STATE
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_m = 4;
		addr_x = 0;
		addr_y=1;
		enable0 =0;
		m_valid0=1;
		clear_acc0 = 0;
	end
	else if (StateCounter == 32 ) begin //CLEARING STATE
	s_ready = 0;
	wr_en_m = 0;
	wr_en_x = 0;
	addr_m = 4;
	addr_x = 0;
	enable0 =0;
	m_valid0=0;
	clear_acc0 = 1;
	end
	else if (StateCounter > 32 && StateCounter < 37) begin //CALCULATION STATES
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_x = StateCounter -33;
		addr_m = StateCounter -29;
		clear_acc0 = 0;
		enable0 =1;
		m_valid0=0;
		if (StateCounter==34)
			begin	
			acc_source=1;
			end
		else
			acc_source=0;
	end
	else if (StateCounter == 37 ) begin // WAITING STATE
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_m = 8;
		addr_x = 0;
		addr_y=2;
		enable0 =0;
		m_valid0=1;
		clear_acc0 = 0;
	end
	else if (StateCounter == 38 ) begin //CLEARING STATE
	s_ready = 0;
	wr_en_m = 0;
	wr_en_x = 0;
	addr_m = 8;
	addr_x = 0;
	enable0 =0;
	m_valid0=0;
	clear_acc0 = 1;
	end	
	else if (StateCounter > 38 && StateCounter < 43) begin //CALCULATION STATES
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_x = StateCounter -39;
		addr_m = StateCounter -31;
		clear_acc0 =0;
		enable0 =1;
		m_valid0=0;
		if (StateCounter==40)
			begin	
			acc_source=1;
			end
		else
			acc_source=0;

	end
	else if (StateCounter == 43) begin //RESETING STATE SENDS THE COUNTER BACK TO STATE 0
		s_ready = 0;
		wr_en_m =0;
		wr_en_x =0;
		addr_x = 0;
		addr_m = 0;
		addr_y=3;
		enable0 =0;
		m_valid0=1;
	end
	else if (StateCounter == 44) begin //RESETING STATE SENDS THE COUNTER BACK TO STATE 0
		s_ready = 0;
		wr_en_m =0;
		wr_en_x =0;
		addr_x = 0;
		addr_m = 0;
		enable0 =0;
		m_valid0=0;
		clear_acc0=1;
	end

else if (StateCounter > 44 && StateCounter < 49) begin //CALCULATION STATES
		s_ready = 0;
		wr_en_m = 0;
		wr_en_x = 0;
		addr_x = StateCounter -45;
		addr_m = StateCounter -33;
		clear_acc0 =0;
		enable0 =1;
		m_valid0=0;
		if (StateCounter==46)
			begin	
			acc_source=1;
			end
		else
			acc_source=0;

	end
	else if (StateCounter == 49) begin //RESETING STATE SENDS THE COUNTER BACK TO STATE 0
		s_ready = 0;
		wr_en_m =0;
		wr_en_x =0;
		addr_x = 0;
		addr_m = 0;
		enable0 =0;
		m_valid0=1;
	end
	else if (StateCounter == 50) begin //RESETING STATE SENDS THE COUNTER BACK TO STATE 0
		s_ready = 0;
		wr_en_m =0;
		wr_en_x =0;
		addr_x = 0;
		addr_m = 0;
		enable0 =0;
		m_valid0=0;
		clear_acc0=1;
	end

end
end
	
endmodule






// ESE-507 Project 2, Fall 2017
// This simple testbench is provided to help you in testing Project 2, Part 1.
// This testbench is not sufficient to test the full correctness of your system, it's just
// a relatively small test to help you get started.

module check_timing3();

   logic clk, s_valid, s_ready, m_valid, m_ready, reset, overflow;
   logic signed [7:0] data_in;
   logic signed [15:0] data_out;
   
   initial clk=0;
   always #5 clk = ~clk;
   
//(clk, reset, s_valid, m_ready, addr_x, wr_en_x, addr_m, wr_en_m, addr_y,wr_en_y, clear_acc, s_ready, enable, m_valid,acc_source)
   mvm4_part3 dut (.clk(clk), .reset(reset), .s_valid(s_valid), .m_ready(m_ready), 
		   .data_in(data_in), .m_valid(m_valid), .s_ready(s_ready), .data_out(data_out),
		   .overflow(overflow));


   //////////////////////////////////////////////////////////////////////////////////////////////////
   // code to feed some test inputs

   // rb and rb2 represent random bits. Each clock cycle, we will randomize the value of these bits.
   // When rb is 0, we will not let our testbench send new data to the DUT.
   // When rb is 1, we can send data.
   logic rb, rb2;
   always begin
      @(posedge clk);
      #1;
      std::randomize(rb, rb2); // randomize rb
   end

   // Put our test data into this array. These are the values we will feed as input into the system.
   logic [7:0] invals[0:23] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11, 12,13,14,15,16, 1, 2, 3, 4,10, 20, 30,40};

   logic [24:0] j;

   // If s_valid is set to 1, we will put data on data_in.
   // If s_valid is 0, we will put an X on the data_in to test that your system does not 
   // process the invalid input.
   always @* begin
      if (s_valid == 1)
         data_in = invals[j];
      else
         data_in = 'x;
   end

   // If our random bit rb is set to 1, and if j is within the range of our test vector (invals),
   // we will set s_valid to 1.
   always @* begin
      if ((j>=0) && (j<24) && (rb==1'b1)) begin
         s_valid=1;
      end
      else
         s_valid=0;
   end

   // If we set s_valid and s_ready on this clock edge, we will increment j just after
   // this clock edge.
   always @(posedge clk) begin
      if (s_valid && s_ready)
         j <= #1 j+1;
   end
   ////////////////////////////////////////////////////////////////////////////////////////
   // code to receive the output values

   // we will use another random bit (rb2) to determine if we can assert m_ready.
   logic [15:0] i;
   always @* begin
      if ((i>=0) && (i<4) && (rb2==1'b1))
         m_ready = 1;
      else
         m_ready = 0;
   end

   always @(posedge clk) begin
      if (m_ready && m_valid) begin
         $display("y[%d] = %d" , i, data_out); 
         i=i+1; 
      end 
   end

   ////////////////////////////////////////////////////////////////////////////////

   initial begin
      j=0; i=0;
      $display("Small example: correct output is 40,90,140,190");

      // Before first clock edge, initialize
      m_ready = 0; 
      reset = 0;
   
      // reset
      @(posedge clk); #1; reset = 1; 
      @(posedge clk); #1; reset = 0; 

      // wait until 3 outputs have come out, then finish.
      wait(i==4);
      $finish;
   end


   // This is just here to keep the testbench from running forever in case of error.
   // In other words, if your system never produces three outputs, this code will stop 
   // the simulation after 1000 clock cycles.
   initial begin
      repeat(10000) begin
         @(posedge clk);
      end
      $display("Warning: Output not produced within 1000 clock cycles; stopping simulation so it doens't run forever");
      $stop;
   end

endmodule








// ESE-507 Project 2, Fall 2017

// This simple testbench is provided to help you in testing Project 2, Part 1.
// This testbench is not sufficient to test the full correctness of your system, it's just
// a relatively small test to help you get started.

// This testbench will test three matrix-vector multiplications. One of the outputs will
// overflow.

// The testbench will also check if your result is correct or not. If your design works
// correctly, you will see the following when you simulate:

/*
 # SUCCESS:          y[    0] =    186; overflow = 0
 # SUCCESS:          y[    1] =    152; overflow = 0
 # SUCCESS:          y[    2] =   -210; overflow = 0
 # SUCCESS:          y[    3] =   4191; overflow = 0
 # SUCCESS:          y[    4] = -17149; overflow = 1
 # SUCCESS:          y[    5] =    762; overflow = 0
 # SUCCESS:          y[    6] =   -494; overflow = 0
 # SUCCESS:          y[    7] =   1012; overflow = 0
 # SUCCESS:          y[    8] =    808; overflow = 0
 */

// If there is an error, you will see something like:
/*
 # SUCCESS:          y[    0] =    186; overflow = 0
 # SUCCESS:          y[    1] =    152; overflow = 0
 # SUCCESS:          y[    2] =   -210; overflow = 0
 # SUCCESS:          y[    3] =   4191; overflow = 0
 # ERROR:   Expected y[    4] = -17149; overflow = 1.   Instead your system produced: y[    4] = -17149; overflow = 0
 # SUCCESS:          y[    5] =    762; overflow = 0
 # SUCCESS:          y[    6] =   -494; overflow = 0
 # SUCCESS:          y[    7] =   1012; overflow = 0
 # SUCCESS:          y[    8] =    808; overflow = 0
 */

// Please let me know if you have any problems.

module check_timing1();

   logic clk, s_valid, s_ready, m_valid, m_ready, reset, overflow;
   logic signed [7:0] data_in;
   logic signed [15:0] data_out;
   
   initial clk=0;
   always #5 clk = ~clk;
   

   mvm3_part1 dut (.clk(clk), .reset(reset), .s_valid(s_valid), .m_ready(m_ready), 
		   .data_in(data_in), .m_valid(m_valid), .s_ready(s_ready), .data_out(data_out),
		   .overflow(overflow));


   //////////////////////////////////////////////////////////////////////////////////////////////////
   // code to feed some test inputs

   // rb and rb2 represent random bits. Each clock cycle, we will randomize the value of these bits.
   // When rb is 0, we will not let our testbench send new data to the DUT.
   // When rb is 1, we can send data.
   logic rb, rb2;
   always begin
      @(posedge clk);
      #1;
      std::randomize(rb, rb2); // randomize rb
   end

   // Put our test data into this array. These are the values we will feed as input into the system.
   logic [7:0] invals[0:35] = '{1, -8, 3, 9, -5, 11, -7, 8, -9, 1,  -22, 3, 
				10, 11, 12, 127, 127, 127, 1,  2, 3, 127, 127, 127,
				19, 18, -17,  16,  -15,  14, 13, -12, 11, 19, -22, 27 
				};

   
   
   logic signed [15:0] expVals[0:8]  = {186, 152, -210, 4191, -17149, 762, -494, 1012, 808};
   logic 	expOverflow[0:8] = {0, 0, 0, 0, 1, 0, 0, 0, 0};
   
   logic [15:0] j;

   // If s_valid is set to 1, we will put data on data_in.
   // If s_valid is 0, we will put an X on the data_in to test that your system does not 
   // process the invalid input.
   always @* begin
      if (s_valid == 1)
         data_in = invals[j];
      else
         data_in = 'x;
   end

   // If our random bit rb is set to 1, and if j is within the range of our test vector (invals),
   // we will set s_valid to 1.
   always @* begin
      if ((j>=0) && (j<36) && (rb==1'b1)) begin
         s_valid=1;
      end
      else
         s_valid=0;
   end

   // If we set s_valid and s_ready on this clock edge, we will increment j just after
   // this clock edge.
   always @(posedge clk) begin
      if (s_valid && s_ready)
         j <= #1 j+1;
   end
   ////////////////////////////////////////////////////////////////////////////////////////
   // code to receive the output values

   // we will use another random bit (rb2) to determine if we can assert m_ready.
   logic [15:0] i;
   always @* begin
      if ((i>=0) && (i<36) && (rb2==1'b1))
         m_ready = 1;
      else
         m_ready = 0;
   end

   always @(posedge clk) begin
      if (m_ready && m_valid) begin
	 if ((data_out == expVals[i]) && (overflow == expOverflow[i]))
           $display("SUCCESS:          y[%d] = %d; overflow = %b" , i, data_out, overflow);
	 else
	   $display("ERROR:   Expected y[%d] = %d; overflow = %b.   Instead your system produced: y[%d] = %d; overflow = %b" , i, expVals[i], expOverflow[i], i, data_out, overflow);
         i=i+1; 
      end 
   end

   ////////////////////////////////////////////////////////////////////////////////

   initial begin
      j=0; i=0;

      // Before first clock edge, initialize
      m_ready = 0; 
      reset = 0;
   
      // reset
      @(posedge clk); #1; reset = 1; 
      @(posedge clk); #1; reset = 0; 

      // wait until 3 outputs have come out, then finish.
      wait(i==9);
      $finish;
   end


   // This is just here to keep the testbench from running forever in case of error.
   // In other words, if your system never produces three outputs, this code will stop 
   // the simulation after 1000 clock cycles.
   initial begin
      repeat(1000) begin
         @(posedge clk);
      end
      $display("Warning: Output not produced within 1000 clock cycles; stopping simulation so it doens't run forever");
      $stop;
   end

endmodule











