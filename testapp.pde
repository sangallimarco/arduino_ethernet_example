#include <SdFat.h>
#include <SdFatUtil.h>
#include <SPI.h>
#include <Ethernet.h>


//############################################################
//############################################################
//############################################################
int DRONE_ID=250;
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, DRONE_ID };
byte ip[] = { 192, 168, 0, DRONE_ID };
byte gateway[] = { 192,168,0,1 };
byte subnet[] = { 255, 255, 255, 0 };
Server server(23);
//init SD
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;
//############################################################
//############################################################
//############################################################


//tag len
const int code_len=15;
int i=0;
//tcp max msg len
const int msg_len=8;
//init
char code[code_len];
bool initEth = true;

const int lockwait=200;

//sd
char name[] = "APPEND.TXT";

//------------------------------------------------
void delayLoop(int w){
	for(int i=0;i<w;i++){
		delay(1000);
	}
}

int relay_on(int id){
	/*
	
	*/

}
int relay_off(int id){
	/*
	
	*/

}

//-------------------------------------------------
void readCommand(Client conn){
	char val;
	//check first char
	val=conn.read();
	
	//CMD
	if(val=='#'){
		int cnt=0;
		//clean buffer
		char msg[msg_len];
		for(int i=0;i<msg_len;i++){
			msg[i]=' ';
		}
		//check end of line
		while(cnt<msg_len){
			if(conn.available()>0){
				val=conn.read();
				if(val=='\n' || val=='\r'){
					break;
				}
				msg[cnt]=val;
				cnt++;
			}
		}
		//save message to SD
		file.print(msg);
		file.print("\n");
		
		//parse
		char val=msg[0];
		//
		bool found=true;
		
		//open DX
		if(val=='>'){
			relay_on(1);
			delay(lockwait);
			relay_off(1);
		//open SX
		}else if(val=='<'){
			relay_on(2);
			delay(lockwait);
			relay_off(2);
		//alarm
		}else if(val=='A'){
			relay_on(3);
		//reset alarm
		}else if(val=='R'){
			relay_off(3);
		//do nothing
		}else{
			found=false;
		}
		//return to server
		conn.print("@");
		conn.print(val);
		conn.print("[");
		char buff[3];
		conn.print(itoa(DRONE_ID,buff,10));
		conn.print("]");
		if(found){
			conn.print(":OK\n");
		}else{
			conn.print(":ERROR\n");
		}
	//PING
	}else if(val=='*'){
		conn.print("*\n");
	}
}
void flushSerial(){
	while (Serial.available() > 0) {
		Serial.read(); 
	}
}
//------------------------------------------------
bool getTag(){
	int val;
	int cnt=0;
	//int cntf=3;
	
	//clean buffer
	for(int i=0;i<code_len;i++){
		code[i]=' ';
	}
	
	// check for header
	if(Serial.available()>0){
		val = Serial.read();
		if(val==2){
			while(cnt<code_len){
				if(Serial.available()>0){
					//read even if a valid code found
					val = Serial.read();
					if(code[cnt-2]==13 && code[cnt-1]==10 && val==3 ){
						code[cnt] =val;
						return true;
					}else{
						//add to buffer
						code[cnt] = val;
					}
					cnt++;
				}
			}
			return false;
		}
	}
	return false;
}

//------------------------------------------------
void setup() {	
	//ethernet 
	Ethernet.begin(mac, ip, gateway, subnet);
	server.begin();
	
	//serial speed
	Serial.begin(9600);
	
	//reset relay statusb
	for(i=0;i<8;i++){
		relay_off(i);
	}

	//SD
	pinMode(10,OUTPUT);
	digitalWrite(10,HIGH);
	uint8_t r = card.init(SPI_HALF_SPEED, 4);
	volume.init(&card);
	root.openRoot(&volume);
	
	//file.open(&root, name, O_CREAT | O_APPEND | O_WRITE);
		
}

//------------------------------------------------
void loop() {
 	initEth = true;
	Client client = server.available();
	if (client) {
		//client.print("READY\n");
		
		//open file
		file.open(&root, name, O_CREAT | O_APPEND | O_WRITE);
		//if client connected
		while (client.connected()) {
			if(initEth){
				//send alive 
				client.print("READY\n");
				initEth=false;
			}
			//remove data
			//flushSerial();
			//reader
						/*
			if(getTag()){
				//STOP READING WAIT FOR SERVER REPLY
				
				//send code back
				client.print("@T[");
				char buff[3];
				client.print(itoa(DRONE_ID,buff,10));
				client.print("]:");
				//
				for(i=0;i<code_len-3;i++){
					client.print(code[i]);
				}
				//
				client.print("\n");

			}
						*/

			//read reply if data available 
			if (client.available()) {
				//get reply
				readCommand(client);
				//stop
				//file.print(".");
				//client.stop();
			}
		}
		//
		client.stop();
		//disconnected
		file.close();
	}
}
