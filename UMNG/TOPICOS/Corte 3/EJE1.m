% --- CÓDIGO MATLAB: GENERACIÓN DE TRAYECTORIA ÁRBOL DE NAVIDAD (PLANO YZ) ---
clc; clear; close all;

% 1. DEFINICIÓN DE WAYPOINTS (COORDENADAS)
% El robot dibujará en el plano YZ. X será constante (profundidad).
% Coordenadas en Metros (m).

% Formato: [Y, Z]
waypoints = [
    0.000, 0.000;   % 1.  Inicio (Centro Base)
    0.025, 0.000;   % 2.  Base Tronco Derecha
    0.025, 0.050;   % 3.  Tope Tronco Derecha
    0.120, 0.050;   % 4.  Punta Rama Baja Derecha
    0.050, 0.120;   % 5.  Interior Rama Baja
    0.100, 0.120;   % 6.  Punta Rama Media Derecha
    0.040, 0.190;   % 7.  Interior Rama Media
    0.070, 0.190;   % 8.  Punta Rama Alta Derecha
    0.000, 0.280;   % 9.  CIMA (Estrella/Punta)
   -0.070, 0.190;   % 10. Punta Rama Alta Izquierda
   -0.040, 0.190;   % 11. Interior Rama Media
   -0.100, 0.120;   % 12. Punta Rama Media Izquierda
   -0.050, 0.120;   % 13. Interior Rama Baja
   -0.120, 0.050;   % 14. Punta Rama Baja Izquierda
   -0.025, 0.050;   % 15. Tope Tronco Izquierda
   -0.025, 0.000;   % 16. Base Tronco Izquierda
    0.000, 0.000    % 17. Cerrar contorno (Volver al inicio)
];

% Separamos las coordenadas para graficar
Y = waypoints(:, 1);
Z = waypoints(:, 2);

% Definimos X constante (solo para referencia, ej. 0.3m frente al robot)
X_constante = 0.3 * ones(size(Y)); 


% 2. VISUALIZACIÓN DEL CONTORNO (PLANO 2D)
figure('Name', 'Trayectoria Robot - Plano YZ', 'Color', 'w');
plot(Y, Z, 'b.-', 'LineWidth', 2, 'MarkerSize', 15);
hold on;

% Decoración de la gráfica
grid on;
axis equal; % Para que no se deforme el dibujo
xlabel('Eje Y (Ancho del Robot) [m]');
ylabel('Eje Z (Altura del Robot) [m]');
title('Trayectoria de Waypoints: Árbol de Navidad');

% Añadir números a los waypoints para saber el orden
for i = 1:length(Y)-1
    text(Y(i), Z(i), ['  P', num2str(i)], 'FontSize', 8, 'Color', 'r');
end

% Mostrar límites
xlim([-0.15, 0.15]);
ylim([-0.05, 0.35]);

% 3. VISUALIZACIÓN 3D (OPCIONAL)
figure('Name', 'Vista 3D Robot', 'Color', 'w');
plot3(X_constante, Y, Z, 'r.-', 'LineWidth', 2);
grid on;
axis equal;
xlabel('Eje X (Profundidad)');
ylabel('Eje Y (Ancho)');
zlabel('Eje Z (Altura)');
title('Vista 3D (Como lo vería el Robot)');
view(120, 30); % Cambiar ángulo de vista