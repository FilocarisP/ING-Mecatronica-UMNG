%run("C:\Users\pinzo\Documents\GitHub\UMNG\ROBOTICA\toolbox MATLAB\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m");
% clear;clc;
% 
% A=10;
% B=12;
% C=11;
% 
% R(1) = Link('revolute' ,'offset', 0, 'd', A, 'alpha', 0, 'a', 0);
% R(2) = Link('prismatic', 'theta', pi/2, 'a', 0, 'alpha', pi/2, 'qlim',[B B+2]);  
% R(3) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', 0, 'qlim',[C C+2]);
% patroclo = SerialLink(R,'name','PARIN');
% 
% [Q] = [0 12 11];
% home = Q; 
% rad2deg(home)
% figure(1)
% patroclo.plot(home)
% patroclo.teach(home)

%% Cinematica inversa


clear; clc;

% Parámetros de los eslabones
A = 10;  % desplazamiento del primer eslabón (revoluto)
B = 12;  % límite inferior del segundo eslabón (prismático)
C = 11;  % límite inferior del tercer eslabón (prismático)

% Definición del robot 1R2P
R(1) = Link('revolute', 'offset', 0, 'd', A, 'alpha', 0, 'a', 0);
R(2) = Link('prismatic', 'theta', pi/2, 'a', 0, 'alpha', pi/2, 'qlim', [B B+2]);
R(3) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', 0, 'qlim', [C C+2]);
patroclo = SerialLink(R, 'name', 'PARIN');

% Posición inicial en espacio cartesiano
T_A = transl(12, 11, 31);  % punto A
T_B = transl(-14, 7, 25);  % punto B

% Calcular cinemática inversa para A y B
qA = patroclo.ikine(T_A, 'mask', [1 1 1 0 0 0]);  % considerar solo posición XYZ
qB = patroclo.ikine(T_B, 'mask', [1 1 1 0 0 0]);

% Mostrar posición inicial
home = qA;
disp('Configuración articular inicial (grados):');
disp(rad2deg(home));

% Visualizar posición inicial
figure(1)
patroclo.plot(home)
patroclo.teach(home)

% Interpolación entre qA y qB
steps = 50;
traj = jtraj(qA, qB, steps);

% Visualizar trayectoria completa
figure(2)
patroclo.plot(traj)