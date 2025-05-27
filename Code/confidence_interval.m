function [ci_d, ci_u, ci_mu] = confidence_interval(sigma_hat_i, k_hat_i, l, expected_C, f)
    

    u_star = zeros(length(sigma_hat_i), 1);
    d_star = zeros(length(sigma_hat_i), 1);
    mu_star = zeros(length(sigma_hat_i), 1);
    for j=1:length(sigma_hat_i)
        SIGMA = sigma_hat_i(j)/sqrt(2*k_hat_i(j));
        theta = 1/k_hat_i(j);
        c_bar = expected_C/SIGMA;
        [u_star(j), d_star(j), mu_star(j)] = bands(c_bar, l, SIGMA, theta, f);
    end
    ci_d = prctile(d_star,     [2.5, 97.5]);
    ci_u = prctile(u_star,     [2.5, 97.5]);
    ci_mu = prctile(mu_star,     [2.5, 97.5]);
end