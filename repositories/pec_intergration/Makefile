ifdef EXAMPLE
PULP_APP = example
PULP_APP_FC_SRCS = src/example.c
PULP_APP_HOST_SRCS = src/example.c

else
PULP_APP = main
PULP_APP_FC_SRCS = src/main.c 
PULP_APP_HOST_SRCS = src/main.c

endif

PULP_APP_FC_SRCS   += src/pec_driver.c src/layers_util.c
PULP_APP_HOST_SRCS += src/pec_driver.c src/layers_util.c
PULP_CFLAGS = -Og -g -I./include

include $(PULP_SDK_HOME)/install/rules/pulp_rt.mk