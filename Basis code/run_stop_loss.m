function [ann_return_vector] = run_stop_loss(X_OS, d_star, u_star, c_bar, SIGMA, theta)

    l_vector = [-1.282, -1.645, -1.96, -2.326];
    f = 1;
    ann_return_vector = zeros(length(l_vector), 1);
    for i=1:length(l_vector)
        [u_star, d_star, ~] = bands(c_bar, l_vector(i), SIGMA, theta, f);
        ann_return_vector(i) = billionaire(X_OS, d_star, u_star, l_vector(i), c_bar, SIGMA, f, 6);
    end
    figure;
    plot(l_vector, ann_return_vector)
    grid on;
    figure;
    plot(X_OS, 'black'); hold on;
    yline(-1.282, "red", 'LineWidth', 1.5)
    yline( -1.645, "red", 'LineWidth', 1.5)
    yline(-1.96, "red", 'LineWidth', 1.5)
    yline(-2.326, "red", 'LineWidth', 1.5)
    
    xlabel('time');
    ylabel('log-price process');
    legend('OU process', 'd*','u*','stop losses');
    title('title');
    
end