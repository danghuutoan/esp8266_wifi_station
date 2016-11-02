XTENSA		?=
#please export your sdk and esptool before building the code
SDK_BASE	?= /home/toan/workspace/esp_8266_sdk/esp-open-sdk/ESP8266_NONOS_SDK_V2.0.0_16_08_10
ESPTOOL		?= /home/toan/workspace/esp_8266_sdk/esp-open-sdk/esptool/esptool.py
SDK_LIBS 	:= -lc -lgcc -lhal -lphy -lpp -lnet80211 -lwpa -lmain -llwip -lcrypto -ljson
CC			:= $(XTENSA)xtensa-lx106-elf-gcc
LD			:= $(XTENSA)xtensa-lx106-elf-gcc
AR			:= $(XTENSA)xtensa-lx106-elf-ar

LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static
CFLAGS 		+= -g -Wpointer-arith -Wundef -Wl,-EL -fno-inline-functions -nostdlib\
			  -mlongcalls -mtext-section-literals -ffunction-sections -fdata-sections\
			  -fno-builtin-printf -DICACHE_FLASH\
			  -I.
LD_SCRIPT	= -T$(SDK_BASE)/ld/eagle.app.v6.ld
SERIAL_PORT ?= /dev/ttyUSB0
BAUD		?= 921600

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
project_name=$(notdir $(current_dir))

OUTPUT=output
INCLUDE+=-I$(SDK_BASE)/include -I.
SRCS+= main.c

OBJS+=$(patsubst %.c,%.o,$(SRCS))
OBJECTS=$(addprefix $(OUTPUT)/, $(OBJS))

all: INIT_DIR $(OUTPUT)/$(project_name).bin
INIT_DIR:
	$(shell mkdir -p ${OUTPUT} 2>/dev/null)

$(OUTPUT)/$(project_name).bin: $(OUTPUT)/$(project_name).out
	$(ESPTOOL) elf2image $(ESPTOOL_FLASHDEF) $(OUTPUT)/$(project_name).out -o $(OUTPUT)/$(project_name)
	
$(OUTPUT)/$(project_name).out: $(OUTPUT)/$(project_name).a
	@echo "LD $@"
	$(LD) -L$(SDK_BASE)/lib $(LD_SCRIPT) $(LDFLAGS) -L$(SDK_BASE)/lib -Wl,--start-group $(SDK_LIBS) $(OUTPUT)/$(project_name).a -Wl,--end-group -o $(OUTPUT)/$(project_name).out

$(OUTPUT)/$(project_name).a: $(OBJECTS)
	@echo "AR $(OBJECTS)"
	$(AR) cru $(OUTPUT)/$(project_name).a $^


$(OUTPUT)/%.o:%.c
	mkdir -p $(@D)
	$(CC)  $(INCLUDE) $(CFLAGS) -c $< -o $@
	
clean:
	rm -rf $(OUTPUT)/*.o $(OUTPUT)/*.bin $(OUTPUT)/*.a $(OUTPUT)/*.out 
	
flash:
	$(ESPTOOL) --port $(SERIAL_PORT) \
			   --baud $(BAUD) \
			   write_flash --flash_freq 40m --flash_mode dio --flash_size 32m \
			   0x00000 $(OUTPUT)/$(project_name)0x00000.bin \
			   0x10000 $(OUTPUT)/$(project_name)0x10000.bin \
			   0x3fc000 $(SDK_BASE)/bin/esp_init_data_default.bin

.PHONY: all clean