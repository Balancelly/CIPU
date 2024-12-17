module CIPU(
input       clk, 
input       rst,
input       [7:0]people_thing_in,//fifo1 in
input       ready_fifo, //data in
input       ready_lifo, //data in
input       [7:0]thing_in, //lifo1 in
input       [3:0]thing_num, //lifo1 out
output  reg    valid_fifo,
output  reg    valid_lifo,
output  reg    valid_fifo2,
output  reg    [7:0]people_thing_out,//fifo1 out
output  reg    [7:0]thing_out, //lifo1 out
output  reg    done_thing,
output  reg    done_fifo,
output  reg    done_lifo,
output  reg    done_fifo2);



reg [3:0] cs,ns;
reg [7:0] thing_tmp[0:15];
reg [3:0] i_counter,j_counter,zr_counter,zw_counter,s,ip,k_counter;
reg [3:0] pop_num;
reg [7:0] stack[0:15];




parameter idle=4'd0,fifo1=4'd1,lifo_r=4'd2,lifo_w=4'd3,fifo2=4'd4;


always@(posedge clk or posedge rst)begin
	if(rst)begin
		cs <= idle;
	end
	else begin
		cs <= ns;
	end
end

//fsm
always@(*)begin
	case(cs)
		idle:
		begin
			if(ready_lifo)begin
				ns = lifo_r;
			end
			else begin
				ns = idle;
			end
		end
		lifo_r:
		begin
			if(!done_lifo&&((thing_num!=4'd0&&thing_in==8'd59)||(thing_num==4'd0&&zr_counter==4'd2)))begin
				ns = lifo_w;
			end
			else if(thing_in==8'd36)begin
				ns = fifo2;
			end
			else begin
				ns = lifo_r;
			end
		end
		lifo_w:
		begin
			if(done_thing)begin
				ns = lifo_r;
			end
			else begin
				ns = lifo_w;
			end
		end
		fifo2:
		begin
			if(done_fifo2)begin
				ns = idle;
			end
			else begin
				ns = fifo2;
			end
		end
		
		default:ns = idle;
	endcase
end

		
//control line//fifo1?
always@(*)begin
	if(people_thing_in>8'd64 && people_thing_in<8'd91)begin//23A24G
		valid_fifo = 1'b1;
	end
	else begin
		valid_fifo = 1'b0;
	end
end

//control finish
always@(*)begin
	if(people_thing_in==8'd36)begin//fifo1 finish 
		done_fifo = 1'b1;
	end
	else begin
		done_fifo = 1'b0;
	end
end

//fifo1 people_thing_in/out 

always@(*)begin
	if(valid_fifo)begin//只有在這個fifo1狀態會輸出people_thing_value(A to Z)
		people_thing_out=people_thing_in;
	end
	else begin
		people_thing_out=people_thing_out;
	end
end




//lifo control
always@(*)begin 
	if(cs==lifo_r && thing_in==8'd36)begin//
		done_lifo = 1'b1;
	end
	else begin
		done_lifo = 1'b0;
	end
end


//control
always@(*)begin	
	if(cs==lifo_w && pop_num==4'b0 &&zw_counter==4'd2)begin
		valid_lifo=1'b1;
	end
	else begin
		if(cs==lifo_w && pop_num!=4'b0 && j_counter>=4'b1 && j_counter<=pop_num)begin //何時拉1to3
			valid_lifo=1'b1;
		end
		else begin
			valid_lifo=1'b0;
		end
	end
end

always@(posedge clk or posedge rst)begin 
	if(rst)begin
		done_thing<=1'b0;
	end
	else begin
		if(cs==lifo_w && pop_num==4'd0 && zw_counter==4'd2)begin
			done_thing<=1'b1;
		end
		else if(cs==lifo_w && pop_num!=4'd0 &&j_counter==pop_num)begin
			done_thing<=1'b1;
		end
		else begin
			done_thing<=1'b0;
		end
	end
end



//lifo read //i tmp寫一起 其他拉出來寫
//i_counter要再碰到59停止,在w維持 tmp也是
always@(posedge clk or posedge rst)begin
	if(rst)begin
		pop_num<=4'b0;
	end
	else begin
		if(cs==lifo_r)begin
			if(thing_num==4'b0)begin
				pop_num<=4'b0;
			end
			else begin
				if(thing_in!=8'd59)begin // 2 3
					pop_num<=thing_num;//pop_counter<=1(共有幾個要pop);

				end
				else begin//thing_in=8'd59 //;
					pop_num<=pop_num;
				end
			end
		end
		else if(cs==lifo_w)begin
			pop_num<=pop_num;
		end
		else begin //(cs==idle fifo2)
			pop_num <= 4'b0;
		end
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		i_counter<=4'd0;
		thing_tmp[i_counter]<=8'b0;
	end
	else begin
		if(cs==lifo_r)begin
			if(thing_in!=8'd59)begin
				i_counter<=i_counter+4'd1;//i不是8'd59時 要+1
				thing_tmp[i_counter][7:0] <= thing_in[7:0];//存0 1的值
			end
			else begin//i==8'd59時 ,停止加
				i_counter<=i_counter;
				thing_tmp[i_counter][7:0] <= thing_tmp[i_counter][7:0];//clk1 thing_tmp[0]<=thing_in,clk2 thing_tmp[1]<=thing_in,//共有幾個要存
			end
		end
		else if(cs==lifo_w)begin
			if(done_thing)begin//done thing拉起在回0
				i_counter<=4'd0;
				thing_tmp[i_counter][7:0]<=8'b0;
			end
			else begin
				i_counter<=i_counter;
				thing_tmp[i_counter][7:0]<=thing_tmp[i_counter][7:0];
			end
		end
		else begin
			i_counter<=4'd0;
			thing_tmp[i_counter][7:0]<=8'b0;
		end
	end
end	

//write	
always@(posedge clk or posedge rst)begin
	if(rst)begin
		j_counter<=4'b0;
	end
	else begin
		if(cs==lifo_r && thing_in==8'd59)begin
			j_counter<=4'b0;
		end
		else if(cs==lifo_w &&pop_num!=4'd0 && j_counter<pop_num &&!done_thing)begin
			j_counter<=j_counter+4'b1;
		end
		else if(cs==lifo_w &&pop_num!=4'd0&&j_counter==pop_num)begin
			j_counter<=4'b0;
		end
		else begin
			j_counter<=j_counter;
		end		
	end	
end

//thing_num==0
always@(posedge clk or posedge rst)begin
	if(rst)begin
		zr_counter<=4'b0;
	end
	else begin
		if(cs==lifo_r&&pop_num==4'd0)begin
			zr_counter<=zr_counter+4'b1;
		end
		else begin
			zr_counter<=4'b0;
		end
	end
end
			
			
always@(posedge clk or posedge rst)begin
	if(rst)begin
		zw_counter<=4'b0;
	end
	else begin
		if(cs==lifo_w&&pop_num==4'd0)begin
			zw_counter<=zw_counter+4'b1;
		end
		else begin
			zw_counter<=4'b0;
		end
	end
end
				

//thing_out

always@(posedge clk or posedge rst)begin
	if(rst)begin
		thing_out<=8'b0;
	end
	else begin
		if(cs==lifo_w && pop_num==4'b0 &&zw_counter==4'd1)begin
			thing_out<=8'd48;
		end
		else begin
			if(cs==lifo_w && j_counter<pop_num)begin//cs==3
				thing_out<=thing_tmp[i_counter-j_counter-4'd1];//2-0-1=1 //2-1-1=0
			end
			else if(cs==lifo_w && j_counter==pop_num && pop_num!=4'b0)begin
				thing_out<=8'b0;
			end
			else if(done_thing)begin
				thing_out<=8'b0;
			end
			else if(cs==fifo2)begin
				thing_out<=stack[s];
			end
			else begin
				thing_out<=thing_out;
			end
		end
	end
end


//fifo2
//ip為stack內剩餘個數
always@(posedge clk or posedge rst)begin
	if(rst)begin
		ip<=4'd0;
	end
	else begin
		if(cs==lifo_r && thing_in==8'd59)begin
			ip<=i_counter-thing_num;
		end
		else if(cs==lifo_w)begin
			ip<=ip;
		end
		else begin
			ip<=4'd0;
		end
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		k_counter<=4'd0;
	end
	else begin
		if(cs==lifo_r && thing_in==8'd59)begin
			k_counter<=4'd0;
		end
		else if(cs==lifo_w && ip!=4'd0 && k_counter<ip)begin
			k_counter<=k_counter+4'd1;
		end
		else begin 
			k_counter<=k_counter;
		end
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		stack[s]<=8'd0;
	end
	else begin
		if(cs==lifo_w && ip!=4'd0 && k_counter<ip)begin//cs==3
			stack[s]<=thing_tmp[k_counter];//2-0-1=1 //2-1-1=0
		end
		else begin
			stack[s]<=stack[s];
		end
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		s<=4'd0;
	end
	else begin
		if(cs==lifo_w && ip!=4'd0 && k_counter<ip)begin
			s<=s+4'd1;
		end
		else if(done_lifo)begin
			s<=4'd0;
		end
		else if(cs==fifo2)begin
			s<=s+4'd1;
		end
		else begin
			s<=s;
		end
	end
end

//counter
always@(*)begin
	if(cs==fifo2&&s>=4'd1&&s<=4'd10)begin
		valid_fifo2 = 1'b1;
	end
	else begin
		valid_fifo2 = 1'b0;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		done_fifo2<=1'b0;
	end
	else begin
		if(cs==fifo2&&s==4'd10)begin
			done_fifo2 = 1'b1;
		end
		else begin
			done_fifo2 = 1'b0;
		end
	end
end

endmodule
