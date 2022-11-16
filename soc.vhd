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
    constant flag: boolean := true;
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
    signal instruction_read: std_logic := '1';
    signal instruction_write: std_logic := '0';
    signal instruction_out: std_logic_vector((data_width*2)-1 downto 0) := (others => '0');
    signal endereco: std_logic_vector(15 downto 0) := (others => '0');


    begin
    
    start: process is
    file arq : text open read_mode is firmware_filename;
    variable text_line: line;
    variable auxiliar: bit_vector(7 downto 0);
    begin
        if started = '0' then
            instruction_write <= '1';
            halt <= '1';
            if falling_edge(clock) and not endfile(arq) then
                readline(arq,text_line);
                read(text_line,auxiliar);
                instruction_out(7 downto 0) <= std_logic_vector(unsigned(to_stdlogicvector(auxiliar)));
                instruction_out(15 downto 8) <= "00000000";
                instruction_addr <= endereco;
                endereco <= std_logic_vector(unsigned(endereco) + 1);
                wait for 5 ns;
                report integer'image(to_integer(unsigned(endereco)));
            end if;
        else
            halt <= '0';
            endereco <= instruction_addr;
        end if;
        wait on clock;
    end process;
    
    
        cpu1: entity work.cpu(behavior)
        generic map(addr_width, data_width)
        port map(halt => halt, instruction_in => instruction_in((data_width*4)-1 downto (data_width*4)-8), instruction_addr => instruction_addr, 
            mem_data_read => mem_data_read, mem_data_write => mem_data_write, mem_data_addr => mem_data_addr,
            mem_data_in => mem_data_in, mem_data_out => mem_data_out, codec_interrupt => codec_interrupt, codec_read => codec_read,
            codec_write => codec_write, codec_valid => codec_valid, codec_data_out => codec_data_out, codec_data_in => codec_data_in, clock => clock);

    dmem: entity work.memory(behavior)
    generic map(addr_width, data_width)
    port map(clock, mem_data_read, mem_data_write, mem_data_addr, mem_data_in, mem_data_out);

    imem: entity work.memory(behavior)
        generic map(addr_width, data_width)
        port map(clock, instruction_read, instruction_write, endereco, instruction_out, instruction_in);

    codec: entity work.codec(behavior)
        port map(codec_interrupt, codec_read, codec_write, codec_valid, codec_data_in, codec_data_out);


end architecture;