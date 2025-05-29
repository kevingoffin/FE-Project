function [Rt_IS_filtered, Rt_OS, time_IS_filtered, ts_OS] = cleaner(Rt, timestamp, n)
    
    % Filtra splittando il dataset e togliendo tutti gli outlier
    
    % Converti timestamp in datetime
    timestamp = datetime(timestamp, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
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
    
    
    % 1) trova gli indici
    idx_extreme_IS = find(outliers_IS);    % posizioni in Rt_IS
    
    % 2) ottieni i timestamp corrispondenti
    ts_IS = timestamp(IS_idx);  % datetime full IS
    ts_OS = timestamp(OS_idx);
    
    times_extreme_IS  = ts_IS(idx_extreme_IS);
    
    % 3) valori Rt corrispondenti
    values_extreme_IS = Rt_IS(idx_extreme_IS);

    % Stampa risultati
    fprintf('Outlier IS: %d trovati\n', sum(outliers_IS));
    % Calcola l'IQR per ogni serie
    IQR_IS = iqr(Rt_IS);
    
    % Applica la funzione a IS e OS
    [Rt_IS_filtered, time_IS_filtered, idx_removed_IS] = removeAntipersistentOutliers(Rt_IS, timestamp(IS_idx), IQR_IS);
    
    % Mostra i risultati
    fprintf('Outlier antipersistenti rimossi in IS: %d\n', length(idx_removed_IS));

    
    % 1) timestamp originali per IS/OS (prima del clean)
    orig_ts_IS = ts_IS;       
      
    
    % 2) indici di quelli rimossi
    idx_ap_IS = idx_removed_IS;   
 
    
    % 3) estrai timestamp e valori corrispondenti
    times_ap_IS  = orig_ts_IS(idx_ap_IS);
    
    values_ap_IS = Rt_IS(idx_ap_IS);

    
    % 4) (opzionale) visualizza
    fprintf('\n--- Antipersistent outliers IS (%d punti) ---\n', numel(idx_ap_IS));
    for k = 1:numel(idx_ap_IS)
        fprintf('%s  →  Rt = %.6f\n', char(times_ap_IS(k)), values_ap_IS(k));
    end
end