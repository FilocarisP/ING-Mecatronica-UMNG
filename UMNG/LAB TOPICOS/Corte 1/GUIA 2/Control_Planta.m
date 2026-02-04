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
[num_d,den_d]=tfdata(Gd,'v'); a=den_d; b=num_d; A1=-a(2)/a(1); A2=-a(3)/a(1); B0=b(1)/a(1); B1=b(2)/a(1); B2=b(3)/a(1); fprintf('A1=%.6f A2=%.6f B0=%.8f B1=%.8f B2=%.8f\n',A1,A2,B0,B1,B2);

% fprintf('y[k] = %.6f*y[k-1] %+.6f*y[k-2] %+.8f*u[k-1] %+.8f*u[k-2]\n', A1, A2, B0, B1, B2);
% fprintf('y[k] = %.6f*y[k-1] %+.6f*y[k-2] %+.8f*u[k-1] %+.8f*u[k-2]\n', 1.824123, -0.837864, 0.00710559, 0.00669861);
fprintf('u[k] = u[k-1] + %.6f*e[k] %+.6f*e[k-1] %+.6f*e[k-2]\n', 60.9771, -112.214, 51.93); % C2D


