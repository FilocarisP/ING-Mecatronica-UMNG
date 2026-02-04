void Display(int count){
	switch(count){
		case 0://0
			GPIOD->BSRR |= (0x0040003F);
		break;
		case 1://
			GPIOD->BSRR |= (0x00790006);
		break;
		case 2://2
			GPIOD->BSRR |= (0x0024005B);
		break;
		case 3://3
			GPIOD->BSRR |= (0x0030004F);
		break;
		case 4://4
			GPIOD->BSRR |= (0x00190066);
		break;
		case 5://5
			GPIOD->BSRR |= (0x0012006D);
		break;
		case 6://6
			GPIOD->BSRR |= (0x0002007D);
		break;
		case 7://7
			GPIOD->BSRR |= (0x00780007);
		break;
		case 8://8
			GPIOD->BSRR |= (0x0000007F);
		break;
		case 9://9
			GPIOD->BSRR |= (0x00180067);
		break;
		case 10://A
			GPIOD->BSRR |= (0x00080077);
		break;
		case 11://B
			GPIOD->BSRR |= (0x0003007C);
		break;
		case 12://C
			GPIOD->BSRR |= (0x00460039);
		break;
		case 13://D
			GPIOD->BSRR |= (0x0021005E);
		break;
		case 14://E
			GPIOD->BSRR |= (0x00060079);
		break;
		case 15://F
			GPIOD->BSRR |= (0x000E0071);
		break;
		case 16://G
			GPIOD->BSRR |= (0x0010006F);
		break;
		case 17://H
			GPIOD->BSRR |= (0x00090076);
		break;
		case 18://I
			GPIOD->BSRR |= (0x004F0030);
		break;
		case 19://J
			GPIOD->BSRR |= (0x0061001E);
		break;
		case 20://K
			GPIOD->BSRR |= (0x00090076);
		break;
		case 21://L
			GPIOD->BSRR |= (0x00470038);
		break;
		case 22://M
			GPIOD->BSRR |= (0x006A0015);
		break;
		case 23://N
			GPIOD->BSRR |= (0x002B0054);
		break;
		case 24://O
			GPIOD->BSRR |= (0x0040003F);
		break;
		case 25://P
			GPIOD->BSRR |= (0x000C0073);
		break;
		case 26://Q
			GPIOD->BSRR |= (0x00180067);
		break;
		case 27://R
			GPIOD->BSRR |= (0x002F0050);
		break;
		case 28://S
			GPIOD->BSRR |= (0x0012006D);
		break;
		case 29://T
			GPIOD->BSRR |= (0x00070078);
		break;
		case 30://U
			GPIOD->BSRR |= (0x0041003E);
		break;
		case 31://V
			GPIOD->BSRR |= (0x0063001C);
		break;
		case 32://W
			GPIOD->BSRR |= (0x0055002A);
		break;
		case 33://X
			GPIOD->BSRR |= (0x00090076);
		break;
		case 34://Y
			GPIOD->BSRR |= (0x0011006E);
		break;
		case 35://Z
			GPIOD->BSRR |= (0x0024005B);
		break;
		case 36://Off
			GPIOD->BSRR |= (0xFFFF0000);
		default:
			GPIOD->ODR |= (0xFFFF0000);
	}
}