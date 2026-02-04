syms s z
%% Parámetros de la planta
numG = 150.8;
denG = [1 17.69 150.1];
G = tf(numG, denG);

%% Definir el tiempo de muestreo
Ts = 0.01; % periodo de muestreo en segundos 
Gd = c2d(G, Ts, 'zoh');

%% Mostrar resultado
disp('Función transferencia discreta:');
Gd

%% Convertir a polinomio en z^-1
[num_d, den_d] = tfdata(Gd, 'v'); % vectores
Gd_zinv = tf(num_d, den_d, Ts, 'Variable', 'z^-1');

disp('Función transferencia en atrasos (z^-1):');
Gd_zinv

%% Extraer numerador y denominador
[num_d, den_d] = tfdata(Gd, 'v'); % 'v' devuelve vectores


%% Guardar en variables
numerador = num_d;
denominador = den_d;
disp(numerador)
disp(denominador)
 
r0 = 62.5219
r1 = -148.912
r2 = 147.642
s0 = 0.139719
% --- Fin ---