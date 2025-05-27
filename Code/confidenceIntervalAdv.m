function [ci_d, ci_u, ci_mu] = confidenceIntervalAdv(sigma_hat_i, k_hat_i, l, expected_C, f)
    
    % Calcola tutti i parametri in vectoriale
    SIGMA_vec = sigma_hat_i ./ sqrt(2 * k_hat_i);
    theta_vec = 1 ./ k_hat_i;
    c_bar_vec = expected_C ./ SIGMA_vec;
    
    n = length(sigma_hat_i);
    
    % Griglia di valori c più piccola per velocità
    c_vals = linspace(0.001, 0.75, 20); % Ridotto drasticamente!
    n_c = length(c_vals);
    
    % Pre-alloca matrici per tutti i risultati
    D_matrix = zeros(n, n_c); % d_vals per ogni (i, c)
    U_matrix = zeros(n, n_c); % u_vals per ogni (i, c)
    
    % Calcola maximize_mu per tutti i parametri contemporaneamente
    fprintf('Calcolando maximize_mu per %d parametri...', n);
    for i = 1:n
        if mod(i, 1000) == 0
            fprintf(' %d/%d', i, n);
        end
        [D_matrix(i,:), U_matrix(i,:)] = maximize_mu(c_vals, l, SIGMA_vec(i), theta_vec(i), f);
    end
    fprintf(' Done!\n');
    
    % Ora interpola per trovare i valori finali
    u_star = zeros(n, 1);
    d_star = zeros(n, 1);
    mu_star = zeros(n, 1);
    
    fprintf('Interpolando risultati...');
    for i = 1:n
        % Interpolazione lineare veloce
        d_star(i) = interp1(c_vals, D_matrix(i,:), c_bar_vec(i), 'linear', 'extrap');
        u_star(i) = interp1(c_vals, U_matrix(i,:), c_bar_vec(i), 'linear', 'extrap');
        mu_star(i) = evaluate_mu(d_star(i), u_star(i), c_bar_vec(i), theta_vec(i), l, SIGMA_vec(i), f);
    end
    fprintf(' Done!\n');
    
    % Calcola percentili
    ci_d = prctile(d_star, [2.5, 97.5]);
    ci_u = prctile(u_star, [2.5, 97.5]);
    ci_mu = prctile(mu_star, [2.5, 97.5]);
end