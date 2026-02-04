% ================= MATLAB - RECEPCIÓN BINARIA CONTINUA ==================
close all; clear on; clc; clear s;

puerto = "COM6" + ...
    "";   % Puerto del Bluetooth
baud   = 115200;

% Crear objeto serial
s = serialport(puerto, baud);
flush(s);

% Buffers dinámicos (crecen con el tiempo)
error_sig   = [];
referencia  = [];
salida_sig  = [];
control_sig = [];

% ====== Figura con 4 gráficas ======
fig = figure('Name','Seguidor de línea - Datos en tiempo real (binario)', ...
             'Units','normalized', 'Position',[0.05 0.05 0.9 0.85]); % ajustable

tiledlayout(fig,4,1,'Padding','compact','TileSpacing','compact');

nexttile; h1 = plot(nan, nan, 'r'); grid on;
title('Error'); ylabel('error');

nexttile; h2 = plot(nan, nan, 'b'); grid on;
title('Referencia'); ylabel('ref');

nexttile; h3 = plot(nan, nan, 'g'); grid on;
title('Salida (θ)'); ylabel('θ');

nexttile; h4 = plot(nan, nan, 'k'); grid on;
title('Control (u_k)'); ylabel('u_k'); xlabel('Muestras');

% Configurar para que los ejes se ajusten dinámicamente
ax = [ancestor(h1,'axes'), ancestor(h2,'axes'), ancestor(h3,'axes'), ancestor(h4,'axes')];
for a = ax
    a.XLimMode = 'auto';
    a.YLimMode = 'auto';
end

% ====== Lectura en tiempo real (ilimitada) ======
i = 1;
while ishandle(h1)
    if s.NumBytesAvailable >= 16   % 4 floats * 4 bytes = 16
        bytes = read(s, 16, "uint8");                  
        valores = typecast(uint8(bytes), 'single');    

        error_sig(i)   = valores(1);
        referencia(i)  = valores(2);
        salida_sig(i)  = valores(3);
        control_sig(i) = valores(4);

        % Actualizar gráficas
        set(h1, 'XData', 1:i, 'YData', error_sig);
        set(h2, 'XData', 1:i, 'YData', referencia);
        set(h3, 'XData', 1:i, 'YData', salida_sig);
        set(h4, 'XData', 1:i, 'YData', control_sig);

        % Reajuste automático de límites
        for a = ax
            a.XLim = [max(0,i-500) i];  % ventana de 500 muestras visibles
            a.YLimMode = 'auto';
        end

        drawnow limitrate;
        i = i + 1;
    end
end

clear s;
disp("🔴 Lectura finalizada. Puerto cerrado.");