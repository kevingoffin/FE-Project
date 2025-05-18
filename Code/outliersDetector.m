function [outliers] = outliersDetector(dataset)
    % Calcola i quartili e l'IQR
    Q1 = quantile(dataset, 0.25);  % Primo quartile (25° percentile)
    Q3 = quantile(dataset, 0.75);  % Terzo quartile (75° percentile)
    IQR = Q3 - Q1;                 % Intervallo interquartile
    
    % Definisci i bound per gli outlier
    lower_bound = Q1 - 3 * IQR;    % Limite inferiore per gli outlier
    upper_bound = Q3 + 3 * IQR;    % Limite superiore per gli outlier
    
    % Identifica gli outlier
    outliers = (dataset < lower_bound) | (dataset > upper_bound);
end