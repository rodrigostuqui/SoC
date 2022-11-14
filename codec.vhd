library ieee, std;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;

entity codec is
port (
    interrupt: in std_logic; -- Interrupt signal
    read_signal: in std_logic; -- Read signal
    write_signal: in std_logic; -- Write signal
    valid: out std_logic; -- Valid signal
    -- Byte written to codec
    codec_data_in : in std_logic_vector(7 downto 0);
    -- Byte read from codec
    codec_data_out : out std_logic_vector(7 downto 0)
);
end entity;

architecture behavior of codec is
    constant file_write :string  := "dados_write.dat";
    constant file_read :string  := "dados_read.dat";
    file fptr: text;
    signal aux_valid: std_logic := '0';
begin
    process (interrupt) is
        variable fstatus       :file_open_status;
        variable file_line     :line;
        variable aux_out : integer;
    begin
        
        if(read_signal = '1' and write_signal = '0') then
            file_open(fstatus, fptr, file_read, read_mode);
            if(fstatus = open_ok) then
                while not endfile(fptr) loop
                    readline(fptr, file_line);
                    read(file_line, aux_out);
                end loop;
                codec_data_out <= std_logic_vector(to_unsigned(aux_out, 8));
                aux_valid <= not aux_valid;
                file_close(fptr);
            end if;
        elsif (read_signal = '0' and write_signal = '1') then
            file_open(fstatus, fptr, file_write, append_mode);
            if(fstatus = open_ok) then
                write(file_line, to_integer(unsigned(codec_data_in)));
                writeline(fptr, file_line);
                aux_valid <= not aux_valid;

                file_close(fptr);
            end if;
        end if;
    end process;
    valid <= not aux_valid;
end architecture;