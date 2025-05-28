function [sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt, n_sim, deltaT, eta_hat, k_hat, sigma_hat)
    % Parametri
    T      = length(Rt);       % numero di time-step (uguale a length(Rt_0))               % numero di repliche Monte Carlo
    alpha  = exp(-k_hat*deltaT); % e^{-k Δt}
    beta   = 1 - alpha;          % 1 - e^{-k Δt}
    sd_noise = sigma_hat * sqrt((1 - alpha^2)/(2*k_hat));  % deviazione del rumore
    
    % Preallocazione (righe = tempo, colonne = simulazioni)
    X = zeros(T, n_sim);
    X(1,:) = Rt(1);  % tutti i path partono dallo stesso valore iniziale
    
    % % Simulation
    for j = 1:n_sim
        for t = 2:T
            X(t,j) = X(t-1,j)*alpha + eta_hat*beta + sd_noise*randn;
        end
    end

    for j = 1:n_sim
        X(2:T,j) = X(1:T-1,j) * alpha + eta_hat * beta + sd_noise * randn(T-1, 1);
    end
    
    eta_hat_i   = zeros(1, n_sim);
    zeta_hat_i  = zeros(1, n_sim);
    k_hat_i     = zeros(1, n_sim);


    for j = 1:n_sim
        x_prev = X(1:end-1,j);
        x_next = X(2:end,  j);
        % ricalcoli Y_min, Y_pls, ecc. esattamente come fai sul dato reale
        Y_min      = mean(x_prev);
        Y_pls      = mean(x_next);
        Y_min_min  = mean(x_prev.^2);
        Y_pls_pls  = mean(x_next.^2);
        Y_pls_min  = mean(x_prev .* x_next);
    
        num = Y_pls_min - Y_min*Y_pls;
        den = Y_min_min - Y_min^2;
    
        k_hat_i(j)     = -(1/deltaT) * log(num/den);
        eta_hat_i(j)   = Y_pls + ((x_next(end)-x_prev(1))/ (T-1)) * (num/(den - num));
        zeta_hat_i(j)  = Y_pls_pls - Y_pls^2 - num^2/den;
    end
    
    
    sigma_hat_i = sqrt(real( (2*zeta_hat_i .* k_hat_i) ./ (1 - exp(-2*k_hat_i*deltaT))));
    k_hat_i     = real(k_hat_i);
    eta_hat_i   = real(eta_hat_i);
end