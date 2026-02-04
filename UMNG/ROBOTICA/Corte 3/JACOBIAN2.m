clear; clc; close all;

L1=15;

L2=30;

L3=15;

L4=30;

% Definición del Robot (Toolbox)

E(1) = Link('revolute','d',L1,'alpha',0,'a',L2,'offset',0);

E(2) = Link('revolute','d',L3,'alpha',0,'a',L4,'offset',0);

Robot=SerialLink(E,'name','ART2R');

q=[0 0];

syms q1 q2 l1 l2 l3 l4 real

% --- AQUÍ OCURRÍA EL ERROR ---

% Ahora funcionará porque abajo agregamos la función MiDH y corregimos el orden

MTH = simplify(Art_2R_fkin([q1 q2], l1, l2, l3, l4));

PosVector = simplify(MTH(1:3,4));

J2R = jacobian(PosVector, [q1 q2]);

J2R = J2R(1:2, 1:2); % Solo X e Y para robot planar

J2Rinv = simplify(inv(J2R));

% Configuración inicial y trayectoria

qin = [pi/3 pi/3]';

qtraj = [0 0]';

% Inicializar gráfica

Robot.plot(qin');

hold on

% --- BUCLES DE MOVIMIENTO (CUADRADO) ---

% Lado 1: X positivo

for i=1:1:50

Thetadot = eval(subs(J2Rinv*[0.5; 0.0], [q1 q2 l1 l2 l3 l4], [qin(1) qin(2) L1 L2 L3 L4]));

qin = qin + Thetadot;

MTH_num = Art_2R_fkin(qin, L1, L2, L3, L4); % Cinemática numérica actual


Robot.plot(qin');

plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');

pause(0.001)

end

% Lado 2: Y negativo

for i=1:1:50

Thetadot = eval(subs(J2Rinv*[0.0; -0.5], [q1 q2 l1 l2 l3 l4], [qin(1) qin(2) L1 L2 L3 L4]));

qin = qin + Thetadot;

MTH_num = Art_2R_fkin(qin, L1, L2, L3, L4);


Robot.plot(qin');

plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');

pause(0.001)

end

% Lado 3: X negativo

for i=1:1:50

Thetadot = eval(subs(J2Rinv*[-0.5; 0], [q1 q2 l1 l2 l3 l4], [qin(1) qin(2) L1 L2 L3 L4]));

qin = qin + Thetadot;

MTH_num = Art_2R_fkin(qin, L1, L2, L3, L4);


Robot.plot(qin');

plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');

pause(0.001)

end

% Lado 4: Y positivo

for i=1:1:50

Thetadot = eval(subs(J2Rinv*[0.0; 0.5], [q1 q2 l1 l2 l3 l4], [qin(1) qin(2) L1 L2 L3 L4]));

qin = qin + Thetadot;

MTH_num = Art_2R_fkin(qin, L1, L2, L3, L4);


Robot.plot(qin');

plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');

pause(0.001)

end

% --- FUNCIONES AUXILIARES (Deben ir al final) ---

function MTH = Art_2R_fkin(q, L1, L2, L3, L4)

% CORRECCIÓN IMPORTANTE:

% MiDH(theta, d, a, alpha)

% Tu Link 1 tiene d=L1, a=L2, alpha=0

T1 = MiDH(q(1), L1, L2, 0);


% Tu Link 2 tiene d=L3, a=L4, alpha=0

T2 = MiDH(q(2), L3, L4, 0);


MTH = T1 * T2;

end

% Esta es la función que te faltaba

function T = MiDH(theta, d, a, alpha)

T = [cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);

sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);

0 sin(alpha) cos(alpha) d;

0 0 0 1];

end

%% HOLA 5R
% clear; clc; close all;
% 
% %% --- 1. CONFIGURACIÓN DE LA PALABRA (¡EDITA ESTO!) ---
% % Usa el símbolo '|' para indicar SALTO DE LÍNEA
% TEXTO_A_ESCRIBIR = 'H O L A'; 
% Escala_Letra     = 0.4;      % Tamaño de la letra (multiplicador)
% Altura_Escritura = 15;       % Altura Z donde escribe
% Espacio_Letras   = 2;        % Espacio en blanco entre letras
% 
% % COORDENADAS DE INICIO (Pared YZ)
% % Profundidad (X), Inicio Horizontal (Y), Inicio Vertical (Z)
% Punto_Inicio     = [15, -40, 50]; 
% 
% %% --- 2. DEFINICIÓN DEL ROBOT ---
% L5_vec = [10, 0, 10, 10]; 
% L_vec  = [0, 5]; 
% 
% R5(1) = Link('revolute',  'd', L5_vec(1), 'a', 0, 'alpha', 0, 'offset', pi);
% R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L_vec(2));
% R5(3) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', pi/2, 'offset', L_vec(2));
% R5(4) = Link('revolute',  'd', 0, 'a', L5_vec(4)+L5_vec(3), 'alpha', pi/2, 'offset', pi/2);
% R5(5) = Link('revolute',  'd', 0, 'a', 10, 'alpha', pi/2, 'offset', 0);
% 
% Rob5r = SerialLink(R5, 'name', 'ROBOT_ESCRITOR');
% 
% %% --- 3. CÁLCULO SIMBÓLICO ---
% disp('Cargando matemáticas...');
% syms q1 q2 q3 q4 q5 real 
% MTH = simplify(Nuevo_Fkin([q1 q2 q3 q4 q5], L5_vec, L_vec));
% PosVector = simplify(MTH(1:3,4)); 
% J_sym = jacobian(PosVector, [q1 q2 q3 q4 q5]);
% 
% %% --- 4. INICIALIZACIÓN ---
% % Posición inicial lista para escribir en el plano XY
% % q2 controla X aprox, q3 controla Y aprox.
% qin = [0, 5, 5, 0, 0]'; 
% 
% figure(1);
% Rob5r.plot(qin', 'workspace', [-40 60 -40 60 0 60], 'scale', 0.5, 'floorlevel', 0);     
% hold on; grid on; 
% %view(0, 90); % VISTA SUPERIOR Plano XY
% view(90, 0); % VISTA LATERAL Plano YZ
% zlim([-10 80]);
% 
% %% --- 5. INTÉRPRETE DE TEXTO (MOTOR DE ESCRITURA) ---
% % Parámetros globales de movimiento
% dt = 0.1;
% pasos_base = 15; % Pasos por cada segmento de línea
% 
% % Mover al punto inicial de escritura
% fprintf('Posicionándose para escribir: "%s"...\n', TEXTO_A_ESCRIBIR);
% 
% % Iterar letra por letra
% for i = 1:length(TEXTO_A_ESCRIBIR)
%     letra = upper(TEXTO_A_ESCRIBIR(i)); % Convertir a mayúscula
% 
%     % Obtener las instrucciones de trazo para la letra [dx, dy, lapiz_on]
%     trazos = DiccionarioLetras(letra);
% 
%     fprintf('Escribiendo: %s\n', letra);
% 
%     % Ejecutar cada segmento de la letra
%     [filas, ~] = size(trazos);
%     for k = 1:filas
%         dx = trazos(k, 1) * Escala_Letra;
%         dy = trazos(k, 2) * Escala_Letra;
%         lapiz = trazos(k, 3); % 1 = pintar, 0 = mover sin pintar
% 
%         % Calcular Vector Velocidad necesario para ese desplazamiento
%         % Desplazamiento = Velocidad * (pasos * dt)
%         % Velocidad = Desplazamiento / (pasos * dt)
%         %V_des = [dx; dy; 0] / (pasos_base * dt); %plano XY
%         V_des = [0; dx; dy] / (pasos_base * dt); %plano YZ
% 
%         % Llamar al bucle de control
%         qin = bucle_movimiento(Rob5r, J_sym, MTH, V_des, pasos_base, dt, qin, lapiz, q1,q2,q3,q4,q5);
%     end
% 
%     % Espacio después de cada letra (Movimiento sin pintar)
%     %V_espacio = [Espacio_Letras; 0; 0] / (pasos_base * dt);  %plano XY
%     V_espacio = [0; Espacio_Letras; 0] / (pasos_base * dt);  %plano YZ
%     qin = bucle_movimiento(Rob5r, J_sym, MTH, V_espacio, pasos_base, dt, qin, 0, q1,q2,q3,q4,q5);
% end
% 
% disp('Escritura finalizada.');
% 
% %% --- FUNCIONES AUXILIARES ---
% 
% % 1. BUCLE DE MOVIMIENTO (Con control de Lápiz)
% function q_actual = bucle_movimiento(Robot, J_sym, MTH, V_des, pasos, dt, q_in, pintar, q1,q2,q3,q4,q5)
%     q_actual = q_in;
%     for i=1:pasos
%         J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], q_actual'));
%         qdot = pinv(J_num) * V_des;
%         q_actual = q_actual + qdot * dt;
% 
%         Robot.animate(q_actual');
% 
%         if pintar == 1
%             % Solo dibujamos si el lápiz está "abajo"
%             pos_num = double(subs(MTH, [q1 q2 q3 q4 q5], q_actual'));
%             plot3(pos_num(1,4), pos_num(2,4), pos_num(3,4), 'r.', 'MarkerSize', 8);
%         end
%         pause(0.01);
%     end
% end
% 
% % 2. DICCIONARIO DE LETRAS (Definición Geométrica)
% % Formato de salida: Matriz donde cada fila es [DeltaX, DeltaY, Pintar(1)/No(0)]
% % Se asume que la letra empieza abajo a la izquierda de su "caja"
% function trazos = DiccionarioLetras(letra)
%     w = 6; % Ancho estándar
%     h = 10; % Alto estándar
% 
%     switch letra
%         case ' ' % ESPACIO
%             trazos = [4, 0, 0]; % Solo moverse a la derecha
% 
%         case 'A'
%             trazos = [
%                 w/2, h, 1;   % Subir diagonal derecha
%                 w/2, -h, 1;  % Bajar diagonal derecha
%                 -w*0.8, 0.4*h, 0; % Regresar (sin pintar) al centro
%                 w*0.6, 0, 1; % Barra horizontal
%                 w*0.2, -0.4*h, 0 % Ir al final de la letra (sin pintar)
%             ];
% 
%         case 'B'
%             trazos = [
%                 0, h, 1;     % Palo vertical
%                 w, -h*0.25, 1; % Curva arriba (simplificada recta)
%                 -w*0.8, -h*0.25, 1; % Entrar al centro
%                 w*0.8, -h*0.25, 1; % Salir del centro
%                 -w, -h*0.25, 1; % Curva abajo
%                 w, 0, 0;      % Posicionar para sig letra
%             ];
% 
%         case 'C'
%             trazos = [
%                w, h, 0;    % Ir arriba derecha (sin pintar)
%                -w, 0, 1;   % Techo
%                0, -h, 1;   % Pared izq
%                w, 0, 1;    % Suelo
%             ];
% 
%         case 'D'
%             trazos = [
%                 0, h, 1;    % Palo vertical
%                 w, -h/2, 1; % Diagonal centro
%                 -w, -h/2, 1; % Diagonal abajo
%                 w, 0, 0;    % Posicionar
%             ];
% 
%         case 'E'
%             trazos = [
%                 0, h, 1;   % Palo vertical
%                 w, 0, 1;   % Techo
%                 -w, -h/2, 0; % Bajar a la mitad (sin pintar)
%                 w*0.8, 0, 1; % Barra medio
%                 -w*0.8, -h/2, 0; % Bajar al suelo (sin pintar)
%                 w, 0, 1;   % Suelo
%             ];
% 
%         case 'F'
%             trazos = [
%                 0, h, 1;     % Palo vertical
%                 w, 0, 1;     % Techo
%                 -w, -h/2, 0; % Bajar mitad (sin pintar)
%                 w*0.8, 0, 1; % Barra medio
%                 0, -h/2, 0;  % Bajar suelo
%                 w*0.2, 0, 0; % Ir final
%             ];
% 
%         case 'G'
%             trazos = [
%                 w, h, 0; % Ir arriba derecha
%                 -w, 0, 1; % Techo
%                 0, -h, 1; % Pared izq
%                 w, 0, 1; % Suelo
%                 0, h*0.4, 1; % Ganchito subida
%                 -w*0.3, 0, 1; % Ganchito dentro
%                 w*0.3, -h*0.4, 0; % Volver al suelo
%             ];
% 
%         case 'H'
%             trazos = [
%                 0, h, 1;      % Palo Izq
%                 0, -h/2, 0;   % Bajar mitad (sin pintar)
%                 w, 0, 1;      % Puente
%                 0, h/2, 1;    % Palo Der (Arriba)
%                 0, -h, 1;     % Palo Der (Abajo)
%             ];
% 
%         case 'I'
%             trazos = [
%                 w/2, 0, 0; % Mover al centro
%                 0, h, 1;   % Palo
%                 w/2, -h, 0; % Ir al final
%             ];
% 
%         case 'J'
%             trazos = [
%                 w, h, 0;      % Ir arriba derecha (sin pintar)
%                 0, -h*0.8, 1; % Bajar casi todo
%                 -w*0.5, -h*0.2, 1; % Gancho hacia izquierda
%                 w*0.5, 0, 0;  % Ir final
%             ];
% 
%         case 'K'
%             trazos = [
%                 0, h, 1;      % Palo vertical
%                 0, -h/2, 0;   % Volver al centro
%                 w, h/2, 1;    % Rama arriba
%                 -w, -h/2, 0;  % Volver centro
%                 w, -h/2, 1;   % Rama abajo
%             ];
% 
%         case 'L'
%             trazos = [
%                 0, h, 1;      % Arriba
%                 0, -h, 0;     % Abajo (repaso o sin pintar, mejor bajar sin pintar para no engrosar)
%                 0, 0, 1;      % (Reinicio lógico)
%                 w, 0, 1;      % Derecha (base)
%             ];
%             % Corregimos L para que sea continua:
%             trazos = [
%                 0, h, 0; % Ir arriba
%                 0, -h, 1; % Palo abajo
%                 w, 0, 1; % Base
%             ];
% 
%         case 'M'
%             trazos = [
%                 0, h, 1;      % Palo Izq
%                 w/2, -h/2, 1; % Diagonal centro
%                 w/2, h/2, 1;  % Diagonal subida
%                 0, -h, 1;     % Palo der
%             ];
% 
%         case 'N'
%             trazos = [
%                 0, h, 1;     % Palo Izq
%                 w, -h, 1;    % Diagonal
%                 0, h, 1;     % Palo Der
%                 0, -h, 0;    % Bajar al suelo (sin pintar)
%             ];
% 
%         case 'O'
%             trazos = [
%                 0, h, 1; % Izq
%                 w, 0, 1; % Techo
%                 0, -h, 1; % Der
%                 -w, 0, 1; % Suelo
%                 w, 0, 0; % Ir al final (sin pintar)
%             ];
% 
%         case 'P'
%             trazos = [
%                 0, h, 1; % Palo
%                 w, 0, 1; % Techo
%                 0, -h*0.4, 1; % Bajada P
%                 -w, 0, 1; % Cierre P
%                 w, -h*0.6, 0; % Ir al final suelo
%             ];
% 
%         case 'Q'
%             trazos = [
%                 0, h, 1; w, 0, 1; 0, -h, 1; -w, 0, 1; % La O
%                 w*0.6, h*0.3, 0; % Posicionarse para la cola
%                 w*0.4, -h*0.3, 1; % Colita
%             ];
% 
%         case 'R'
%             trazos = [
%                 0, h, 1; % Palo
%                 w, 0, 1; % Techo
%                 0, -h*0.4, 1; % Bajada R
%                 -w, 0, 1; % Cierre bucle
%                 w, -h*0.6, 1; % Patita R
%             ];
% 
%         case 'S'
%             trazos = [
%                 w, h*0.2, 0; % Inicio S (un poco arriba)
%                 -w, 0, 0; % ...ajuste
%                 w, 0, 1; % Base
%                 0, h/2, 1; % Der
%                 -w, 0, 1; % Medio
%                 0, h/2, 1; % Izq arriba
%                 w, 0, 1; % Techo
%                 0, -h, 0; % Volver suelo
%             ];
% 
%         case 'T'
%             trazos = [
%                w/2, 0, 0;      % Ir al centro
%                0, h, 1;        % Palo central
%                -w/2, 0, 1;     % Mitad techo izq
%                w, 0, 1;        % Techo completo der
%                0, -h, 0;       % Bajar (sin pintar)
%             ];
% 
%         case 'U'
%             trazos = [
%                 0, h, 0; % Ir arriba izq
%                 0, -h, 1; % Bajar
%                 w, 0, 1; % Suelo
%                 0, h, 1; % Subir der
%                 0, -h, 0; % Bajar
%             ];
% 
%         case 'V'
%             trazos = [
%                 0, h, 0;       % Inicio arriba izq
%                 w/2, -h, 1;    % Diagonal centro abajo
%                 w/2, h, 1;     % Diagonal arriba der
%                 0, -h, 0;      % Bajar final
%             ];
% 
%         case 'W'
%             trazos = [
%                 0, h, 0;          % Inicio arriba izq
%                 w*0.3, -h, 1;     % Bajada 1
%                 w*0.2, h*0.6, 1;  % Subida media
%                 w*0.2, -h*0.6, 1; % Bajada media
%                 w*0.3, h, 1;      % Subida final
%                 0, -h, 0;         % Bajar final
%             ];
% 
%         case 'X'
%             trazos = [
%                0, h, 0;    % Ir arriba izq
%                w, -h, 1;   % Diagonal bajada
%                0, h, 0;    % Subir derecha (sin pintar)
%                -w, -h, 1;  % Diagonal bajada cruzada
%                w, 0, 0;    % Ir final
%             ];
% 
%         case 'Y'
%             trazos = [
%                0, h, 0; % Ir arriba izq
%                w/2, -h/2, 1; % Centro
%                w/2, h/2, 1; % Rama derecha
%                -w/2, -h/2, 0; % Volver centro
%                0, -h/2, 1; % Palo abajo
%                w/2, 0, 0; % Ir a fin
%             ];
% 
%         case 'Z'
%             trazos = [
%                 0, h, 0;    % Ir arriba izq
%                 w, 0, 1;    % Techo
%                 -w, -h, 1;  % Diagonal
%                 w, 0, 1;    % Base
%             ];
% 
%         otherwise
%             % Si la letra no existe, dibuja un cuadrado simple
%             disp(['Letra ', letra, ' no definida. Dibujando caja.']);
%             trazos = [0, h, 1; w, 0, 1; 0, -h, 1; -w, 0, 1; w, 0, 0];
%     end
% end
% 
% % 3. Función Kinematica 
% function MTH = Nuevo_Fkin(q, L5_v, L_v)
%     T1 = MiDH(q(1) + pi, L5_v(1), 0, 0);
%     T2 = MiDH(-pi/2, q(2) + L_v(2), 0, -pi/2);
%     T3 = MiDH(-pi/2, q(3) + L_v(2), 0, pi/2);
%     a4 = L5_v(4) + L5_v(3);
%     T4 = MiDH(q(4) + pi/2, 0, a4, pi/2);
%     a5 = 10; 
%     T5 = MiDH(q(5), 0, a5, pi/2);
%     MTH = T1 * T2 * T3 * T4 * T5;
% end
% 
% function T = MiDH(theta, d, a, alpha)
%     T = [cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
%          sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
%          0          sin(alpha)            cos(alpha)            d;
%          0          0                     0                     1];
% end

%% 