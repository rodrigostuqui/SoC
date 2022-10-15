library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_codec is

end entity;

architecture mixed of tb_codec is
    signal interrupt: std_logic := '0'; -- Interrupt signal
    signal read_signal: std_logic := '0'; -- Read signal
    signal write_signal: std_logic := '1'; -- Write signal
    signal valid: std_logic; -- Valid signal
    -- Byte written to codec
    signal codec_data_in : std_logic_vector(7 downto 0) := "00001010";
    -- Byte read from codec
    signal codec_data_out : std_logic_vector(7 downto 0);
begin
   
    mem: entity work.codec(behavior)
        port map(interrupt, read_signal, write_signal, valid, codec_data_in, codec_data_out);


    estimulo: process is
        variable aux_valid : std_logic := '1';
    begin
        interrupt <= not interrupt;
        wait for 3 ns;
        assert aux_valid = valid
        report "Valor não escrito"
        severity failure;
        read_signal <= '1';
        write_signal <= '0';
        interrupt <= not interrupt;
        wait for 3 ns;
        assert aux_valid = valid
        report "Valor não lido"
        severity failure;

    wait;
    end process estimulo;

end architecture;