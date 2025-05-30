function [opt_lev, rtn, mu_vector] = run_leverage(X_OS, SIGMA, theta, c_bar, l, f_max, sigma_hat_i, k_hat_i, expected_C, d_star, u_star, value)

    [opt_lev] = optimalLeverage(SIGMA, theta, c_bar, l, f_max);
    
    f = [1, 5, 10, opt_lev, 28, 35, 50, 65, 75, 90, 120, 150, 200, 250, 300, 400, 600];
    mu_vector = zeros(length(f),1);
    rtn = zeros(length(f),1);
    for j=1:length(f)
        [u_star_lev, d_star_lev] = bands(c_bar, l, SIGMA, theta, f(j));
        mu_vector(j) = evaluate_mu(d_star_lev, u_star_lev, c_bar, theta, l, SIGMA, f(j))*100;
        rtn(j) = billionaire(X_OS, d_star_lev, u_star_lev, l, c_bar, SIGMA, f(j), 6);
        %fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
    end
    
    figure;
    plot(f, rtn*100); 
    xline(1);
    xline(2);
    xline(5);
    xline(opt_lev, "red", 'LineWidth', 1.5);
    xlabel('leverage levels');
    ylabel('OS return');
    title('Empirical returns leveraged');
    grid on;
    
    
    figure;
    plot(f, mu_vector); hold on;
    xline(1);
    xline(2);
    xline(5);
    xline(opt_lev, "red", 'LineWidth', 1.5);
    xlabel('leverage levels');
    ylabel('leveraged returns');
    title('Theoretical returns leveraged');
    grid on;
%%
    [ci_d, ci_u, ci_mu] = confidence_interval(sigma_hat_i, k_hat_i, l, expected_C, 1);

    fprintf('d, u, mu: [%.15f, %.15f, %.15f]\n', d_star, u_star, value);
    fprintf('===Confidence intervals for d,u,mu===\n')
    fprintf('95%% CI per d :     [%.15f, %.15f]\n', ci_d(1),     ci_d(2));
    fprintf('95%% CI per u: [%.15f, %.15f]\n', ci_u(1), ci_u(2));
    fprintf('95%% CI per mu:   [%.15f, %.15f]\n', ci_mu(1),   ci_mu(2));

end