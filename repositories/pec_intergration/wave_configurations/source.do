add wave -noupdate -divider source_streamer
add wave -noupdate -group source_streamer  /tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_source_i/*
add wave -noupdate -group in_bit_stream /tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_source_i/i_in_bit_stream/*
add wave -noupdate -group {hwpe_tcdm[0]} {sim:/tb_pulp/i_dut/soc_domain_i/pulp_soc_i/i_pec_top/pec_streamer_top_i/pec_streamer_source_i/hwpe_tcdm[0]/*}