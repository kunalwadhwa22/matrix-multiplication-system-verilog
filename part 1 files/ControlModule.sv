module ControlModule(clk, reset, s_valid, m_ready, addr_x, wr_en_x, addr_m, wr_en_m, clear_acc, m_valid, s_ready, enable_f);


input clk, reset, s_valid, m_ready;

output logic m_valid, s_ready, wr_en_x, wr_en_m, clear_acc, enable_f;

//INTERNAL SIGNALS
logic unsigned [4:0] StateCounter ;
output logic unsigned [5:0] addr_m;
output logic unsigned [5:0] addr_x;





always_ff @(posedge clk) begin


if (reset==1) begin
	StateCounter <=0;
	wr_en_m <= 0;
	wr_en_x <= 0;
	s_ready <=0;
	m_valid <=0;
	clear_acc <=0;
	addr_m <= 0;
	addr_x <= 0;
	enable_f <=0;

	
end

else begin

if (StateCounter < 12) begin // READ AND STORE MODE
	s_ready <=1;
	m_valid <=0;
	enable_f <=0;
	
	if (s_valid == 1) begin //THE SYSTEM IS GETTING INPUT AND STORING IT IN ITS MEMORY
		StateCounter <= StateCounter +1;
		
		if (StateCounter <3) begin
			addr_x <= StateCounter;
			wr_en_x <=1;
			addr_m <= 0;
			wr_en_m <=0;
			clear_acc <=1;
		end
		else if (StateCounter >2 && StateCounter < 12) begin
			addr_x <= 0;
			wr_en_x <=0;
			addr_m <= StateCounter -3;
			wr_en_m <=1;
			clear_acc <=0;
		end
	end
	else begin //NO INPUT IS GIVEN TO THE SYSTEM AND/OR THE SYSTEM IS NOT READY FOR NEW INPUT
		StateCounter <= StateCounter;
		wr_en_m <= 0;
		wr_en_x <= 0;
		addr_m <= addr_m;
		addr_x <= addr_x;
		clear_acc <= 1;
	end
end
else if (StateCounter > 11 && StateCounter < 15 ) begin // CALCULATION STATES
	s_ready <= 0;
	StateCounter <= StateCounter +1;
	wr_en_m <= 0;
	wr_en_x <= 0;
	addr_x <= StateCounter -12;
	addr_m <= StateCounter -12;
	clear_acc <=0;
	m_valid<=0;
	enable_f <=1;
end
if (StateCounter == 15 ) begin 
	s_ready <= 0;
	wr_en_m <= 0;
	wr_en_x <= 0;
	addr_m <= 3;
	addr_x <= 0;
	m_valid <= 0;
	enable_f <=0;

	if (m_ready == 1) begin
		StateCounter <= StateCounter +1;
		clear_acc <= 1;
	end	
	else begin
		StateCounter <= StateCounter;
		clear_acc <= 0;
	end
end
else if (StateCounter > 15 && StateCounter < 19) begin //CALCULATION STATES
	s_ready <= 0;
	StateCounter <= StateCounter +1;
	wr_en_m <= 0;
	wr_en_x <= 0;
	addr_x <= StateCounter -16;
	addr_m <= StateCounter -13;
	clear_acc <= 0;
	m_valid <= 0;
	enable_f <=1;
end
else if (StateCounter == 19 ) begin // WAITING STATE
	s_ready <= 0;
	wr_en_m <= 0;
	wr_en_x <= 0;
	addr_m <= 6;
	addr_x <= 0;
	m_valid <= 0;
	enable_f <=0;

	if (m_ready == 1) begin
		StateCounter <= StateCounter +1;
		clear_acc <= 1;
	end	
	else begin
		StateCounter <= StateCounter;
		clear_acc <= 0;
	end
end
else if (StateCounter > 19 && StateCounter < 23) begin //CALCULATION STATES
	s_ready <= 0;
	StateCounter <= StateCounter +1;
	wr_en_m <= 0;
	wr_en_x <= 0;
	addr_x <= StateCounter -20;
	addr_m <= StateCounter -14;
	clear_acc <=0;
	m_valid<=0;
	enable_f <=1;
end
else if (StateCounter == 23) begin //RESETING STATE SENDS THE COUNTER BACK TO STATE 0
	s_ready <= 0;
	m_valid <= 1;
	wr_en_m<=0;
	wr_en_x<=0;
	addr_x<= 0;
	addr_m<= 0;
	enable_f<=0;
	if (m_ready == 1) begin
		StateCounter <= 0;
	end	
	else begin
		StateCounter <= StateCounter;
	end	
end

end
end

endmodule

module TB ();

logic clk, reset, s_valid, m_ready, enable_f;
logic m_valid, s_ready, wr_en_x, wr_en_m, clear_acc;
int i;
logic unsigned [5:0] addr_m;
logic unsigned [5:0] addr_x;

ControlModule dut(.enable_f(enable_f), .clk(clk), .reset(reset), .s_valid(s_valid), .m_ready(m_ready), .m_valid(m_valid), .s_ready(s_ready), .wr_en_x(wr_en_x), .wr_en_m(wr_en_m), .clear_acc(clear_acc), .addr_m(addr_m), .addr_x(addr_x));


initial clk = 0;
   always #5 clk = ~clk;

initial begin
$display("\t\t\tTESTING STARTS HERE!");

m_ready = 1;
s_valid = 1;

reset = 1;
$display($time,, "reset=%b, addr_m=%d, addr_x=%d, s_ready=%b, m_valid=%b, clear_acc=%b, enable_f=%b", reset, addr_m, addr_x, s_ready, m_valid, clear_acc, enable_f);
@(posedge clk);#1;
reset = 0;


for (i = 0; i< 50; i = i+1) begin
@(posedge clk);#1;
$display($time,, "reset=%b, addr_m=%d, addr_x=%d, s_ready=%b, m_valid=%b, clear_acc=%b, enable_f=%b", reset, addr_m, addr_x, s_ready, m_valid, clear_acc, enable_f);
end



@(posedge clk);
$finish; // Stop simulation

end


endmodule
