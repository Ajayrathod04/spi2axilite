// ============================================================================
// Module Name: spi_cmd_decoder
// Description: Decodes the 8-bit SPI command byte into simple control signals.
//              8'h01 = WRITE
//              8'h02 = READ
//              Any other code = INVALID
// ============================================================================
module spi_cmd_decoder (
    input [7:0] cmd_byte,
    output reg write_en,
    output reg read_en,
    output reg invalid_cmd
);

    always @(*) begin
        // Default assignments to prevent latches
        write_en = 1'b0;
        read_en = 1'b0;
        invalid_cmd = 1'b0;

        case (cmd_byte)
            8'h01: begin
                write_en = 1'b1;
            end
            8'h02: begin
                read_en = 1'b1;
            end
            default: begin
                invalid_cmd = 1'b1;
            end
        endcase
    end

endmodule
