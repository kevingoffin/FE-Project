function [Rt_IS_filtered, Rt_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner_bis(Rt, timestamp, n)
    
    % Filtra splittando il dataset e togliendo tutti gli outlier
    
    % Converti timestamp in datetime
    timestamp = datetime(timestamp, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    % Ordina per data (opzionale se già ordinato)
    [~, idx] = sort(timestamp);
    timestamp = timestamp(idx);
    Rt = Rt(idx);
    
    % Estrai intervallo temporale
    start_date = timestamp(1);
    end_date = timestamp(end);
    total_months = calmonths(between(start_date, end_date, 'months'));
    split_date = start_date + calmonths(n);
    
    % Split: IS = primi 9 mesi, OS = ultimi 3 mesi
    IS_idx = timestamp < split_date;
    OS_idx = timestamp >= split_date;
    
    Rt_IS = Rt(IS_idx);
    Rt_OS = Rt(OS_idx);
    
    
    % Identifica outlier
    outliers_IS = outliersDetector(Rt_IS);
    outliers_OS = outliersDetector(Rt_OS);
    
    
    % 1) trova gli indici
    idx_extreme_IS = find(outliers_IS);    % posizioni in Rt_IS
    idx_extreme_OS = find(outliers_OS);
    
    % 2) ottieni i timestamp corrispondenti
    ts_IS = timestamp(IS_idx);  % datetime full IS
    ts_OS = timestamp(OS_idx);
    
    times_extreme_IS  = ts_IS(idx_extreme_IS);
    times_extreme_OS  = ts_OS(idx_extreme_OS);
    
    % 3) valori Rt corrispondenti
    values_extreme_IS = Rt_IS(idx_extreme_IS);
    values_extreme_OS = Rt_OS(idx_extreme_OS);
    
    % 4) (opzionale) visualizza
    fprintf('\n--- Extreme outliers IS (%d punti) ---\n', numel(idx_extreme_IS));
    for k = 1:numel(idx_extreme_IS)
        fprintf('%s  →  Rt = %.6f\n', char(times_extreme_IS(k)), values_extreme_IS(k));
    end
    
    fprintf('\n--- Extreme outliers OS (%d punti) ---\n', numel(idx_extreme_OS));
    for k = 1:numel(idx_extreme_OS)
        fprintf('%s  →  Rt = %.6f\n', char(times_extreme_OS(k)), values_extreme_OS(k));
    end
    
    % Stampa risultati
    fprintf('Outlier IS: %d trovati\n', sum(outliers_IS));
    fprintf('Outlier OS: %d trovati\n', sum(outliers_OS));
    % Calcola l'IQR per ogni serie
    IQR_IS = iqr(Rt_IS);
    IQR_OS = iqr(Rt_OS);
    
    % Applica la funzione a IS e OS
    [Rt_IS_filtered, time_IS_filtered, idx_removed_IS] = removeAntipersistentOutliers(Rt_IS, timestamp(IS_idx), IQR_IS);
    [Rt_OS_filtered, time_OS_filtered, idx_removed_OS] = removeAntipersistentOutliers(Rt_OS, timestamp(OS_idx), IQR_OS);
    
    % Mostra i risultati
    fprintf('Outlier antipersistenti rimossi in IS: %d\n', length(idx_removed_IS));
    fprintf('Outlier antipersistenti rimossi in OS: %d\n', length(idx_removed_OS));
    
    % 1) timestamp originali per IS/OS (prima del clean)
    orig_ts_IS = ts_IS;       
    orig_ts_OS = ts_OS;       
    
    % 2) indici di quelli rimossi
    idx_ap_IS = idx_removed_IS;   
    idx_ap_OS = idx_removed_OS;   
    
    % 3) estrai timestamp e valori corrispondenti
    times_ap_IS  = orig_ts_IS(idx_ap_IS);
    times_ap_OS  = orig_ts_OS(idx_ap_OS);
    
    values_ap_IS = Rt_IS(idx_ap_IS);
    values_ap_OS = Rt_OS(idx_ap_OS);
    
    % 4) (opzionale) visualizza
    fprintf('\n--- Antipersistent outliers IS (%d punti) ---\n', numel(idx_ap_IS));
    for k = 1:numel(idx_ap_IS)
        fprintf('%s  →  Rt = %.6f\n', char(times_ap_IS(k)), values_ap_IS(k));
    end
    
    fprintf('\n--- Antipersistent outliers OS (%d punti) ---\n', numel(idx_ap_OS));
    for k = 1:numel(idx_ap_OS)
        fprintf('%s  →  Rt = %.6f\n', char(times_ap_OS(k)), values_ap_OS(k));
    end

end