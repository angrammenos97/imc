pulpissimo_fpga:
	@git clone repositories_db/pec_intergration.git	pec_intergration; \
	git clone repositories_db/pulpissimo.git 		pulpissimo_fpga -b 7.0.0; \
	git clone repositories_db/pec-ctrl.git 			pulpissimo_fpga/working_dir/pec-ctrl -b new_controller; \
	git clone repositories_db/pec-engine.git 		pulpissimo_fpga/working_dir/pec-engine; \
	git clone repositories_db/pulp_soc.git 			pulpissimo_fpga/working_dir/pulp_soc -b 3.0.0; \
	cd pulpissimo_fpga; \
	make bender; \
	./bender update; \
	make checkout

pulpissimo_devel:
	@git clone repositories_db/pec_intergration.git	pec_intergration; \
	git clone repositories_db/pulpissimo.git 		pulpissimo_devel; \
	git clone repositories_db/pec-ctrl.git 			pulpissimo_devel/working_dir/pec-ctrl -b new_controller; \
	git clone repositories_db/pec-engine.git 		pulpissimo_devel/working_dir/pec-engine; \
	git clone repositories_db/pulp_soc.git 			pulpissimo_devel/working_dir/pulp_soc; \
	cd pulpissimo_devel; \
	make bender; \
	./bender update; \
	make checkout

repositories:
	mkdir repositories
	git clone repositories_db/pec_intergration.git	repositories/pec_intergration
	git clone repositories_db/pec-ctrl.git 			repositories/pec-ctrl -b new_controller
	# git clone repositories_db/pec-engine.git 		repositories/pec-engine
	git clone repositories_db/pulp_soc.git 			repositories/pulp_soc
	git clone repositories_db/pulpissimo.git 		repositories/pulpissimo

download_env: download_compiler
	@git clone https://github.com/pulp-platform/pulp-runtime.git

download_compiler:
	@if [ -f /etc/os-release ]; then \
		if grep -q "CentOS Linux 7" /etc/os-release; then \
			wget https://github.com/pulp-platform/pulp-riscv-gnu-toolchain/releases/download/v1.0.16/v1.0.16-pulp-riscv-gcc-centos-7.tar.bz2; \
			mkdir pulp-riscv-gcc-v1.0.16; \
			tar -xvf v1.0.16-pulp-riscv-gcc-* --directory=pulp-riscv-gcc-v1.0.16 --strip-components=1; \
			rm v1.0.16-pulp-riscv-gcc-*; \
		elif grep -q "Ubuntu 16.04" /etc/os-release; then \
			wget https://github.com/pulp-platform/pulp-riscv-gnu-toolchain/releases/download/v1.0.16/v1.0.16-pulp-riscv-gcc-ubuntu-16.tar.bz2; \
			mkdir pulp-riscv-gcc-v1.0.16; \
			tar -xvf v1.0.16-pulp-riscv-gcc-* --directory=pulp-riscv-gcc-v1.0.16 --strip-components=1; \
			rm v1.0.16-pulp-riscv-gcc-*; \
		elif grep -q "Ubuntu 18.04" /etc/os-release; then \
			wget https://github.com/pulp-platform/pulp-riscv-gnu-toolchain/releases/download/v1.0.16/v1.0.16-pulp-riscv-gcc-ubuntu-18.tar.bz2; \
			mkdir pulp-riscv-gcc-v1.0.16; \
			tar -xvf v1.0.16-pulp-riscv-gcc-* --directory=pulp-riscv-gcc-v1.0.16 --strip-components=1; \
			rm v1.0.16-pulp-riscv-gcc-*; \
		else \
			echo "Unsupported Linux distribution, try to download and build from source"; \
		fi; \
	else \
		echo "Unable to detect the Linux distribution, try to download and build from source"; \
	fi

clean:
	@read -p "Are you sure? [y/N] " ans && ans=$${ans:-N} ; \
    if [ $${ans} = y ] || [ $${ans} = Y ]; then \
        echo "Cleaning workspace"; \
		rm -rf repositories pec_intergration pulpissimo_fpga pulpissimo_devel; \
    else \
        echo "Aborded" ; \
    fi

clean_all: clean
	@rm -rf pulp-runtime pulp-riscv-gcc-v1.0.16
	
help:
	@echo "Description: Setup workspace script."
	@echo
	@echo "pulpissimo_fpga:	Initilize workspace with pulpissimo v7.0.0 integrated with accelerator and fpga scripts."
	@echo "pulpissimo_devel:	Initilize workspace with more recent pulpissimo version integrated with accelerator."
	@echo "repositories:		Checkout all repositories to latest commit."
	@echo "download_env:		Donwload pulp-runtime and riscv gcc compiler.""
	@echo "clean:			Clean workspace."
	@echo
