library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_memory is

end entity;

architecture mixed of tb_memory is
    constant addr_width: natural := 16;
    constant data_width: natural := 8;
    signal data_in: std_logic_vector(data_width-1 downto 0) := (others => '1');
    signal data_addr: std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal data_out :std_logic_vector((data_width*4)-1 downto 0);
    signal data_read: std_logic := '0';
    signal data_write: std_logic := '1';
    signal clk: std_logic := '0';
begin
   
    mem: entity work.memory(behavior)
        generic map(addr_width, data_width)
        port map(data_in => data_in, data_addr => data_addr, data_read => data_read, 
        data_write => data_write, data_out => data_out, clock => clk);
        

        

    estimulo: process is
        variable resultado : std_logic_vector((data_width*4)-1 downto 0) := (others => '1');
    begin
        
        --Escrita
        data_write <= '1';
        data_read <= '0';
        for i in 0 to (2**addr_width - 1) loop
            data_addr <= std_logic_vector(to_unsigned(i, addr_width));
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait until falling_edge(clk);
            wait for 1 ns;
        end loop;

        --Leitura
        data_write <= '0';
        data_read <= '1';
        for i in 0 to (2**addr_width - 4) loop
            data_addr <= std_logic_vector(to_unsigned(i, addr_width));
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait until falling_edge(clk);
            wait for 1 ns;
            assert data_out = resultado
            report "Erro!"
            severity failure;
        end loop;
    wait;
    end process estimulo;

end architecture;