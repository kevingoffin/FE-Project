function [Rt_clean, time_clean, removed_idx] = removeAntipersistentOutliers(Rt, time, IQR)
    removed_idx = [];
    for t = 2:length(Rt)-1
        delta_prev = Rt(t) - Rt(t-1);
        delta_next = Rt(t+1) - Rt(t);
        
        % Condizione 1: salto iniziale > IQR
        % Condizione 2: movimento successivo recupera almeno 95% del salto
        % Condizione 3: movimento successivo è nella direzione opposta (corregge)
        if abs(delta_prev) > IQR && ...               % Salto grande
           abs(delta_next) >= 0.95*abs(delta_prev) && ... % Recupero almeno 95%
           sign(delta_next) == -sign(delta_prev)      % Direzione opposta
           
            removed_idx(end+1) = t;
        end
    end
    Rt_clean = Rt;
    time_clean = time;
    Rt_clean(removed_idx) = [];
    time_clean(removed_idx) = [];
end