%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;

L = [105.28 120 155.25];
R(1) = Link('revolute',  'd', L(1), 'a', 0, 'alpha', 0, 'offset', pi);
R(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);
R(3) = Link('revolute',  'd', 0, 'a', L(3), 'alpha', 0, 'offset', 0);

Rob3r = SerialLink(R,'name','PARIN');

L5 = [105.28 120 89.75 65.5 38];
R5(1) = Link('revolute',  'd', L5(1), 'a', 0, 'alpha', 0, 'offset', pi);
R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);
R5(3) = Link('revolute',  'd', 0, 'a', 0, 'alpha', pi/2, 'offset', pi/2);
R5(4) = Link('revolute',  'd', L5(4)+L5(3), 'a', 0, 'alpha', 0, 'offset', 0);
R5(5) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);
Rob5r = SerialLink(R5, 'name', 'PARIN');

home3 = [0 0 0];
home = [0 0 0 0 0];

% figure(1)
% Rob3r.plot(home3)
% zlim([-10 400])
% Rob3r.teach(home3)
% hold on

figure(2)
Rob5r.plot(home)
zlim([-10 400])
Rob5r.teach(home)
hold on

% 
% L5 = [10, 0, 10, 10]; 
% L  = [0, 5]; 
% 
% % --- 2. DEFINICIÓN DEL ROBOT (Toolbox) ---
% % Copia exacta de tu definición
% R5(1) = Link('revolute',  'd', L5(1), 'a', 0, 'alpha', 0, 'offset', pi);
% R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);
% R5(3) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', pi/2, 'offset', L(2), 'qlim', [0 25]);
% R5(4) = Link('revolute',  'd', 0, 'a', L5(4)+L5(3), 'alpha', pi/2, 'offset', pi/2);
% R5(5) = Link('revolute',  'd', 0, 'a', 10, 'alpha', pi/2, 'offset', 0);
% Rob5r = SerialLink(R5, 'name', 'PARIN');
% 
% home = [0 0 0 0 0];
% 
% figure(2)
% Rob5r.plot(home)
% zlim([-10 40])
% Rob5r.teach(home)
% hold on