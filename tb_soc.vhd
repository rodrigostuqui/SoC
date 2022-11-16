library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_soc is

end entity;

architecture mixed of tb_soc is
    signal clock: std_logic := '1';
    signal started: std_logic := '0';
begin
   
    soc1: entity work.soc(structural)
        generic map("firmware.bin")
        port map(clock, started);

    estimulo: process is
        variable aux_valid : std_logic := '1';
    begin
        started <= '0';
        wait for 1 ns;
        for i in 0 to 20 loop
            clock <= not clock;
            wait for 5 ns;
        end loop;
        started <= '1';
        wait for 1 ns;
        for i in 0 to 20 loop
            clock <= not clock;
            wait for 5 ns;
        end loop;

    wait;
    end process estimulo;
    
end architecture;