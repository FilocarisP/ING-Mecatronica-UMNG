void Config_Timer3(){	//HSI 16MHz 1Seg
	RCC->APB1ENR |=(0x1<<1);
                        
	TIM3->PSC = 15999;                           
	TIM3->ARR = 99;                           
	TIM3->DIER |= (0x1<<0);                  
	//TIM3->CR1 |= (0x1<<0);                    
	NVIC_EnableIRQ(TIM3_IRQn); 
	NVIC_SetPriority(TIM3_IRQn, 3);
}
void Config_Timer7(){//HSI 16MHz 10seg
	RCC->APB1ENR |= (0x1<<5);
	
	TIM7->PSC = 15999;
	TIM7->ARR = 9999;
	TIM7->DIER |= (0x1<<0);
	//TIM7->CR1 |= (0x1<<0);
	NVIC_EnableIRQ(TIM7_IRQn);
	NVIC_SetPriority(TIM7_IRQn, 3);
}