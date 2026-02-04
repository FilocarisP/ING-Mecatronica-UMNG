% ==============================
% 📡 Lectura en tiempo real desde ESP32 vía Bluetooth
% ==============================

% Ajusta el puerto COM según aparezca en tu PC
puerto = "COM6";    
baud = 115200;      

% Crear conexión serial
bt = serialport(puerto, baud);

% Configurar terminador de línea
configureTerminator(bt, "LF");

% Número de muestras a mostrar en pantalla (ventana deslizante)
N = 500;
data = nan(N,3);   % [Error, Entrada, Salida]

% Preparar la figura para graficar en vivo
figure;
h1 = plot(nan, nan, 'r', 'DisplayName', 'Error'); hold on;
h2 = plot(nan, nan, 'g', 'DisplayName', 'Entrada');
h3 = plot(nan, nan, 'b', 'DisplayName', 'Salida');
legend;
xlabel('Muestras');
ylabel('Valor');
title('Seguimiento en tiempo real - ESP32');
grid on;

% Contador de muestras
idx = 0;

while true
    try
        % Leer una línea del ESP32
        line = readline(bt);                   
        values = str2double(split(line, ","));  % Separar CSV -> números
        
        % Validar que sean 3 valores (error, entrada, salida)
        if numel(values) == 3
            idx = idx + 1;
            
            % Desplazar datos tipo "ventana deslizante"
            data = [data(2:end,:); values'];
            
            % Actualizar datos de las curvas
            set(h1, 'XData', 1:idx, 'YData', data(:,1));
            set(h2, 'XData', 1:idx, 'YData', data(:,2));
            set(h3, 'XData', 1:idx, 'YData', data(:,3));
            
            % Ajustar ejes
            xlim([max(0, idx-N) idx]);
            ylim([-200 200]);   % 🔹 Ajusta este rango según tus valores
            
            drawnow; % refrescar gráfica
        end
    catch ME
        warning("Error de lectura: %s", ME.message);
    end
end