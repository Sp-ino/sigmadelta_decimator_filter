create_clock -name sys_clk -period 1.05 [get_db ports *clk]

# Define input delay
set_input_delay -clock clk 0.5 [get_db ports {input1 input2 input3}]

# Define output delay
set_output_delay -clock clk 0.5 [get_ports {output1 output2 output3}]

# Specify the maximum transition time
set_max_transition 0.2 [all_outputs]
