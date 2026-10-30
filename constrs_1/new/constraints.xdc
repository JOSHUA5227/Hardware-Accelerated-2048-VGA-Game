# HDMI TMDS Clock
set_property -dict { PACKAGE_PIN L17 IOSTANDARD TMDS_33 } [get_ports { TMDS_CLK_N_0 }]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD TMDS_33 } [get_ports { TMDS_CLK_P_0 }]

# HDMI TMDS Data Channel 0
set_property -dict { PACKAGE_PIN K18 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_N_0[0] }]
set_property -dict { PACKAGE_PIN K17 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_P_0[0] }]

# HDMI TMDS Data Channel 1
set_property -dict { PACKAGE_PIN J19 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_N_0[1] }]
set_property -dict { PACKAGE_PIN K19 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_P_0[1] }]

# HDMI TMDS Data Channel 2
set_property -dict { PACKAGE_PIN H18 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_N_0[2] }]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD TMDS_33 } [get_ports { TMDS_DATA_P_0[2] }]

set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk_in1_0 }]; #IO_L13P_T2_MRCC_35 Sch=sysclk

set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { right_0 }]; #IO_L4P_T0_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { left_0 }]; #IO_L4N_T0_35 Sch=btn[1]
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { down_0 }]; #IO_L9N_T1_DQS_AD3N_35 Sch=btn[2]
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { up_0 }]; #IO_L9P_T1_DQS_AD3P_35 Sch=btn[3]

set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { soft_rst_0 }]; #IO_L7N_T1_AD2N_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { resetn_0 }]; #IO_L7P_T1_AD2P_35 Sch=sw[1]

