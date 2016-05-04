//////////////////////////////////////////////////////////////////////////////////
// Autorzy: Arkadiusz Kuberek, Tomasz Lukawski
// Grupa: E2
//////////////////////////////////////////////////////////////////////////////////

//ABY UKLAD DZIALAL ENABLE (K13) HIGH
//RESET(K14) LOW 


module VGA(TYPE,RESET,ENABLE,R,G,B,HSYNC,VSYNC,CLK);
    input CLK; //zegar systemowy 50MHz
    input [1:0]TYPE; //rodzaj generowanej animacji badz tla
    input RESET; //reset preskalera
    input ENABLE; //aktywacja preskalera
    wire CLKOUT; //polaczenie preskalera
    wire ANIMATION_CLOCK; //polaczenie preskalera animacji
    output R,G,B; //wyjscia pinów koloru RGB zlacza VGA
    output HSYNC,VSYNC; //wyjscia synchronizacji pinów zlacza VGA
    wire [9:0]HDATA; //polaczenie licznika HSYNC
    wire [9:0]VDATA; //polaczenie licznika VSYNC
    wire [3:0]NUMBER; 
	 
   
    CLOCK CLOCK25(CLK,ENABLE,RESET,CLKOUT);  //preskaler redukujacy czestotliwosc systemowa (50MHz na 25MHz)	 
    HVSYNC_DRV HVSYNC_DRIVER(CLKOUT,HDATA,VDATA,HSYNC,VSYNC); //generator sygnalów HSYNC/VSYNC zlacza VGA
    VIDEO_GENERATOR PRINT_BLOCK(CLKOUT,TYPE,R,G,B,HDATA,VDATA, NUMBER); //generator syganlu video 
    ANIMATION_COUNTER MYCOUNTER(ANIMATION_CLOCK,RESET,NUMBER); //blok licznkikow animacji 
    PRE_ANIMATION_COUNTER KUNTER(VSYNC, RESET, ANIMATION_CLOCK); //instancja preskalera animacji
endmodule


//Glowny preskaler ukladu
//Zmneijsza czestotliwoœæ 2-ktrotnie
//Aby otrzymac pixelclock = 25Mhz 
module CLOCK(CLK,ENABLE,RESET,CLKOUT);
    input CLK; //systemowy zegar 50MHz
    input RESET; 
    input ENABLE;
    output CLKOUT; //wyjscie preskalera po zredukowaniu czestotliwosci zegara
    wire CLK;
    wire ENABLE;
    reg CLKOUT;

    always @ (posedge CLK)

    if (RESET) begin 
    	CLKOUT <= 1'b0;
    end else if (ENABLE) begin
        CLKOUT <= !CLKOUT; 
    end 
endmodule




// Modul zajmujacy sie tworzeniem sygnalów VSYNC oraz VSYNC, modul zwraca koordynanty danego pixela
module HVSYNC_DRV(CLK,HDATA,VDATA,HSYNC,VSYNC);
    input CLK; //zegar 25MHz
    output reg [9:0]HDATA; //licznik HSYNC
    output reg [9:0]VDATA; //licznik VSYNC
    output reg HSYNC; //wyjscie sygnalu HSYNC
    output reg VSYNC; //wyjscie sygnalu VSYNC
     
    //blok odpowiedzilany za HSYNC
    //zlicza pixele w wierszu z uwzglednieniem tzw ramek
    //suma pixeli = 800 (640+ramki+Hsync)
    always @(posedge CLK)
    begin
    	HDATA <= HDATA + 1; //inkrementacja
       
    	if(HDATA==10'd799) //zakres licznika
    	begin
		VDATA <= VDATA + 1;
		HDATA <=10'd0;
    	end
     
    	if(HDATA==10'd659) 
    		HSYNC<=1'b0; //poczatek HSYNC
		
    	if(HDATA==10'd752) 
    		HSYNC<=1'b1; //kniec HSYNC
		
    	if(VDATA==10'd524) 
    		VDATA<=10'd0; //resetowanie licznika VSYNC	
    
    	if(VDATA==10'd491) 
    		VSYNC<=1'b0; //pocztek VSYNC 
    
    	if(VDATA==10'd493) 
    		VSYNC<=1'b1; //koniec VSYNC
    end
endmodule
     

//Modul odpowiadajacy za generacje obrazu
//Przyjmuje koordynaty pixela, sprawdza czy miesci sie w zakresie wyswietlania
//Nastepnie generuje odpowiedni obraz w zaleznosci od wejsc wybierajacych
module VIDEO_GENERATOR(CLK,TYPE,R,G,B,HDATA,VDATA, NUMBER);
    input [1:0]TYPE; //Rodzaj animacji wybierany z klawiszy F12 G12 
    inout CLK;
    output reg R,G,B; // Wyjscia na VGA
    input [9:0]HDATA;
    input [9:0]VDATA;
    input [2:0]NUMBER; // WEJSCIE LICZNIKA ANIMACJI
     
    always @(posedge CLK)
    begin				
		if((HDATA>=10'd0 && HDATA<=10'd639) && (VDATA>=10'd0 && VDATA<=10'd479)) //Sprawdzenie czy jestesmy w zakresie wyswietlania
		begin 
			//Blok wyboru generowanych obrazów		
			if(TYPE==0)//Animacja prostokontów 
			begin
				//Obcinami liczbe bitow zaczynajac od najmniej znaczacego bittu
				//Dzieki czemu pojedyncze pixele zamieniaja sie w kwadraty/prostokaty
				//Dodatkowo kolory brane s¹ ze stanów licznika
				//Przez co ca³y czas siê zmieniaja
				if(HDATA[3]==1) //Obcina pixele w poziomie
				begin
					if(VDATA[NUMBER]==1) // Obcina pixele  w pionie
					begin
						R=NUMBER[0];
                  G=NUMBER[1];
                  B=NUMBER[2];
					end 
					else 
					begin
                  R=NUMBER[2];
                  G=NUMBER[1];
                  B=NUMBER[0];
               end
			   end 
			   else 
			   begin
					if(VDATA[NUMBER]==0)
					begin
						R=NUMBER[0];
                  G=NUMBER[1];
                  B=NUMBER[2];
					end 
					else 
					begin
                  R=NUMBER[2];
                  G=NUMBER[1];
                  B=NUMBER[0];
					end
				end 
			end
			  
		//Animowane kwadraty
		//Zasada taka sama jak w poprzednim obrazie
		//Sta³e kolory
		else 
			if (TYPE==1)
			begin	
				if(HDATA[NUMBER]==1 && VDATA[NUMBER]==0)
				begin
					R=1'b0;
               G=1'b0;
               B=1'b0;
            end 
				else 
				begin
               R=1'b1;
               G=1'b1;
               B=1'b0;
            end
			end

			//Podobnie jak w 1 przypadku tylko pomieszano bity kolorow
			else 
				if (TYPE==2)
				begin
					if(VDATA[NUMBER]==1)
					begin
						R=NUMBER[0];
                  G=NUMBER[1];
                  B=NUMBER[2];
					end 
					else 
					begin
						R=NUMBER[2];
						G=NUMBER[1];
                  B=NUMBER[0];
               end
				end 
				else 
				begin
					if(VDATA[NUMBER]==0)
					begin
						R=NUMBER[1];
                  G=NUMBER[0];
                  B=NUMBER[2];
					end 
					else 
					begin
						R=NUMBER[2];
                  G=NUMBER[1];
                  B=NUMBER[2];
					end
        		end
		end
		
      else
		begin
			R=0;
			G=0;
			B=0;
      end   
    end
endmodule

//licznik odpowiedzialny za zmiane rozmiaru generowanej animacji
//Liczy do przodu, a jak osiagnie wartosc 6 to zaczyna odliczac wstecz
module ANIMATION_COUNTER(CLK, RESET, NUMBER);
    input CLK; 
    input RESET;
    reg WAY;
    output reg [2:0]NUMBER;

    always @(posedge CLK)
    begin
    	if(RESET)
	begin
		NUMBER <= 3'b000;
		WAY <= 1'b0;
	end
	
//Blok zmiany kierunku
	if(NUMBER == 3'b110)
		WAY <= 1'b1;

	if(NUMBER == 3'b001)
		WAY <= 1'b0;
//Dodawanie lub odjemowanie w zaleznosci od wybranego kierunku
// 0 -> do przodu 1-> do ty³u
	if(WAY==0)
		NUMBER <= NUMBER + 1;
	if(WAY==1)
		NUMBER <= NUMBER - 1;

    end
endmodule

//blok odpowiedzialny za redukcje czestotliwosci, która wykorzystana bedzie do szybkosci zmian rozmiaru animacji
//liczy do 16
module PRE_ANIMATION_COUNTER(CLK, RESET, OUT);
    input CLK; //sygnal VSYNC (60Hz)
    input RESET;
    reg [4:0]NUMBER;
    output reg OUT; // 3,75Hz

    always @ (posedge CLK)
    if(RESET)
	NUMBER <= 5'b00000;
    else 
	if(NUMBER == 5'b10000)//sprawdzenie 16
	begin
		NUMBER <= 5'b00000;
		OUT <= 1;
	end
	else 
	begin
		NUMBER <= NUMBER + 1;
		OUT <= 0;
	end
endmodule
