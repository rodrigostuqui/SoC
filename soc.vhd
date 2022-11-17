library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;

entity soc is
generic (
    firmware_filename: string := "firmware.bin"
);
port (
    clock: in std_logic; -- Clock signal
    started: in std_logic -- Start execution when '1'
);
end entity;

architecture structural of soc is
    constant addr_width: natural := 16;
    constant data_width: natural := 8;
    signal halt: std_logic := '1';
    signal instruction_in: std_logic_vector((data_width*4)-1 downto 0) := (others => '0');
    signal instruction_addr: std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal mem_data_read: std_logic := '0';
    signal mem_data_write: std_logic := '0';
    signal mem_data_addr: std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal mem_data_in : std_logic_vector((data_width*2)-1 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector((data_width*4)-1 downto 0) := (others => '0');
    signal codec_interrupt: std_logic := '0';
    signal codec_read: std_logic := '0';
    signal codec_write: std_logic := '0';
    signal codec_valid: std_logic := '0';
    signal codec_data_out : std_logic_vector(7 downto 0) := (others => '0');
    signal codec_data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal instruction_read: std_logic := '0';
    signal instruction_write: std_logic := '0';
    signal instruction_out: std_logic_vector((data_width*2)-1 downto 0) := (others => '0');
    signal endereco_inst: std_logic_vector(15 downto 0) := (others => '0');
    signal endereco1_inst: std_logic_vector(15 downto 0) := (others => '0');


    begin
    
    start: process is
    file arq : text open read_mode is firmware_filename;
    variable text_line: line;
    variable auxiliar: bit_vector(7 downto 0);
    begin
        if started = '0' and not endfile(arq) then
            halt <= '1';
            instruction_read <= '0';
            instruction_write <= '1';
            readline(arq,text_line);
            read(text_line,auxiliar);
            wait for 5 ns;
            instruction_out(15 downto 8) <= std_logic_vector(unsigned(to_stdlogicvector(auxiliar)));
            instruction_out(7 downto 0) <= "00000000";
            wait for 5 ns;
            instruction_write <= '0';
            if not endfile(arq) then
                endereco_inst <= std_logic_vector(unsigned(endereco_inst) + 1);
            end if;
        elsif started = '1' and endfile(arq) then
            if endereco_inst = endereco1_inst then
                halt <= '1';
            else 
                halt <= '0';
            end if;

            instruction_read <= '1';
            instruction_write <= '0';
            wait for 5 ns;
        end if;
        wait until falling_edge(clock);
    end process;
    
    mux_imem: entity work.mux2x1(behavioral)
        generic map(addr_width)
        port map(input0 => endereco_inst, input1 => endereco1_inst, sel => started, output => instruction_addr);
    
    cpu1: entity work.cpu(behavior)
    generic map(addr_width, data_width)
    port map(halt => halt, instruction_in => instruction_in((data_width*4)-1 downto (data_width*4)-8), instruction_addr => endereco1_inst, 
        mem_data_read => mem_data_read, mem_data_write => mem_data_write, mem_data_addr => mem_data_addr,
        mem_data_in => mem_data_in, mem_data_out => mem_data_out, codec_interrupt => codec_interrupt, codec_read => codec_read,
        codec_write => codec_write, codec_valid => codec_valid, codec_data_out => codec_data_out, codec_data_in => codec_data_in, clock => clock);

    dmem: entity work.memory(behavior)
        generic map(addr_width, data_width)
        port map(clock => clock, data_read => mem_data_read, data_write => mem_data_write,data_addr => mem_data_addr, data_in => mem_data_in, data_out => mem_data_out);
        
    imem: entity work.memory(behavior)
        generic map(addr_width, data_width)
        port map(clock => clock, data_read => instruction_read, data_write => instruction_write,data_addr => instruction_addr, data_in => instruction_out, data_out => instruction_in);

    codec: entity work.codec(behavior)
        port map(codec_interrupt, codec_read, codec_write, codec_valid, codec_data_in, codec_data_out);


end architecture;