function [u_samples, d_samples] = simulation_ci(sigma_vec, k_vec, eta_vec, c_bar, l, theta, f)
% sigma_vec, k_vec, eta_vec: 1×n_sim
% c_bar        : costo normalizzato
% l            : stop-loss
% theta, f     : altri parametri di maximize_mu
n_sim = numel(sigma_vec);
u_samples = nan(n_sim,1);
d_samples = nan(n_sim,1);

flag = 2;  % se stai facendo Question C
for i = 1:n_sim
    sigma_i = sigma_vec(i);
    k_i     = k_vec(i);
    % Ricava bande (sola per c_bar):
    [d_i, u_i] = maximize_mu(c_bar, l, sigma_i, theta, flag, f);
    d_samples(i) = d_i;
    u_samples(i) = u_i;
end
end