ft= tf([0.02],[1 0.52 0.04])% -- Rehacer tiempo uniforme --
t0 = t(1); tf = t(end);
N = numel(t);
t_uni = linspace(t0, tf, N)';   % mismo número de puntos, pero uniformes

% Interpolar entradas y salida medida al nuevo tiempo
u_uni = interp1(t, u_lin, t_uni, 'linear');
y_uni = interp1(t, y_f, t_uni, 'linear');

% Simular con tiempo uniforme
y_sim = lsim(Gtheta, u_uni, t_uni, y_uni(1));  

figure;
subplot(3,1,1); plot(t,u,'LineWidth',1.2); grid on; ylabel('u (PWM)');
title('Entrada original');
subplot(3,1,2); plot(t,ydot,'k',t_uni,lsim(Gv1,u_uni,t_uni),'r--','LineWidth',1.2);
grid on; ylabel('\thetȧ (deg/s)'); legend('Medida','Modelo');
title('Ajuste en velocidad angular');
subplot(3,1,3); plot(t,y_f,'k',t_uni,y_sim,'r--','LineWidth',1.2);
grid on; ylabel('\theta (deg)'); xlabel('Tiempo (s)'); legend('Medida (filtrada)','Modelo');
title('Ajuste en ángulo');