####################################################################################################
#
#  Rules to generate config files and update ldr-address for krn/sigma0/alpha.
#
####################################################################################################

makefiles = Makefile $(wildcard mk/*.mk)

$(blddir)/config/sys-config.h:  $(cfg_file) $(makefiles)
	@mkdir -p $(blddir)/config
	@echo -e "/* Generated by mk/syscfg.mk. Don't edit me. */"    > $@
	@echo -e ""                                                  >> $@
	@echo -e "#ifndef SYS_CONFIG_H"                              >> $@
	@echo -e "#define SYS_CONFIG_H"                              >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#define Cfg_arch $(arch)"                          >> $@
	@echo -e "#define Cfg_arch_$(arch)"                          >> $@
	@echo -e "#define Cfg_cpu $(cpu)"                            >> $@
	@echo -e "#define Cfg_cpu_$(cpu)"                            >> $@
	@echo -e "#define Cfg_plat $(plat)"                          >> $@
	@echo -e "#define Cfg_plat_$(plat)"                          >> $@
	@echo -e "#define Cfg_brd $(brd)"                            >> $@
	@echo -e "#define Cfg_brd_$(brd)"                            >> $@
	@echo -e "#define Cfg_sys_clock_hz $(sys_clock_hz)"          >> $@
	@echo -e "#define Cfg_ram_start $(ram_start)"                >> $@
	@echo -e "#define Cfg_ram_sz $(ram_sz)"                      >> $@
	@echo -e "#define Cfg_page_sz  $(page_sz)"                   >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#endif // SYS_CONFIG_H"                            >> $@

# uart vaddr for temporary rude mapping, use at initial startup code
# сhoose an address upper kernel + 16 MB and aligned to 2 MB
kuart_va = (((Cfg_krn_vaddr + 0x1000000) & 0xffffffffffe00000) + (Cfg_krn_uart_paddr & 0xfffff))

$(blddir)/config/krn-config.h:  $(cfg_file) $(makefiles)
	@mkdir -p $(blddir)/config
	@echo -e "/* Generated by mk/syscfg.mk. Don't edit me. */"    > $@
	@echo -e ""                                                  >> $@
	@echo -e "#ifndef KRN_CONFIG_H"                              >> $@
	@echo -e "#define KRN_CONFIG_H"                              >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#include \"sys-config.h\""                         >> $@
	@echo -e ""                                                  >> $@
	@echo -e "/* kernel settings */"                             >> $@
	@echo -e "#define Cfg_krn_vaddr $(krn_vaddr)"                >> $@
	@echo -e "#define Cfg_krn_tick_usec $(krn_tick_usec)"        >> $@
	@echo -e "#define Cfg_krn_uart_paddr $(krn_uart_paddr)"      >> $@
	@echo -e "#define Cfg_krn_uart_vaddr ($(kuart_va))"          >> $@
	@echo -e "#define Cfg_krn_uart_sz $(krn_uart_sz)"            >> $@
	@echo -e "#define Cfg_krn_uart_bitrate $(krn_uart_bitrate)"  >> $@
	@echo -e "#define Cfg_krn_uart_irq $(krn_uart_irq)"          >> $@
	@echo -e "#define Cfg_krn_intc_paddr $(krn_intc_paddr)"      >> $@
	@echo -e "#define Cfg_krn_intc_sz $(krn_intc_sz)"            >> $@
	@echo -e "#define Cfg_krn_timer_paddr $(krn_timer_paddr)"    >> $@
	@echo -e "#define Cfg_krn_timer_sz $(krn_timer_sz)"          >> $@
	@echo -e "#define Cfg_krn_timer_irq $(krn_timer_irq)"        >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#endif // KER_CONFIG_H"                            >> $@

$(blddir)/config/ldr-config.h:  $(cfg_file) $(makefiles)
	@mkdir -p $(blddir)/config
	@echo -e "/* Generated by mk/syscfg.mk. Don't edit me. */"    > $@
	@echo -e ""                                                  >> $@
	@echo -e "#ifndef LDR_CONFIG_H"                              >> $@
	@echo -e "#define LDR_CONFIG_H"                              >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#include \"sys-config.h\""                         >> $@
	@echo -e ""                                                  >> $@
	@echo -e "/* loader settings */"                             >> $@
	@echo -e "#define Cfg_ldr_uart_paddr $(ldr_uart_paddr)"      >> $@
	@echo -e "#define Cfg_ldr_uart_bitrate $(ldr_uart_bitrate)"  >> $@
	@echo -e ""                                                  >> $@
	@echo -e "#endif // LDR_CONFIG_H"                            >> $@

$(blddir)/config/next-load-addr.h:  $(cfg_file) $(makefiles)
	@mkdir -p $(blddir)/config
	@echo -e "/* Generated by mk/syscfg.mk. Don't edit me. */"    > $@
	@echo -e ""                                                  >> $@
	@echo -e "/* load address for next module */"                >> $@
	@echo -e "#define Cfg_load_addr $(ram_start)"                >> $@

# update Cfg_load_addr value in next-load-addr.h
# $(blddir)/$(target) - path to elf file
# $(cfgdir) - dir with next-load-addr.h
update-next-load-addr:
	@file=$(cfgdir)/next-load-addr.h; \
	if [ ! -f "$$file" ]; then \
		echo -e "ERROR:  no such file:  '$$file'.\n"; \
		exit -1; \
	fi; \
	elf=$(blddir)/$(target); \
	if [ ! -f "$$elf" ]; then \
		echo -e "ERROR:  no such file:  '$$elf'.\n"; \
		exit -1; \
	fi; \
	str=$$(readelf -lW $$elf | grep LOAD | tail -n1); \
	arr=($$str); \
	paddr=$${arr[3]}; \
	memsz=$${arr[5]}; \
	new_val=$$(printf "0x%x\n" $$(($$paddr + $$memsz))); \
	new_val=$$(printf "0x%x\n" $$((($$new_val + 0xfff) & ~0xfff))); \
	\
	str=$$(tail -n1 $$file); \
	arr=($$str); \
	old_val=$${arr[2]};\
	\
	sed -i -e '$$d' $$file; \
	echo "/* #define Cfg_load_addr $$old_val --> used by $$elf */" >> $$file; \
	echo "#define Cfg_load_addr $$new_val" >> $$file;

