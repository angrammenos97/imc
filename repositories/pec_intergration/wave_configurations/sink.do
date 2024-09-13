add wave -noupdate -divider sink_streamer
add wave -noupdate -group sink_streamer /tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_sink_i/*
add wave -noupdate -group pixel_stream /tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_sink_i/i_pixel_stream/*
add wave -noupdate -group {hwpe_tcdm[1]} {sim:/tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_sink_i/hwpe_tcdm[0]/*}