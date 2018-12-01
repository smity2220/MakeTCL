library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity test_tb is
  
end entity;

architecture tb of test_tb is
  signal clk : std_logic;
begin

  uut: entity work.test
  generic map (
    clk_period => 2 ns             ) -- time := 4 ns);
  port map (
    clk        => clk              -- out std_logic 
  );

  process (all) is
  begin
    wait for 10 us;
    stop;
  end process;

end tb;