unsigned long int Over8;
int bitsp;
int txi = 0;
char tx[32];

uint32_t BAUDRATE;

void config_USART(int USART,  char Puerto, int Pines, float bitP, uint32_t Baudios){
	bitsp = bitP * 2;
	Over8=0;
	if(USART==1){	//USART1  PA(9 y 10), PB(14 y 15)(6 y 7)
		RCC->APB2ENR |= (0x1<<4);			//USART1 Encendido
		if(Puerto=='A'){
			RCC->AHB1ENR |= 0x1;					// Puerto A
			if(Pines==910){
				GPIOA->MODER |= 0x280000;			// Alternante PA9 y PA10
				GPIOA->AFR[1] |= 0x770;				// AF7 PA9 y PA10
			}
		}
		if(Puerto=='B'){
			RCC->AHB1ENR |= 0x2;					// Puerto B
			if(Pines==67){
				GPIOB->MODER |= 0x7000;				// Alternante PB6 y PB7
				GPIOB->AFR[0] |= 0x77000000;	// AF4 PB6 y PB7
			}
			if(Pines==1415){
				GPIOB->MODER |= 0xA0000000;		// Alternante PB14 y PB15
				GPIOB->AFR[1] |= 0x44000000;	// AF4 PB14 y PB15
			}
		}
		switch(bitsp){
			case 1:{
					USART1->CR2 |= (0x1<<12);
					USART1->CR2 &= ~(0x1<<13);
				break;
			}
			case 2:{
					USART1->CR2 &= ~(0x1<<12);
					USART1->CR2 &= ~(0x1<<13); 
				break;
			}
			case 3:{
					USART1->CR2 |= (0x1<<12);
					USART1->CR2 |= (0x1<<13); 
				break;
			}
			case 4:{
					USART1->CR2 &= ~(0x1<<12);
					USART1->CR2 |= (0x1<<13); 
				break;
			}
		}
		BAUDRATE = (16000000/Baudios)+1;
		USART1->BRR |= BAUDRATE;
		USART1->CR1 |= 0xD;				 		// Transmision, recepcion, stop mode, enable USART
		USART1->CR1 |= (0x1<<5);	 		// Interrupcion (recepcion)
		USART1->CR1 &= ~(0x1<<15);	// Over8 = 0
		
		NVIC_SetPriority(USART1_IRQn,2);
		NVIC_EnableIRQ(USART1_IRQn);
	}
	if(USART==2){	//USART2  PA(2 y 3), PD(5 y 6) 

		RCC->APB1ENR |= (0x1<<17);		// USART2 Encendido
		if(Puerto=='A'){
			RCC->AHB1ENR |= 0x1;					// Puerto A
			if(Pines==23){
				GPIOA->MODER |= 0xA0;					// Alternante PA2 y PA3
				GPIOA->AFR[0] |= 0x7700;			// AF7 PA2 y PA3
			}
		}
		if(Puerto=='D'){
			RCC->AHB1ENR |= 0x8;					// Puerto D
			if(Pines==56){
				GPIOD->MODER |= 0x2800;				// Alternante PD5 y PD6
				GPIOD->AFR[0] |= 0x7700000;		// AF7 PD5 y PD6
			}
		}
		switch(bitsp){
			case 1:{
					USART2->CR2 |= (0x1<<12);
					USART2->CR2 &= ~(0x1<<13);
				break;
			}
			case 2:{
					USART2->CR2 &= ~(0x1<<12);
					USART2->CR2 &= ~(0x1<<13); 
				break;
			}
			case 3:{
					USART2->CR2 |= (0x1<<12);
					USART2->CR2 |= (0x1<<13); 
				break;
			}
			case 4:{
					USART2->CR2 &= ~(0x1<<12);
					USART2->CR2 |= (0x1<<13); 
				break;
			}
		}
		BAUDRATE = (16000000/Baudios)+1;
		USART2->BRR |= BAUDRATE;
		USART2->CR1 |= 0xD;				 		// Transmision, recepcion, stop mode, enable USART
		USART2->CR1 |= (0x1<<5);			// Interrupcion (recepcion)
		USART2->CR1 &= ~(0x1<<15);	// Over8 = 0
		
		NVIC_SetPriority(USART2_IRQn,2);
		NVIC_EnableIRQ(USART2_IRQn);
	}
	if(USART==3){	//USART3  PB(10 y 11), PC(10 y 11), PD(8 y 9)
		RCC->APB1ENR |= (0x1<<18);		// USART3 Encendido
		if(Puerto=='B'){
			RCC->AHB1ENR |= 0x2;					// Puerto B
			if(Pines==1011){
				GPIOB->MODER |= 0xA00000;			// Alternante PB10 y PB11
				GPIOB->AFR[1] |= 0x7700;			// AF7 PB10 y PB11
			}
		}
		if(Puerto=='C'){
			RCC->AHB1ENR |= 0x4;					// Puerto C
			if(Pines==1011){
				GPIOC->MODER |= 0xA00000;			// Alternante PC10 y PC11
				GPIOC->AFR[1] |= 0x7700;			// AF7 PC10 y PC11
			}
		}
		if(Puerto=='D'){
			RCC->AHB1ENR |= 0x8;					// Puerto D
			if(Pines==89){
				GPIOD->MODER |= 0xA0000;			// Alternante PD8 y PD9
				GPIOD->AFR[1] |= 0x77;				// AF7 PD8 y PD9
			}
		}
		switch(bitsp){
			case 1:{
					USART3->CR2 |= (0x1<<12);
					USART3->CR2 &= ~(0x1<<13);
				break;
			}
			case 2:{
					USART3->CR2 &= ~(0x1<<12);
					USART3->CR2 &= ~(0x1<<13); 
				break;
			}
			case 3:{
					USART3->CR2 |= (0x1<<12);
					USART3->CR2 |= (0x1<<13); 
				break;
			}
			case 4:{
					USART3->CR2 &= ~(0x1<<12);
					USART3->CR2 |= (0x1<<13); 
				break;
			}
		}
		BAUDRATE = (16000000/Baudios)+1;
		USART3->BRR |= BAUDRATE;
		USART3->CR1 |= 0xD;				 		// Transmision, recepcion, stop mode, enable USART
		USART3->CR1 |= (0x1<<5);	 		// Interrupcion (recepcion)
		USART3->CR1 &= ~(0x1<<15);	// Over8 = 0
		
		NVIC_SetPriority(USART3_IRQn,2);
		NVIC_EnableIRQ(USART3_IRQn);
	}
	if(USART==6){	//USART6  PC(6 y 7), PG(9 y 14)
		RCC->APB2ENR |= (0x1<<5);			// USART6 Encendido
		if(Puerto=='C'){
			RCC->AHB1ENR |= 0x4;					// Puerto C
			if(Pines==67){
				GPIOC->MODER |= 0xA000;				// Alternante PC6 y PC7
				GPIOC->AFR[0] |= 0x88000000;	// AF8 PC6 y PC7
			}
		}
		if(Puerto=='G'){
			RCC->AHB1ENR |= 0x40;					// Puerto G 
			if(Pines==914){
				GPIOG->MODER |= 0x20080000;		// Alternante PG9 y PG14
				GPIOG->AFR[1] |= 0x8000080; 	// AF8 PG9 y PG14
			}
		}
		switch(bitsp){
			case 1:{
					USART6->CR2 |= (0x1<<12);
					USART6->CR2 &= ~(0x1<<13);
				break;
			}
			case 2:{
					USART6->CR2 &= ~(0x1<<12);
					USART6->CR2 &= ~(0x1<<13); 
				break;
			}
			case 3:{
					USART6->CR2 |= (0x1<<12);
					USART6->CR2 |= (0x1<<13); 
				break;
			}
			case 4:{
					USART6->CR2 &= ~(0x1<<12);
					USART6->CR2 |= (0x1<<13); 
				break;
			}
		}
		BAUDRATE = (16000000/Baudios)+1;
		USART6->BRR |= BAUDRATE;
		USART6->CR1 |= 0xD;				 		// Transmision, recepcion, stop mode, enable USART
		USART6->CR1 |= (0x1<<5);			// Interrupcion (recepcion)
		USART6->CR1 &= ~(0x1<<15);	// Over8 = 0
		
		NVIC_SetPriority(USART6_IRQn,2);
		NVIC_EnableIRQ(USART6_IRQn);
	}
}
int USART1_SendChar(int value) { 	//Enviar Caracter
   USART1->TDR = value;
   while(!(USART1->ISR & USART_ISR_TXE));
   return 0;
 }
int USART2_SendChar(int value) { 	//Enviar Caracter
   USART2->TDR = value;
   while(!(USART2->ISR & USART_ISR_TXE));
   return 0;
 }
int USART3_SendChar(int value) { 	//Enviar Caracter
   USART3->TDR = value;
   while(!(USART3->ISR & USART_ISR_TXE));
   return 0;
 }
int USART6_SendChar(int value) { 	//Enviar Caracter
   USART6->TDR = value;
   while(!(USART6->ISR & USART_ISR_TXE));
   return 0;
 }
void USART1_SendChain(char str[32]){	//Enviar Cadena
	strncpy(tx,str,30);
	txi = 0;
	for(;txi<strlen(tx);){
		USART1_SendChar(tx[txi++]);
	}
}
void USART2_SendChain(char str[32]){	//Enviar Cadena
	strncpy(tx,str,30);
	txi = 0;
	for(;txi<strlen(tx);){
		USART2_SendChar(tx[txi++]);
	}
}
void USART3_SendChain(char str[32]){	//Enviar Cadena
	strncpy(tx,str,30);
	txi = 0;
	for(;txi<strlen(tx);){
		USART3_SendChar(tx[txi++]);
	}
}
void USART6_SendChain(char str[32]){	//Enviar Cadena
	strncpy(tx,str,30);
	txi = 0;
	for(;txi<strlen(tx);){
		USART6_SendChar(tx[txi++]);
	}
}