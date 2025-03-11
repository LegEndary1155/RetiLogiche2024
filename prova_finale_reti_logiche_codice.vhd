-- --------------------------------------------------
-- -------------------DATAPATH-----------------------
-- --------------------------------------------------
-- 
-- Prova Finale: Progetto Di Reti Logiche (A.A. 2023 - 2024)
-- Prof. Gianluca Palermo
--
-- Matteo Sabino
-- --------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity datapath is
port(
    i_clk : in  std_logic;
    i_rst : in  std_logic;
    -- (non serve nel datapath) i_start : in  std_logic;
    i_add : in  std_logic_vector(15 downto 0);
    i_k : in  std_logic_vector(9 downto 0);
    
    is_starting_k_zero : out std_logic;
    is_k_zero : out std_logic;
    
    o_mem_addr : out  std_logic_vector(15 downto 0);
    i_mem_data : in  std_logic_vector(7 downto 0);
    o_mem_data : out  std_logic_vector(7 downto 0);
    -- (non serve nel datapath) o_mem_we : out  std_logic; -- se '1' allora è abilitata la scrittura in memoria
    -- (non serve nel datapath) o_mem_en : out std_logic; -- se '1' allora è abilitato l'accesso alla memoria
    
    -- segnali miei
    r1_load : in STD_LOGIC;
    r2_load : in STD_LOGIC;
    r3_load : in STD_LOGIC;
    r4_load : in STD_LOGIC;
    r1_sel : in STD_LOGIC;
    r2_sel : in STD_LOGIC;
    r3_sel : in STD_LOGIC;
    mux_starting_credibility : in STD_LOGIC;
    mux_addr : in STD_LOGIC;
    mux_data_credibility : in STD_LOGIC;
    
    is_data_zero : out STD_LOGIC;
    is_credibility_zero : out STD_LOGIC
    
);
end datapath;

architecture Behavioral of datapath is

-- segnali
signal o_reg1 : STD_LOGIC_VECTOR(15 downto 0);
signal o_reg2 : STD_LOGIC_VECTOR(9 downto 0);
signal o_reg3 : STD_LOGIC_VECTOR(7 downto 0);
signal o_reg4 : STD_LOGIC_VECTOR(7 downto 0);

signal mux_reg1 : STD_LOGIC_VECTOR(15 downto 0);
signal mux_reg2 : STD_LOGIC_VECTOR(9 downto 0);
signal mux_reg3 : STD_LOGIC_VECTOR(7 downto 0);
signal o_mux_starting_credibility : STD_LOGIC_VECTOR(7 downto 0);
signal mux_data_out : STD_LOGIC_VECTOR(7 downto 0);

signal mux_addr_exit : STD_LOGIC_VECTOR(15 downto 0);

signal next_address : STD_LOGIC_VECTOR(15 downto 0);

signal words_left : STD_LOGIC_VECTOR(9 downto 0);

signal remaining_credibility : STD_LOGIC_VECTOR(7 downto 0);

-- costanti
constant max_credibility : STD_LOGIC_VECTOR(7 downto 0) := (4 downto 0 => '1', others => '0');  -- costante con credibility massima uguale a 31 (in binario "00011111")
constant zero_credibility : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');                    -- costante con credibility nulla "00000000"

-- inizio dell'architecture
begin
    -- registro di memoria 1
    process(i_clk, i_rst)
        begin
            if(i_rst = '1') then
                o_reg1 <= "0000000000000000";
            elsif i_clk'event and i_clk = '1' then
                if(r1_load = '1') then
                    o_reg1 <= mux_reg1; -- carico dal mux 1 il valore
                end if;
            end if;
        end process;

    -- calcolo l'indirizzo successivo a quello di dove mi trovo
    next_address <= STD_LOGIC_VECTOR(SIGNED(o_reg1) + "0000000000000001"); -- incremento di 1 byte quindi 8 bit
    
    -- mux registro 1
    with r1_sel select
        mux_reg1 <= i_add when '0',
                    next_address when '1', -- il prossimo indirizzo di memoria che voglio
                    "XXXXXXXXXXXXXXXX" when others;
                    
    -- mux_addr
    with mux_addr select
        mux_addr_exit <= o_reg1 when '0',
                         next_address when '1',
                         "XXXXXXXXXXXXXXXX" when others;
                         
    -- in uscita posso mandare sia lo stesso indirizzo letto o quello incrementato
    o_mem_addr <= mux_addr_exit;
       
    -- registro di memoria 2
    process(i_clk, i_rst)
        begin
            if(i_rst = '1') then
                o_reg2 <= "0000000000";
            elsif i_clk'event and i_clk = '1' then
                if(r2_load = '1') then
                    o_reg2 <= mux_reg2; -- carico dal mux 2 il valore
                end if;
            end if;
        end process;
    
    -- calcolo di quante word vanno controllate ancora
    words_left <= STD_LOGIC_VECTOR(SIGNED(o_reg2) - 1);
    
    -- mux registro 2
    with r2_sel select
        mux_reg2 <= i_k when '0',
                    words_left when '1',
                    "XXXXXXXXXX" when others;
                    
    -- alzo l'uscita quando non ci sono più word
    is_k_zero <= '1' when (o_reg2 = "0000000000") else '0';
    
    is_starting_k_zero <= '1' when (i_k = "0000000000") else '0';
    
    -- registro di memoria 3
    process(i_clk, i_rst)
        begin
            if(i_rst = '1') then
                o_reg3 <= "00000000";
            elsif i_clk'event and i_clk = '1' then
                if(r3_load = '1') then
                    o_reg3 <= mux_reg3; -- carico dal mux 3 il valore
                end if;
            end if;
        end process;
        
    -- mux_starting_credibility
    with mux_starting_credibility select
        o_mux_starting_credibility <= zero_credibility when '0',
                                      max_credibility when '1',
                                      "XXXXXXXX" when others;

    -- mux registro 3
    with r3_sel select
        mux_reg3 <= o_mux_starting_credibility when '0', -- asserisco 31 all'interno di reg3
                    remaining_credibility when '1', 
                    "XXXXXXXX" when others;
                    
    -- calcolo il valore della credibility rimanente    
    remaining_credibility <= STD_LOGIC_VECTOR(SIGNED(o_reg3) - "00000001");
    
    -- segnale che indica se la credibilità è nulla
    is_credibility_zero <= '1' when (o_reg3 = "00000000") else '0';
    
    -- registro di memoria 4
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            o_reg4 <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            if(r4_load = '1') then
                o_reg4 <= i_mem_data;
            end if;
        end if;
    end process;
    
    -- controllo se il valore ricevuto dalla memoria è zero
    is_data_zero <= '1' when (i_mem_data = "00000000") else '0';
    
    -- mux_data_credibility
    with mux_data_credibility select
        mux_data_out <= o_reg4 when '0',
                     o_reg3 when '1',
                    "XXXXXXXX" when others;
    
    o_mem_data <= mux_data_out;
    
end Behavioral;



-- --------------------------------------------------
-- ------------------FSA-----------------------------
-- --------------------------------------------------
-- 
-- Prova Finale: Progetto Di Reti Logiche (A.A. 2023 - 2024)
-- Prof. Gianluca Palermo
--
-- Matteo Sabino
-- --------------------------------------------------

-- librerie
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- --------------------------------------------------
-- note: - 
--       - macchina di Moore
--       - Ricontrollare nome dell'architecture
--------------------------------------------------

-- entity
entity project_reti_logiche is
    port (
        i_clk : in  std_logic;
        i_rst : in  std_logic;
        i_start : in  std_logic;
        i_add : in  std_logic_vector(15 downto 0);
        i_k : in  std_logic_vector(9 downto 0);
    
        o_done : out std_logic;
    
        o_mem_addr : out  std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out  std_logic_vector(7 downto 0);
        o_mem_we : out  std_logic; -- se '1' allora è abilitata la scrittura in memoria
        o_mem_en : out std_logic -- se '1' allora è abilitato l'accesso alla memoria
    );
end project_reti_logiche;

-- architecture
architecture Behavioral of project_reti_logiche is

component datapath is
port(
    i_clk : in  std_logic;
    i_rst : in  std_logic;

    i_add : in  std_logic_vector(15 downto 0);
    i_k : in  std_logic_vector(9 downto 0);
    
    is_starting_k_zero : out std_logic;
    is_k_zero : out std_logic;
    
    o_mem_addr : out  std_logic_vector(15 downto 0);
    i_mem_data : in  std_logic_vector(7 downto 0);
    o_mem_data : out  std_logic_vector(7 downto 0);
    -- (non serve nel datapath) o_mem_we : out  std_logic; -- se '1' allora è abilitata la scrittura in memoria
    -- (non serve nel datapath) o_mem_en : out std_logic; -- se '1' allora è abilitato l'accesso alla memoria
    
    -- segnali miei
    r1_load : in STD_LOGIC;
    r2_load : in STD_LOGIC;
    r3_load : in STD_LOGIC;
    r4_load : in STD_LOGIC;
    r1_sel : in STD_LOGIC;
    r2_sel : in STD_LOGIC;
    r3_sel : in STD_LOGIC;
    mux_starting_credibility : in STD_LOGIC;
    mux_addr : in STD_LOGIC;
    mux_data_credibility : in STD_LOGIC;
        
    is_data_zero : out STD_LOGIC;
    is_credibility_zero : out STD_LOGIC
);
end component;

-- segnali del datapath
signal r1_load : STD_LOGIC;
signal r2_load : STD_LOGIC;
signal r3_load : STD_LOGIC;
signal r4_load : STD_LOGIC;
signal r1_sel : STD_LOGIC;
signal r2_sel : STD_LOGIC;
signal r3_sel : STD_LOGIC;
signal mux_starting_credibility : STD_LOGIC;
signal mux_addr : STD_LOGIC;
signal mux_data_credibility : STD_LOGIC;

signal is_starting_k_zero : STD_LOGIC;
signal is_k_zero : STD_LOGIC;
    
signal is_data_zero : STD_LOGIC;
signal is_credibility_zero : STD_LOGIC;


-- Segnali dell'architecture
type S is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12); --numero stati della macchina
signal cur_state, next_state : S;

-- inizio dell'architecture
begin
-- Adesso iniziano le istruzioni concorrenti all'interno del modulo hardware

-- non utilizzo l'assegnamento posizionale (anche il tool sconsiglia di usarlo)
DATAPATH0: datapath port map(
    
    i_clk => i_clk,
    i_rst => i_rst,
    i_add => i_add,
    i_k => i_k,

    is_starting_k_zero => is_starting_k_zero,
    is_k_zero => is_k_zero, -- non assegno al segnale is_k_zero al segnale o_done del datapath perché quando finisce deve fare un passaggio di stato prima di terminare
    
    o_mem_addr => o_mem_addr,
    i_mem_data => i_mem_data,
    o_mem_data => o_mem_data,
    
    r1_load => r1_load,
    r2_load => r2_load,
    r3_load => r3_load,
    r4_load => r4_load,
    r1_sel => r1_sel,
    r2_sel => r2_sel,
    r3_sel => r3_sel,
    mux_starting_credibility => mux_starting_credibility,
    mux_addr => mux_addr,
    mux_data_credibility => mux_data_credibility,
    
    is_data_zero => is_data_zero,
    is_credibility_zero => is_credibility_zero
    );

    -- Process che mi fa passare da uno stato all'altro ad ogni ciclo di clock
    process(i_clk, i_rst)
    begin
        -- reset asincrono
        if(i_rst = '1') then -- attivo alto 
            cur_state <= S0;
        elsif i_clk'event and i_clk = '1' then
            cur_state <= next_state;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- logica combinatoria macchiana a stati

    -- DELTA: funzione delta per il passaggio da uno stato all'altro
    process (cur_state, i_start, i_rst, is_data_zero, is_starting_k_zero, is_k_zero, i_mem_data, is_credibility_zero) -- sensibility list(deve includere tutti gli ingressi della macchiana a stati)
    begin
        -- asserisco un valore di default a ogni uscita
        next_state <= cur_state;
        case cur_state is
            when S0 =>
                
                if i_start = '1' and i_rst = '0' then
                    next_state <= S1;   -- transizione al prossimo stato solo se è stato fornito il segnale di start
                end if;
                
            when S1 =>
                
                if is_starting_k_zero = '1' then -- se i_k è fornito subito a 0 vado nello stato S2
                    next_state <= S2;
                else
                    next_state <= S3;   -- se i_k è diverso da 0 procedo con l'elaborazione
                end if;
            
            when S2 =>
            
                if i_start = '0' then
                    next_state <= S0;   -- se i_start è 0 torno nello stato S0
                end if;
                
            when S3 =>
            
                next_state <= S4;
                
            when S4 =>
            
                if is_data_zero = '1' then
                    next_state <= S5;
                else
                    next_state <= S8;
                end if;
                
            when S5 =>
            
                next_state <= S6;
                
            when S6 =>
            
                next_state <= S7;
                
            when S7 =>
            
                if is_k_zero = '1' then
                    next_state <= S2;   -- se i_k è 0 ho terminato l'elaborazione
                else
                    next_state <= S9;   -- se i_k è diverso da 0 continuo l'elaborazione
                end if;
                
            when S8 =>                     
                
                next_state <= S6;
                
            when S9 =>
                
                next_state <= S10;
                
            when S10 =>
            
                if is_data_zero = '0' then
                    next_state <= S4;
                else -- if is_data_zero = '1'
                    if is_credibility_zero = '0' then
                        next_state <= S11;  -- se la credibilità rimanente non è nulla la decremento al prossimo stato
                    else
                        next_state <= S12;  -- se la credebilità rimanente è nulla non decremento ulteriormente
                    end if;
                
                end if;
                
            when S11 =>
                
                next_state <= S12;
                
            when S12 =>
            
                next_state <= S5;                
            
            when others =>
                -- next_state <= S0; -- REMOVE!
        end case;
    end process;
    
    -- LAMBDA: funzione lambda per determinare i segnali in uscita
    process(cur_state) -- dato che ho realizzato una macchina di Moore la funzione di uscita dipende solo dallo stato presente
    begin
        
        -- Assegno il valore dei segnali a un valore di default (così da non inferire latch in caso dovessi dimenticarmi un assegnamento per ogni casistica)
        r1_load <= '0';
        r2_load <= '0';
        r3_load <= '0';
        r4_load <= '0';

        r1_sel <= '0';
        r2_sel <= '0';
        r3_sel <= '0';
        
        mux_starting_credibility <= '0';
        mux_addr <= '0';
        mux_data_credibility <= '0';
        
        o_mem_we <= '0';
        o_mem_en <= '0';
    
        o_done <= '0';
        
        -- assegnamenti in base allo stato
        case cur_state is
            when S0 =>      -- resetto tutti i segnali (tutti a 0 per default)
            
            when S1 =>
                
                r1_sel <= '0';                      -- salvo i_add in reg1
                r1_load <= '1';                     -- salvo i_add in reg1
                
                r2_sel <= '0';                      -- salvo i_k in reg2
                r2_load <= '1';                     -- salvo i_k in reg2
                
                r4_load <= '0';                     -- non leggo dalla memoria perché non so dove punta e a cosa
                
                --- 
                
                mux_starting_credibility <= '0';    -- carico zero_credibility 
                r3_sel <= '0';                      -- carico zero_credibility
                r3_load <= '1';                     -- salvo zero_credibility in reg3
                                

            when S2 =>
            
                o_done <= '1';
            
            when S3 =>
            
                mux_addr <= '0';                    -- accedo all'indirizzo di memoria che mi ero salvato
                o_mem_en <= '1';                    -- accedo all'indirizzo di memoria
                o_mem_we <= '0';                    -- accedo in lettura all'indirizzo di memoria
            
            when S4 =>
            
                r4_load <= '1';                     -- salvo il valore nel registro (potrebbero essere tutti 0 oppure un numero)
                
            when S5 =>
                               
                r1_sel <= '1';                      -- salvo il prossimo indirizzo
                r1_load <= '1';                     -- salvo il prossimo indirizzo            
                    
            when S6 =>
            
                mux_addr <= '0';                    -- accedo all'indirizzo di memoria
                o_mem_en <= '1';                    -- richiedo l'accesso
                o_mem_we <= '1';                    -- in scrittura
                                        
                mux_data_credibility <= '1';        -- scrivo il valore di credibilità salvato in reg3 (tutti 0 in questo caso)
                                        
                r2_sel <= '1';                      -- decremento i_k
                r2_load <= '1';                     -- decremento i_k
                
            when S7 =>                          
                
                r1_sel <= '1';                      -- salvo il prossimo indirizzo
                r1_load <= '1';                     -- salvo il prossimo indirizzo
                
            when S8 =>
                
                mux_starting_credibility <= '1';    -- carico max_credibility
                r3_sel <= '0';                      -- carico max_credibility
                r3_load <= '1';                     -- carico max_credibility
                
                r1_sel <= '1';                      -- salvo il prossimo indirizzo
                r1_load <= '1';                     -- salvo il prossimo indirizzo
                            
            when S9 =>
                
                mux_addr <= '0';                    -- accedo all'indirizzo di memoria che mi ero salvato
                o_mem_en <= '1';                    -- accedo all'indirizzo di memoria
                o_mem_we <= '0';                    -- accedo in lettura all'indirizzo di memoria
                
            when S10 =>
                
                
                
            when S11 =>
            
                r3_sel <= '1';                      -- decremento la credibilità
                r3_load <= '1';                     -- decremento la credibilità
                                        
                mux_data_credibility <= '0';
                        
                
            when S12 =>
            
                mux_addr <= '0';                    -- accedo all'indirizzo corrente
                o_mem_en <= '1';                    -- accedo all'indirizzo corrente
                o_mem_we <= '1';                    -- accedo in scrittura all'indirizzo corrente
                mux_data_credibility <= '0';        -- scrivo nell'indirizzo corrente il valore salvato precedentemente in memoria
                
            when others =>
        end case;
        
    end process;

end Behavioral;
