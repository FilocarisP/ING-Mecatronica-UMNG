% --- CÓDIGO MATLAB: VERIFICACIÓN TRAYECTORIA ÁRBOL (ZONA SEGURA) ---
clc; clear; close all;

% CONFIGURACIÓN INICIAL (Tus límites)
% Todas las medidas en MILÍMETROS (mm)
X_fijo = 180;  % Profundidad fija
Y_centro = 180; % Centro del árbol en Y
Z_base = 80;    % Base del árbol en Z

% DEFINICIÓN DE PUNTOS (WAYPOINTS)
% Formato: [X, Y, Z]
waypoints = [
    % 1. INICIO (Centro Base)
    X_fijo,  180,   80;

    % --- LADO DERECHO ---
    % 2. Tronco Base Der
    X_fijo,  165,   80;
    % 3. Tronco Tope Der
    X_fijo,  165,  110;
    % 4. Rama Baja Punta Der
    X_fijo,  120,  110;
    % 5. Rama Baja Interior
    X_fijo,  155,  150;
    % 6. Rama Media Punta Der
    X_fijo,  130,  150;
    % 7. Rama Media Interior
    X_fijo,  165,  190;
    % 8. Rama Alta Punta Der
    X_fijo,  150,  190;

    % --- CIMA ---
    % 9. ESTRELLA (Punto más alto Z=230 < 250)
    X_fijo,  180,  230;

    % --- LADO IZQUIERDO (Simétrico) ---
    % 10. Rama Alta Punta Izq
    X_fijo,  210,  190;
    % 11. Rama Media Interior
    X_fijo,  195,  190;
    % 12. Rama Media Punta Izq
    X_fijo,  230,  150;
    % 13. Rama Baja Interior
    X_fijo,  205,  150;
    % 14. Rama Baja Punta Izq (Max Y=240 < 250)
    X_fijo,  240,  110;
    % 15. Tronco Tope Izq
    X_fijo,  195,  110;
    % 16. Tronco Base Izq
    X_fijo,  195,   80;

    % --- CIERRE ---
    % 17. Volver al Inicio
    X_fijo,  180,   80;
];

% Separar coordenadas
X = waypoints(:,1);
Y = waypoints(:,2);
Z = waypoints(:,3);

% --- GRAFICAR EN 2D (VISTA FRONTAL YZ) ---
figure('Name', 'Vista Frontal (Plano de Dibujo)', 'Color', 'w');
plot(Y, Z, 'b.-', 'LineWidth', 2, 'MarkerSize', 15);
grid on;
axis equal;
xlabel('Eje Y (mm)');
ylabel('Eje Z (mm)');
title('Vista Frontal del Árbol (Plano YZ)');

% Dibujar límites de seguridad (Caja de 250mm)
hold on;
rectangle('Position',[0,0,250,250], 'EdgeColor','r', 'LineStyle','--', 'LineWidth', 1);
text(10, 245, 'Límite Máximo (250mm)', 'Color', 'r');

% Etiquetar los puntos
for i = 1:length(Y)-1
    text(Y(i), Z(i), [' P', num2str(i)], 'FontSize', 8, 'Color', 'k', 'VerticalAlignment','bottom');
end

% --- GRAFICAR EN 3D (PERSPECTIVA ROBOT) ---
figure('Name', 'Vista 3D Isométrica', 'Color', 'w');
plot3(X, Y, Z, 'r.-', 'LineWidth', 2, 'MarkerSize', 12);
grid on;
axis equal;
xlabel('Eje X (Profundidad)');
ylabel('Eje Y (Ancho)');
zlabel('Eje Z (Altura)');
title('Trayectoria 3D del Robot');

% Configurar vista
view(135, 30);
xlim([0, 250]);
ylim([0, 250]);
zlim([0, 250]);

disp('--- COORDENADAS LISTAS PARA COPIAR A UR ---');
disp(waypoints);