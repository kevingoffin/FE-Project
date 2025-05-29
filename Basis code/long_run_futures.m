function [X_OS, value, ann_return] = long_run_futures(Rt_OS_Filtered, eta_hat, theta, SIGMA, u_star, d_star, l, c_bar, f)

    X_OS = (table2array(Rt_OS_Filtered(:,2)) - eta_hat) / SIGMA;

    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    p_pls = erfid(d_star, l)/erfid(u_star,l);
    p_mns = erfid(u_star, d_star)/erfid(u_star,l);
    c_max = p_pls*(u_star - l) - (d_star - l);

    value = evaluate_mu(d_star, u_star, c_bar, theta, l, SIGMA, f);
    [ann_return] = billionaire(X_OS, d_star, u_star, l, c_bar, SIGMA, f, 6);

    figure;
    plot(X_OS, 'black'); hold on;
    yline(d_star, "green", 'LineWidth', 1.5); hold on;
    yline(u_star, "blue", 'LineWidth', 1.5);
    yline(l, "red", 'LineWidth', 1.5)
    xlabel('time');
    ylabel('log-price process');
    legend('OU process', 'd*','u*','stop loss');
    title('title');
    
    fprintf('Expected theorical result over 1 year %.6f \n', value)
    fprintf('actual transaction cost normalized %.6f\n', c_bar)
    fprintf('Actual result over 12 month %.6f\n', ann_return)
    fprintf('maximum transaction cost normalized %.6f\n', c_max)
    
 
end