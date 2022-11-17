library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    generic (
        addr_width: natural := 16; -- Memory Address Width (in bits)
        data_width: natural := 8 -- Data Width (in bits)
    );
    port (
        clock: in std_logic; -- Clock signal
        halt : in std_logic; -- Halt processor execution when '1'
        ---- Begin Memory Signals ---
        -- Instruction byte received from memory
        instruction_in : in std_logic_vector(data_width-1 downto 0);
        -- Instruction address given to memory
        instruction_addr: out std_logic_vector(addr_width-1 downto 0);
        mem_data_read : out std_logic; -- When '1', read data from memory
        mem_data_write: out std_logic; -- When '1', write data to memory
        -- Data address given to memory
        mem_data_addr : out std_logic_vector(addr_width-1 downto 0);
        -- Data sent from memory when data_read = '1' and data_write = '0'
        mem_data_in : out std_logic_vector((data_width*2)-1 downto 0);
        -- Data sent to memory when data_read = '0' and data_write = '1'
        mem_data_out : in std_logic_vector((data_width*4)-1 downto 0);
        ---- End Memory Signals ---
        ---- Begin Codec Signals ---
        codec_interrupt: out std_logic; -- Interrupt signal
        codec_read: out std_logic; -- Read signal
        codec_write: out std_logic; -- Write signal
        codec_valid: in std_logic; -- Valid signal
        -- Byte written to codec
        codec_data_out : in std_logic_vector(7 downto 0);
        -- Byte read from codec
        codec_data_in : out std_logic_vector(7 downto 0)
        ---- End Codec Signals ---
        );
end entity;


architecture behavior of cpu is
    constant HLT: std_logic_vector(3 downto 0):= "0000";
    constant IN_O : std_logic_vector(3 downto 0):= "0001";
    constant OUT_O: std_logic_vector(3 downto 0):= "0010";
    constant PUSH_IP: std_logic_vector(3 downto 0):= "0011";
    constant PUSH_IMM: std_logic_vector(3 downto 0):= "0100";
    constant DROP: std_logic_vector(3 downto 0):= "0101";
    constant DUP: std_logic_vector(3 downto 0):= "0110";
    constant ADD: std_logic_vector(3 downto 0):= "1000";
    constant SUB: std_logic_vector(3 downto 0):= "1001";
    constant NAND_O: std_logic_vector(3 downto 0):= "1010";
    constant SLT: std_logic_vector(3 downto 0):= "1011";
    constant SHL: std_logic_vector(3 downto 0):= "1100";
    constant SHR: std_logic_vector(3 downto 0):= "1101";
    constant JEQ: std_logic_vector(3 downto 0):= "1110";
    constant JMP: std_logic_vector(3 downto 0):= "1111";

    signal op : std_logic_vector(3 downto 0) := "0000";
    signal IP :std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal SP :std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal data_operator : std_logic_vector((data_width*2)-1 downto 0);

    begin
    
    furia: process

        begin
        if halt = '0' then
            instruction_addr <= IP;
            wait for 5 ns;
            op <= instruction_in(7 downto 4);
            IP <= std_logic_vector(unsigned(IP) + 1);
            wait for 5 ns;
            report "Opcode: " & integer'image(to_integer(unsigned(op)));
            case op is
                when HLT =>
                    wait until falling_edge(halt);
                    IP <= "0000000000000000";
                    SP <= "0000000000000000";
                when IN_O =>
                    codec_read <= '1';
                    codec_write <= '0';
                    wait for 5 ns;
                    codec_interrupt <= '0';
                    wait for 5 ns;
                    codec_interrupt <= '1';
                    wait until codec_valid'event;
                    SP <= std_logic_vector(unsigned(SP) + 1);
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    mem_data_write <= '1';
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(to_unsigned(to_integer(unsigned(codec_data_out)), (data_width*2)));
                    wait for 5 ns;
                    mem_data_write <= '0';
                when OUT_O =>
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    mem_data_read <= '1';
                    wait for 5 ns;
                    mem_data_read <= '0';
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    codec_read <= '0';
                    wait for 5 ns;
                    codec_write <= '1';
                    wait for 5 ns;
                    codec_data_in <= mem_data_out(data_width*4 - 1 downto data_width*4 - 8);
                    wait for 5 ns;
                    codec_interrupt <= '0';
                    wait for 5 ns;
                    codec_interrupt <= '1';
                    wait until codec_valid'event;
                when PUSH_IP =>
                    SP <= std_logic_vector(unsigned(SP) + 1);
                    mem_data_write <= '1';
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(to_unsigned(to_integer(unsigned(IP(addr_width-1 downto addr_width/2))), (data_width*2)));
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) + 1);
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(to_unsigned(to_integer(unsigned(IP(addr_width/2 - 1 downto 0))), (data_width*2)));
                    wait for 5 ns;
                    mem_data_write <= '0';
                
                when PUSH_IMM =>
                    SP <= std_logic_vector(unsigned(SP) + 1);
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    report "SP: " & integer'image(to_integer(unsigned(SP)));
                    mem_data_write <= '1';
                    wait for 5 ns;
                    report "Push_IMM Numero: " & integer'image(to_integer(signed(instruction_in(data_width/2 - 1 downto 0))));
                    mem_data_in <= std_logic_vector(to_signed(to_integer(signed(instruction_in(data_width/2 - 1 downto 0))), (data_width*2)));
                    wait for 5 ns;
                    mem_data_write <= '0';
                    wait for 5 ns;


                when DROP =>
                    mem_data_write <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(to_unsigned(0, (data_width*2)));
                    report "Posição dropada: " & integer'image(to_integer(unsigned(SP)));
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    mem_data_write <= '0';
                when DUP =>
                    wait for 5 ns;
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(to_unsigned(to_integer(unsigned(mem_data_out(data_width*4-1 downto data_width*4-8))), (data_width*2)));
                    wait for 5 ns;
                    mem_data_write <= '0';

                when ADD => 
                    mem_data_read <= '1';
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    report "SP: " & integer'image(to_integer(unsigned(SP)));
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-16);
                    wait for 5 ns;

                    report "Add(Op1): " & integer'image(to_integer(signed(data_operator)));
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    
                    mem_data_in <= std_logic_vector(signed(mem_data_out(data_width*4-1 downto data_width*4-16)) + signed(data_operator));
                    report "Add(Op2): " & integer'image(to_integer(signed(mem_data_out(data_width*4-1 downto data_width*4-16))));
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    wait for 5 ns;
                    mem_data_write <= '0';

                when SUB =>
                    mem_data_read <= '1';
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    report "SP: " & integer'image(to_integer(signed(SP)));
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-16);
                    wait for 5 ns;

                    report "Sub(Op1): " & integer'image(to_integer(signed(data_operator)));
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                
                    mem_data_in <= std_logic_vector(signed(mem_data_out(data_width*4-1 downto data_width*4-16)) - signed(data_operator));
                    report "Sub(Op2): " & integer'image(to_integer(signed(mem_data_out(data_width*4-1 downto data_width*4-16))));
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    wait for 5 ns;
                    mem_data_write <= '0';

                when NAND_O =>
                    mem_data_addr <= SP;
                    mem_data_read <= '1';
                    report "Nand(Op1): ";
                    wait for 5 ns;
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-16);
                    wait for 5 ns;
                    report "Nand(Op1): " & integer'image(to_integer(signed(data_operator)));
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= data_operator nand mem_data_out(data_width*4-1 downto data_width*4-16);
                    wait for 5 ns;
                    report "Nand(Op2): " & integer'image(to_integer(signed(mem_data_out(data_width*4-1 downto data_width*4-16))));
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    mem_data_write <= '0';
                when SLT =>
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-8);
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    wait for 5 ns;
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    if signed(data_operator) < signed(mem_data_out(data_width*4-1 downto data_width*4-8)) then
                        mem_data_in <= std_logic_vector(to_unsigned(1, (data_width*2)));
                    else
                        mem_data_in <= std_logic_vector(to_unsigned(0, (data_width*2)));
                    end if;
                    mem_data_write <= '1';
                    wait for 5 ns;
                    mem_data_read <= '0';
                    mem_data_write <= '0';
                
                when SHL =>
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-8);
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(shift_left(signed(data_operator), to_integer(signed(mem_data_out(data_width*4-1 downto data_width*4-8)))));
                    wait for 5 ns;
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    mem_data_write <= '0';
                when SHR =>
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-8);
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_in <= std_logic_vector(shift_right(signed(data_operator), to_integer(signed(mem_data_out(data_width*4-1 downto data_width*4-8)))));
                    wait for 5 ns;
                    mem_data_write <= '1';
                    mem_data_read <= '0';
                    mem_data_write <= '0';
                when JEQ =>
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    data_operator <= mem_data_out(data_width*4-1 downto data_width*4-8);
                    wait for 5 ns;
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    if signed(data_operator) = signed(mem_data_out(data_width*4-1 downto data_width*4-8)) then
                        SP <= std_logic_vector(unsigned(SP) - 1);
                        IP <= std_logic_vector(signed(IP) + signed(mem_data_out(data_width*4-1 downto data_width*4/2)));
                        wait for 5 ns;
                    end if;
                    mem_data_read <= '0';
                
                when JMP =>
                    mem_data_read <= '1';
                    mem_data_addr <= SP;
                    wait for 5 ns;
                    mem_data_read <= '0';
                    wait for 5 ns;
                    IP <= mem_data_out(data_width*4-1 downto data_width*4/2);
                    SP <= std_logic_vector(unsigned(SP) - 1);
                    wait for 5 ns;
                when others => 
                    report "Opcode Desconhecido";
            end case;
        end if;
    wait until rising_edge(clock);
    end process;
end architecture;