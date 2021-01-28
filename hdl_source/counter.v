// Coherent Sampling Module
// 2020-03-07 Naoki F., AIT
// New BSD License is applied. See COPYING file for details.

module COUNTER (CLK, RST, CLK_FF, D_FF, COUNT, COUNT_EN);
    input            CLK, RST;
    input            CLK_FF, D_FF;
    output reg [7:0] COUNT;
    output           COUNT_EN;

    parameter  [9:0] PERIOD = 10'd960;

    reg              q_ff, max_set;
    reg        [9:0] p_count;
    reg        [7:0] count;
    reg        [7:0] max;
    reg        [2:0] set_hist;

    // first stage: D-Flipflop (driven by CLK_FF)
    always @(posedge CLK_FF) begin
        q_ff <= D_FF;
    end

    // second stage: Counter (driven by CLK_FF)
    always @(posedge CLK_FF) begin
        if (RST) begin
            count   <= 8'h00;
            p_count <= 10'h000;
            max     <= 8'h00;
            max_set <= 1'b0;
        end else if (p_count == PERIOD - 1'b1) begin
            max     <= count;
            max_set <= 1'b1;
            count   <= {7'h00, q_ff};
            p_count <= 10'h000;
        end else begin
            max_set <= 1'b0;
            p_count <= p_count + 1'b1;
            if (q_ff) begin
                // distinguish 128, 256, 384, ... from zero
                count   <= (count + 1'b1) | (count & 8'h80);
            end
        end
    end

    // last stage: Output Enable (driven by CLK)
    //   set_hist[1:0] - for double flop synchronization
    //   set_hist[2]   - for edge detection
    assign COUNT_EN = ~ set_hist[2] & set_hist[1];
    always @(posedge CLK) begin
        if (RST) begin
            set_hist  <= 3'b000;
            COUNT <= 8'h00;
        end else begin
            set_hist  <= {set_hist[1:0], max_set};
            if (set_hist[0]) begin
                COUNT <= max;
            end
        end
    end

endmodule