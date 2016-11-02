#include "ets_sys.h"
#include "os_type.h"
#include "osapi.h"
#include "mem.h"
#include "user_interface.h"
#define PASSWORD	"yourpassword"
#define SSID		"yourssid"
LOCAL os_timer_t test_timer;
	
/******************************************************************************
	* FunctionName : user_esp_platform_check_ip
	* Description	 : check whether get ip addr or not
	* Parameters		 : none
	* Returns		 : none
*******************************************************************************/
void ICACHE_FLASH_ATTR
user_esp_platform_check_ip(void)
{
	struct ip_info ipconfig;
	
	//disarm timer first
	os_timer_disarm(&test_timer);
	
	//get ip info of ESP8266 station
	wifi_get_ip_info(STATION_IF, &ipconfig);
	
	if (wifi_station_get_connect_status() == STATION_GOT_IP && ipconfig.ip.addr != 0) {
	
			os_printf("got ip !!! \r\n");
	
	} else {
		
		if ((wifi_station_get_connect_status() == STATION_WRONG_PASSWORD ||
				wifi_station_get_connect_status() == STATION_NO_AP_FOUND ||
				wifi_station_get_connect_status() == STATION_CONNECT_FAIL)) {
					
			os_printf("connect fail !!! \r\n");
				
		} else {
			
			//re-arm timer to check ip
			os_timer_setfn(&test_timer, (os_timer_func_t *)user_esp_platform_check_ip, NULL);
			os_timer_arm(&test_timer, 100, 0);
		}
	}
}
	
	
/******************************************************************************
	* FunctionName : user_set_station_config
	* Description	 : set the router info which ESP8266 station will connect to 
	* Parameters		 : none
	* Returns		 : none
*******************************************************************************/
void ICACHE_FLASH_ATTR
user_set_station_config(void)
{
	// Wifi configuration 
	char ssid[32] = SSID; 
	char password[64] = PASSWORD; 
	struct station_config stationConf; 
	
	os_memset(stationConf.ssid, 0, 32);
	os_memset(stationConf.password, 0, 64);
	//need not mac address
	stationConf.bssid_set = 0; 

	//Set ap settings 
	os_memcpy(&stationConf.ssid, ssid, 32); 
	os_memcpy(&stationConf.password, password, 64); 
	wifi_station_set_config(&stationConf);

	//set a timer to check whether got ip from router succeed or not.
	os_timer_disarm(&test_timer);
	os_timer_setfn(&test_timer, (os_timer_func_t *)user_esp_platform_check_ip, NULL);
	os_timer_arm(&test_timer, 100, 0);
}

/******************************************************************************
	* FunctionName : user_init
	* Description	 : entry of user application, init user function here
	* Parameters		 : none
	* Returns		 : none
*******************************************************************************/
void user_init(void)
{
	uart_div_modify(0, UART_CLK_FREQ / 115200);
	os_printf("SDK version:%s\n", system_get_sdk_version());
	//Set softAP + station mode 
	wifi_set_opmode(STATIONAP_MODE); 
	// ESP8266 connect to router.
	user_set_station_config();
}

