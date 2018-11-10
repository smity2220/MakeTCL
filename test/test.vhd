library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity test is
  generic (
  	clk_period : time := 4 ns);
  port ( 
  	clk : out std_logic 
  );
end entity;

architecture behaviour of test is
begin
  -- Clock process definition
  clk_process: process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;
end behaviour;