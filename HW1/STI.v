module STI(clk ,reset, load, pi_data, pi_length, pi_msb, pi_low,
           so_data, so_valid );
input clk, reset;
input load, pi_msb, pi_low;
input [15:0]  pi_data;
input pi_length;
output reg so_valid;
output so_data;

reg [15:0] in_data;
reg [3:0] cont;
reg [1:0] state;
reg reg_piMsb, reg_piLow, reg_piLength, done;
parameter st_wait = 2'b00;
parameter st_pause = 2'b01;
parameter st_run = 2'b10;

wire [15:0] data_out;

genvar i;
generate
for(i=0;i<16;i=i+1) begin: array
  assign data_out[i] = ( reg_piMsb == 1 )? in_data[15 - i] : in_data[i];
end
assign so_data = data_out[cont];
endgenerate

always@(posedge clk, posedge reset)
  if(reset) begin
    in_data <= 16'b0;
    reg_piMsb <= 0;
    reg_piLow <= 0;
    reg_piLength <= 0;
  end
  else begin
    in_data <= (load)? pi_data: in_data;
    reg_piMsb <= (load)? pi_msb:reg_piMsb;
    reg_piLow <= (load)? pi_low:reg_piLow;
    reg_piLength <= (load)? pi_length:reg_piLength;
  end

always@(posedge clk, posedge reset)
  if(reset)
    state <= st_wait;
  else
    case(state)
      st_wait: 
        state <= (load)? st_pause:st_wait;
      st_pause:
        state <= st_run;
      st_run: 
        state <= (done)? st_wait:st_run;
    endcase

always@(posedge clk, posedge reset) begin
  if(reset) begin
    cont <= 0;
    so_valid <= 0;
    done <= 0;
  end
  else begin
    case(state)
      st_wait: begin
        so_valid <= 0;
        done <= 0;
        if(load && pi_low && !pi_length && !pi_msb)
          cont <= 4'b1000;
        else if(load && !pi_low && !pi_length && pi_msb)
          cont <= 4'b1000;
        else
          cont <= 4'b0000;
      end
      st_pause: begin
        so_valid <= 1;
        done <= 0;
        cont <= cont;
      end
      st_run: begin
        if(reg_piLength) begin
          cont <= ( cont == 4'b1111)? cont : cont + 1;
          done <= ( cont == 4'b1111)? 1 : 0;
          so_valid <= ( cont == 4'b1111)? 0:1;
        end
        else if(reg_piMsb && !done) begin
          cont <= (!reg_piLow)? (( cont == 4'b1111)? cont : cont + 1) : (( cont == 4'b0111)? cont : cont + 1);
          done <= (!reg_piLow)? (( cont == 4'b1111)? 1 : 0) : (( cont == 4'b0111)? 1 : 0);
          so_valid <= (!reg_piLow)? (( cont == 4'b1111)? 0:1) : (( cont == 4'b0111)? 0:1);
        end
        else if(!done) begin
          cont <= (reg_piLow)? (( cont == 4'b1111)? cont : cont + 1) : (( cont == 4'b0111)? cont : cont + 1);
          done <= (reg_piLow)? (( cont == 4'b1111)? 1 : 0) : (( cont == 4'b0111)? 1 : 0);
          so_valid <= (reg_piLow)? (( cont == 4'b1111)? 0:1) : (( cont == 4'b0111)? 0:1);
        end
      end
    endcase
  end
end

endmodule
