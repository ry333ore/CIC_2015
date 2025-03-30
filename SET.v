module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;
reg busy;
reg valid;
reg [7:0] candidate;
/////////////////////////////////////////
reg [6:0] cs,ns;
parameter RST=0,A=1,B=2,C=3,DIS=4,ANS=5,FINISH=6;
//circle
reg [3:0] X_r,Y_r,R_r;
//
reg [1:0] in_circle;
//cnt
reg [1:0] cnt;
reg [3:0] i,j;
//
wire [3:0] X_d,Y_d;
wire [7:0] distance;
assign X_d = (X_r >= i) ? (X_r - i) : (i - X_r);
assign Y_d = (Y_r >= j) ? (Y_r - j) : (j - Y_r);
assign distance = (X_d)*(X_d) + (Y_d)*(Y_d);
//
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cs <= 'd0;
        cs[RST] <= 1'd1;
    end
    else cs <= ns;
end

always @(*) begin
    ns = 'd0;
    case (1'd1)
        cs[RST]:begin
            if(en) ns[A] = 1'd1;
            else ns[RST] = 1'd1;
        end 
        cs[A]:ns[DIS] = 1'd1;
        cs[B]:ns[DIS] = 1'd1;
        cs[C]:ns[DIS] = 1'd1;
        cs[DIS]:begin
            case (mode)
                2'd0:ns[ANS] = 1'd1;
                2'd1:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd2:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd3:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else if(cnt==2'd2) ns[C] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                default:ns[RST] = 1'd1;
            endcase
        end
        cs[ANS]:begin
            if(i==4'd0 && j==4'd0) ns[FINISH] = 1'd1;
            else ns[A] = 1'd1;
        end
        cs[FINISH]:ns[RST] = 1'd1;
        default:ns[RST] = 1'd1;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        busy <= 1'd0;
        valid <= 1'd0;
        candidate <= 8'd0;
        //X Y R
        X_r <= 4'd0;
        Y_r <= 4'd0;
        R_r <= 4'd0;
    
        cnt <= 2'd0;

        in_circle <= 2'd0;
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                busy <= 1'd0;
                valid <= 1'd0;
                candidate <= 8'd0;
                //X Y R
                X_r <= 4'd0;
                Y_r <= 4'd0;
                R_r <= 4'd0;
    
                cnt <= 2'd0;

                in_circle <= 2'd0;    
            end
            ns[A]:begin
                busy <= 1'd1;
                X_r <= central[23:20];
                Y_r <= central[19:16];
                R_r <= radius [11: 8];
                cnt <= 2'd1;
            end
            ns[B]:begin
                X_r <= central[15:12];
                Y_r <= central[11: 8];
                R_r <= radius [ 7: 4];
                cnt <= 2'd2;
            end
            ns[C]:begin
                X_r <= central[ 7: 4];
                Y_r <= central[ 3: 0];
                R_r <= radius [ 3: 0];
                cnt <= 2'd3;
            end
            ns[DIS]:begin
                if(distance <= (R_r)*(R_r)) in_circle <= in_circle+2'd1;
                else in_circle <= in_circle;
            end
            ns[ANS]:begin
                in_circle <= 2'd0;
                case (mode)
                    2'd0:begin
                        if(in_circle==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end 
                    2'd1:begin
                        if(in_circle==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd2:begin
                        if(in_circle==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd3:begin
                        if(in_circle==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    default: candidate <= candidate;
                endcase
            end
            ns[FINISH]:valid <= 1'd1;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        i <= 4'd1;
        j <= 4'd1;
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                i <= 4'd1;
                j <= 4'd1;
            end
            ns[ANS]:begin
                if(i==4'd8 && j==4'd8)begin
                    i <= 4'd0;
                    j <= 4'd0;
                end
                else if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end
        endcase
    end
end
endmodule
//1
/*
module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;

reg busy;
reg valid;
reg [7:0] candidate;
/////////////////////////////////////////
reg [8:0] cs,ns;

reg [1:0] mode_r;

reg [3:0] X_r,Y_r,R_r,
          B_x,B_y,B_r,
          C_x,C_y,C_r;

reg [1:0] dis [64:1];


reg [1:0] cnt;
reg [3:0] i,j;
integer k;

wire [7:0] distance;
wire [3:0] X_d,Y_d;
wire [6:0] addr;

parameter RST=0,A=1,B=2,C=3,DIS=4,WAIT_1=5,ANS=6,WAIT_2=7,FINISH=8;

assign X_d = (X_r >= i) ? (X_r - i) : (i - X_r);
assign Y_d = (Y_r >= j) ? (Y_r - j) : (j - Y_r);
assign distance = (X_d)*(X_d) + (Y_d)*(Y_d);

assign addr = i+63'd8*(j-4'd1);

always @(posedge clk or posedge rst) begin
    if(rst)begin
        cs <= 'd0;
        cs[RST] <= 1'd1;
    end
    else cs <= ns;
end


always@(*)begin
    ns = 'd0;
    case (1'd1)
        cs[RST]:begin
            if(en) ns[A] = 1'd1;
            else ns[RST] = 1'd1;
        end 
        cs[A]:ns[DIS] = 1'd1;
        cs[B]:ns[DIS] = 1'd1;
        cs[C]:ns[DIS] = 1'd1;
        cs[DIS]:begin
            if(i==4'd8 && j==4'd8) ns[WAIT_1] = 1'd1;
            else ns[DIS] = 1'd1;
        end
        cs[WAIT_1]:begin
            case (mode_r)
                2'd0:ns[ANS] = 1'd1;
                2'd1:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd2:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd3:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else if(cnt==2'd2) ns[C] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
            endcase
        end
        cs[ANS]:begin
            if(i==4'd8 && j==4'd8) ns[WAIT_2] = 1'd1;
            else ns[ANS] = 1'd1;
        end  
        cs[WAIT_2]:ns[FINISH] = 1'd1;
        cs[FINISH]:ns[RST] = 1'd1;
    endcase
end


always @(posedge clk or posedge rst) begin
    if(rst)begin
        busy <= 1'd0; 
        valid <= 1'd0; 
        candidate <= 8'd0; 
        //mode
        mode_r <= 2'd0;
        //A
        X_r <= 4'd0;
        Y_r <= 4'd0;
        R_r <= 4'd0;
        //B
        B_x <= 4'd0;
        B_y <= 4'd0;
        B_r <= 4'd0;
        //C
        C_x <= 4'd0;
        C_y <= 4'd0;
        C_r <= 4'd0;
        
        cnt <= 2'd0;

        for(k=1 ;k<65 ;k=k+1)begin
            dis[k] <= 2'd0;            
        end
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                busy <= 1'd0;
                valid <= 1'd0;
                candidate <= 8'd0;
                ///
                mode_r <= 2'd0;
                X_r <= 4'd0;
                Y_r <= 4'd0;
                R_r <= 4'd0;

                B_x <= 4'd0;
                B_y <= 4'd0;
                B_r <= 4'd0;
                
                C_x <= 4'd0;
                C_y <= 4'd0;
                C_r <= 4'd0;
                
                cnt <= 2'd0;

                for(k=1 ;k<65 ;k=k+1)begin
                    dis[k] <= 2'd0;            
                end
            end 
            ns[A]:begin
                busy <= 1'd1;
                mode_r <= mode;

                X_r <= central[23:20];
                Y_r <= central[19:16];
                R_r <= radius [11: 8];

                B_x <= central[15:12];
                B_y <= central[11: 8];
                B_r <= radius [ 7: 4];
            
                C_x <= central[ 7: 4];
                C_y <= central[ 3: 0];
                C_r <= radius [ 3: 0];

                cnt <= cnt+2'd1;
            end
            ns[B]:begin
                X_r <= B_x;
                Y_r <= B_y;
                R_r <= B_r;

                cnt <= cnt+2'd1;
            end
            ns[C]:begin
                X_r <= C_x;
                Y_r <= C_y;
                R_r <= C_r;

                cnt <= cnt+2'd1;
            end
            ns[DIS]:begin
                //in
                if(distance <= (R_r)*(R_r))begin 
                    dis[addr] <= dis[addr] +1'd1;
                end 
                //out
                else begin 
                    dis[addr] <= dis[addr];
                end                
            end
            ns[WAIT_1]:begin
                //in
                if(distance <= (R_r)*(R_r))begin 
                    dis[addr] <= dis[addr] +1'd1;
                end 
                //out
                else begin 
                    dis[addr] <= dis[addr];
                end                
            end
            ns[ANS]:begin
                case (mode_r)
                    2'd0:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd1:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd2:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd3:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                endcase
            end
            ns[WAIT_2]:begin
                case (mode_r)
                    2'd0:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd1:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd2:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd3:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                endcase
            end
            ns[FINISH]:valid <= 1'd1;
        endcase
    end
end


always @(posedge clk or posedge rst) begin
    if(rst) begin
        i <= 4'd1;
        j <= 4'd1;
    end
    else begin
        case (1'd1)
            //ns[A],ns[B],ns[C],ns[FINISH],ns[WAIT_2]:;
            ns[RST]:begin
                i <= 4'd1;
                j <= 4'd1;
            end
            ns[DIS]:begin
                if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end  
            ns[WAIT_1]:begin
                i <= 1'd1;
                j <= 1'd1;
            end
            ns[ANS]:begin
                if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end
        endcase

    end
end
endmodule
*/


//////////////////////////2
/*
module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;

reg busy;
reg valid;
reg [7:0] candidate;
/////////////////////////////////////////
reg [7:0] cs,ns;
parameter RST=0,A=1,B=2,C=3,DIS=4,WAIT_1=5,ANS=6,FINISH=7;
//circle
reg [1:0] mode_r;
reg [3:0] X_r,Y_r,R_r,
          B_x,B_y,B_r,
          C_x,C_y,C_r;
//X_r = central[23:20]
//Y_r = central[19:16]
//B_x = central[15:12]
//B_y = central[11: 8]
//C_x = central[ 7: 4]
//C_y = central[ 3: 0]
//R_r = radius [11: 8]
//B_r = radius [ 7: 4]
//C_r = radius [ 3: 0]

//in out
reg [1:0] dis [64:1];
//cnt
reg [1:0] cnt;
reg [3:0] i,j;
integer k;
//
wire [3:0] X_d,Y_d;
wire [7:0] distance;
assign X_d = (X_r >= i) ? (X_r - i) : (i - X_r);
assign Y_d = (Y_r >= j) ? (Y_r - j) : (j - Y_r);
assign distance = (X_d)*(X_d) + (Y_d)*(Y_d);
//
wire [6:0] addr;
assign addr = i+63'd8*(j-4'd1);
//
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cs <= 'd0;
        cs[RST] <= 1'd1;
    end
    else cs <= ns;
end

always@(*)begin
    ns = 'd0;
    case (1'd1)
        cs[RST]:begin
            if(en) ns[A] = 1'd1;
            else ns[RST] = 1'd1;
        end 
        cs[A]:ns[DIS] = 1'd1;
        cs[B]:ns[DIS] = 1'd1;
        cs[C]:ns[DIS] = 1'd1;
        cs[DIS]:begin
            if(i==4'd0 && j==4'd0) ns[WAIT_1] = 1'd1;
            else ns[DIS] = 1'd1;
        end
        cs[WAIT_1]:begin
            case (mode_r)
                2'd0:ns[ANS] = 1'd1;
                2'd1:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd2:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd3:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else if(cnt==2'd2) ns[C] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
            endcase
        end
        cs[ANS]:begin
            if(i==4'd0 && j==4'd0) ns[FINISH] = 1'd1;
            else ns[ANS] = 1'd1;
        end  
        cs[FINISH]:ns[RST] = 1'd1;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        busy <= 1'd0; 
        valid <= 1'd0; 
        candidate <= 8'd0; 
        //mode
        mode_r <= 2'd0;
        //A
        X_r <= 4'd0;
        Y_r <= 4'd0;
        R_r <= 4'd0;
        //B
        B_x <= 4'd0;
        B_y <= 4'd0;
        B_r <= 4'd0;
        //C
        C_x <= 4'd0;
        C_y <= 4'd0;
        C_r <= 4'd0;
        
        cnt <= 2'd0;

        for(k=1 ;k<65 ;k=k+1)begin
            dis[k] <= 2'd0;            
        end
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                busy <= 1'd0;
                valid <= 1'd0;
                candidate <= 8'd0;
                ///
                mode_r <= 2'd0;
                X_r <= 4'd0;
                Y_r <= 4'd0;
                R_r <= 4'd0;

                B_x <= 4'd0;
                B_y <= 4'd0;
                B_r <= 4'd0;
                
                C_x <= 4'd0;
                C_y <= 4'd0;
                C_r <= 4'd0;
                
                cnt <= 2'd0;

                for(k=1 ;k<65 ;k=k+1)begin
                    dis[k] <= 2'd0;            
                end
            end 
            ns[A]:begin
                busy <= 1'd1;
                mode_r <= mode;

                X_r <= central[23:20];
                Y_r <= central[19:16];
                R_r <= radius [11: 8];

                B_x <= central[15:12];
                B_y <= central[11: 8];
                B_r <= radius [ 7: 4];
            
                C_x <= central[ 7: 4];
                C_y <= central[ 3: 0];
                C_r <= radius [ 3: 0];

                cnt <= cnt+2'd1;
            end
            ns[B]:begin
                X_r <= B_x;
                Y_r <= B_y;
                R_r <= B_r;

                cnt <= cnt+2'd1;
            end
            ns[C]:begin
                X_r <= C_x;
                Y_r <= C_y;
                R_r <= C_r;

                cnt <= cnt+2'd1;
            end
            ns[DIS]:begin
                //in
                if(distance <= (R_r)*(R_r))begin 
                    dis[addr] <= dis[addr] +1'd1;
                end 
                //out
                else begin 
                    dis[addr] <= dis[addr];
                end                
            end
            ns[WAIT_1]:;
            ns[ANS]:begin
                case (mode_r)
                    2'd0:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd1:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd2:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd3:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                endcase
            end
            ns[FINISH]:valid <= 1'd1;
        endcase
    end
end


always @(posedge clk or posedge rst) begin
    if(rst) begin
        i <= 4'd1;
        j <= 4'd1;
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                i <= 4'd1;
                j <= 4'd1;
            end
            ns[DIS]:begin
                if(i==4'd8 && j==4'd8)begin
                    i <= 4'd0;
                    j <= 4'd0;
                end
                else if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end  
            ns[WAIT_1]:begin
                i <= 1'd1;
                j <= 1'd1;
            end
            ns[ANS]:begin
                if(i==4'd8 && j==4'd8)begin
                    i <= 4'd0;
                    j <= 4'd0;
                end
                else if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end
        endcase

    end
end
endmodule
*/
//////////////3
/*
module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;
reg busy;
reg valid;
reg [7:0] candidate;
/////////////////////////////////////////
reg [7:0] cs,ns;
parameter RST=0,A=1,B=2,C=3,DIS=4,WAIT_1=5,ANS=6,FINISH=7;
//circle
reg [3:0] X_r,Y_r,R_r;
//X_r = central[23:20]
//Y_r = central[19:16]
//B_x = central[15:12]
//B_y = central[11: 8]
//C_x = central[ 7: 4]
//C_y = central[ 3: 0]
//R_r = radius [11: 8]
//B_r = radius [ 7: 4]
//C_r = radius [ 3: 0]

//in out
reg [1:0] dis [64:1];
//cnt
reg [1:0] cnt;
reg [3:0] i,j;
integer k;
//
wire [3:0] X_d,Y_d;
wire [7:0] distance;
assign X_d = (X_r >= i) ? (X_r - i) : (i - X_r);
assign Y_d = (Y_r >= j) ? (Y_r - j) : (j - Y_r);
assign distance = (X_d)*(X_d) + (Y_d)*(Y_d);
//
wire [6:0] addr;
assign addr = i+63'd8*(j-4'd1);
//
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cs <= 'd0;
        cs[RST] <= 1'd1;
    end
    else cs <= ns;
end

always@(*)begin
    ns = 'd0;
    case (1'd1)
        cs[RST]:begin
            if(en) ns[A] = 1'd1;
            else ns[RST] = 1'd1;
        end 
        cs[A]:ns[DIS] = 1'd1;
        cs[B]:ns[DIS] = 1'd1;
        cs[C]:ns[DIS] = 1'd1;
        cs[DIS]:begin
            if(i==4'd0 && j==4'd0) ns[WAIT_1] = 1'd1;
            else ns[DIS] = 1'd1;
        end
        cs[WAIT_1]:begin
            case (mode)
                2'd0:ns[ANS] = 1'd1;
                2'd1:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd2:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
                2'd3:begin
                    if(cnt==2'd1) ns[B] = 1'd1;
                    else if(cnt==2'd2) ns[C] = 1'd1;
                    else ns[ANS] = 1'd1;
                end
            endcase
        end
        cs[ANS]:begin
            if(i==4'd0 && j==4'd0) ns[FINISH] = 1'd1;
            else ns[ANS] = 1'd1;
        end  
        cs[FINISH]:ns[RST] = 1'd1;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        busy <= 1'd0;
        valid <= 1'd0;
        candidate <= 8'd0;
        //X Y R
        X_r <= 4'd0;
        Y_r <= 4'd0;
        R_r <= 4'd0;
    
        cnt <= 2'd0;

        for(k=1 ;k<65 ;k=k+1)begin
            dis[k] <= 2'd0;            
        end
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                busy <= 1'd0;
                valid <= 1'd0;
                candidate <= 8'd0;
                //
                X_r <= 4'd0;
                Y_r <= 4'd0;
                R_r <= 4'd0;

                cnt <= 2'd0;

                for(k=1 ;k<65 ;k=k+1)begin
                    dis[k] <= 2'd0;            
                end
            end 
            ns[A]:begin
                busy <= 1'd1;

                X_r <= central[23:20];
                Y_r <= central[19:16];
                R_r <= radius [11: 8];

                cnt <= 2'd1;
            end
            ns[B]:begin
                X_r <= central[15:12];
                Y_r <= central[11: 8];
                R_r <= radius [ 7: 4];

                cnt <= 2'd2;
            end
            ns[C]:begin
                X_r <= central[ 7: 4];
                Y_r <= central[ 3: 0];
                R_r <= radius [ 3: 0];

                cnt <= 2'd3;
            end
            ns[DIS]:begin
                //in
                if(distance <= (R_r)*(R_r))begin 
                    dis[addr] <= dis[addr] +1'd1;
                end 
                //out
                else begin 
                    dis[addr] <= dis[addr];
                end                
            end
            ns[WAIT_1]:;
            ns[ANS]:begin
                case (mode)
                    2'd0:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd1:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd2:begin
                        if(dis[addr]==2'd1) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                    2'd3:begin
                        if(dis[addr]==2'd2) candidate <= candidate+8'd1;
                        else candidate <= candidate;
                    end
                endcase
            end
            ns[FINISH]:valid <= 1'd1;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        i <= 4'd1;
        j <= 4'd1;
    end
    else begin
        case (1'd1)
            ns[RST]:begin
                i <= 4'd1;
                j <= 4'd1;
            end
            ns[DIS]:begin
                if(i==4'd8 && j==4'd8)begin
                    i <= 4'd0;
                    j <= 4'd0;
                end
                else if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end  
            ns[WAIT_1]:begin
                i <= 1'd1;
                j <= 1'd1;
            end
            ns[ANS]:begin
                if(i==4'd8 && j==4'd8)begin
                    i <= 4'd0;
                    j <= 4'd0;
                end
                else if(i==4'd8)begin
                    i <= 4'd1;
                    j <= j+4'd1;
                end
                else begin
                    i <= i+4'd1;
                    j <= j;
                end
            end
        endcase

    end
end
endmodule
*/